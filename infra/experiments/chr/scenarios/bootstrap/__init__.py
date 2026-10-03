"""Reset two disposable routers using the checked-in production bootstrap scripts."""

import os
import shutil
import subprocess
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from types import SimpleNamespace

from lab import SOURCE, Lab, run

REPO = SOURCE.parents[1]


def verify_adoption_plan(plan, recovery=False):
    unexpected = run(
        "jq",
        "-r",
        "--argjson", "recovery", "true" if recovery else "false",
        '.resource_changes[] | select(.change.actions != ["no-op"]) | '
        'select((((.type == "local_file" or .type == "routeros_file") and '
        '.name == "script" and .change.actions == ["create"]) or '
        '(.type == "routeros_move_items" and (.name == "ipv4_filter" or .name == "ipv6_filter") and '
        '(.change.actions == ["create"] or ($recovery and .change.actions == ["update"])))) | not) | .address',
        input=plan,
        capture_output=True,
    ).stdout.strip()
    if unexpected:
        raise RuntimeError(
            f"Bootstrap differs from Terraform before apply:\n{unexpected}"
        )



class BootstrapLab(Lab):
    def __init__(self, parent, root, name, transit_socket, listen):
        self.name = name
        self.transit_socket = transit_socket
        self.listen = listen
        self.address = "10.1.1.1" if name == "stationary" else "10.10.10.1"
        self.prefix = self.address.rsplit(".", 1)[0]
        self.https_port = 0
        super().__init__(
            SimpleNamespace(version=parent.version, state=root / name, ssh_port=0)
        )
        images = self.root / "images"
        (parent.root / "images").mkdir(exist_ok=True)
        if not images.exists():
            images.symlink_to(parent.root / "images", target_is_directory=True)

    def network_args(self, capture):
        args = []
        # The first NIC provides access to the factory image's ether1 DHCP client.
        # The reset wrapper maps it to the RB5009 LAN port ether2.
        for index in range(1, 10):
            ident = "lab" if index == 1 else f"port{index}"
            if index == 1:
                backend = (
                    f"user,id={ident},net={self.prefix}.0/24,host={self.prefix}.254,"
                    f"dhcpstart={self.prefix}.200,"
                    f"hostfwd=tcp:127.0.0.1:{self.ssh_port}-{self.prefix}.200:22,"
                    f"hostfwd=tcp:127.0.0.1:{self.https_port}-{self.address}:443"
                )
            elif index == 2:
                mode = "on" if self.listen else "off"
                backend = f"stream,id={ident},server={mode},addr.type=unix,addr.path={self.transit_socket}"
            elif index == 8:
                backend = f"user,id={ident},net=192.0.2.0/24"
            else:
                backend = f"hubport,id={ident},hubid={index}"
            args += [
                "-netdev",
                backend,
                "-device",
                f"virtio-net-pci,netdev={ident},mac=52:54:00:00:{1 if self.listen else 2:02x}:{index:02x}",
            ]
        args += ["-object", f"filter-dump,id=capture,netdev=lab,file={capture}"]
        return args

    def forwarded_port(self, protocol, guest_port):
        matches = []
        for line in self.monitor("info usernet").splitlines():
            fields = line.split()
            if (
                len(fields) == 8
                and fields[0] == f"{protocol.upper()}[HOST_FORWARD]"
                and fields[2] == "127.0.0.1"
                and fields[5] == str(guest_port)
            ):
                matches.append(int(fields[3]))
        if len(matches) != 1:
            raise RuntimeError(f"Expected one {protocol} forward to guest port {guest_port}: {matches}")
        return matches[0]

    def network_ready(self):
        self.ssh_port = self.forwarded_port("tcp", 22)
        self.https_port = self.forwarded_port("tcp", 443)

    def upload(self, path, name):
        args = self.ssh_args()
        args[0] = "scp"
        args[args.index("-p")] = "-P"
        destination = args.pop()
        run(
            *args,
            "-O",
            str(path),
            f"{destination}:{name}",
            capture_output=True,
            timeout=30,
        )
        # SCP can acknowledge before RouterOS exposes the file to scripting.
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            try:
                size = self.ssh(f':put [/file get [find name="{name}"] size]').strip()
            except RuntimeError:
                size = ""
            if size == str(path.stat().st_size):
                return
            time.sleep(0.5)
        raise RuntimeError(f"{self.name}: upload not visible: {name}")

    def reset_bootstrap(self):
        script = REPO / "local-networking/bootstrap/generated" / f"{self.name}.rsc"
        shutil.copyfile(script, self.directory / "bootstrap.rsc")
        script = self.directory / "bootstrap.rsc"
        self.upload(script, "bootstrap.rsc")
        wrapper = self.directory / "reset.rsc"
        wrapper.write_text(
            ":delay 5s\n"
            "/interface ethernet set [find default-name=ether1] name=temporary-lan\n"
            "/interface ethernet set [find default-name=ether2] name=ether1\n"
            "/interface ethernet set [find default-name=ether1] name=ether2\n"
            "/interface ethernet set [find default-name=ether9] name=sfp-sfpplus1\n"
            "/ip dhcp-client remove [find]\n"
            "/import file-name=bootstrap.rsc\n"
        )
        # Create the reset hook through RouterOS itself. A newly SCP-uploaded
        # file can be readable while still absent from run-after-reset's index.
        contents = (
            wrapper.read_text()
            .replace("\\", "\\\\")
            .replace('"', '\\"')
            .replace("\n", "\\n")
        )
        self.ssh(
            "/file remove [find name=reset.rsc]; /file remove [find name=boostrap.txt]"
        )
        self.ssh(f'/file add name=reset.rsc type=file contents="{contents}"')
        print(f"{self.name}: resetting into production bootstrap", flush=True)
        try:
            self.ssh(
                "/system reset-configuration no-defaults=yes keep-users=yes skip-backup=yes run-after-reset=reset.rsc"
            )
        except subprocess.CalledProcessError as error:
            # Reset may close SSH before it returns an exit status. Completion
            # is determined by the saved marker and post-reboot checks below.
            output = error.stdout + error.stderr
            (self.directory / "reset-request.log").write_text(output)
            if "input does not match" in output:
                raise RuntimeError(
                    f"{self.name}: RouterOS rejected reset.rsc"
                ) from error
        self.monitor(f"hostfwd_remove lab tcp:127.0.0.1:{self.ssh_port}")
        self.monitor(f"hostfwd_add lab tcp:127.0.0.1:0-{self.address}:22")
        self.ssh_port = self.forwarded_port("tcp", 22)
        (self.directory / "ports").write_text(f"{self.ssh_port}\n")
        time.sleep(10)
        (self.directory / "known_hosts").unlink(missing_ok=True)
        deadline = time.monotonic() + 240
        while time.monotonic() < deadline:
            serial_log = self.directory / "serial.log"
            if (
                serial_log.exists()
                and "error while running run-after-reset script"
                in serial_log.read_text(errors="replace")
            ):
                raise RuntimeError(
                    f"{self.name}: reset script failed; see {serial_log}"
                )
            try:
                output = self.ssh(
                    ':put [/file get [find name="boostrap.txt"] contents]'
                )
                if "bootstrap_script_finished" in output:
                    # The script sets this RAM-only global; its absence
                    # confirms the bootstrap's final reboot has happened.
                    if (
                        self.ssh(
                            ':put [:len [/system script environment find where name="isLocalBridgeCreated"]]'
                        ).strip()
                        != "0"
                    ):
                        time.sleep(1)
                        continue
                    (self.directory / "bootstrap.log").write_text(output)
                    print(
                        f"{self.name}: bootstrap completed, management reachable",
                        flush=True,
                    )
                    return
            except (subprocess.SubprocessError, RuntimeError):
                pass
            time.sleep(3)
        raise RuntimeError(f"{self.name}: bootstrap failed; inspect {self.directory}")

    def firewall_export(self):
        return tuple(
            line.strip() for line in self.ssh("/export terse").splitlines()
            if line.startswith(("/ip firewall ", "/ipv6 firewall "))
        )

    def check(self, command, expected, label):
        output = self.ssh(command).strip()
        with (self.directory / "checks.txt").open("a") as evidence:
            evidence.write(f"{label}\n{command}\n{output}\n\n")
        if output != expected:
            raise RuntimeError(
                f"{self.name}: {label}: expected {expected!r}, got {output!r}"
            )
        print(f"{self.name}: PASS {label}", flush=True)

    def verify(self):
        peer = "10.10.10.1" if self.listen else "10.1.1.1"
        self.check(":put [/ipv6 settings get disable-ipv6]", "true", "IPv6 disabled")
        self.check(
            ":put [:len [/ipv6 nd find where disabled=no]]",
            "0",
            "no router advertisements",
        )
        self.check(
            ":put [:len [/ip dns static find where type=AAAA and disabled=no]]",
            "0",
            "no enabled router AAAA records",
        )
        for name, address in [("stationary", "10.1.1.1"), ("kuberack", "10.10.10.1")]:
            self.check(
                f':put [:resolve "{name}.networking.kalski.xyz" type=ipv4]',
                address,
                f"DNS A record for {name}",
            )
        self.monitor(f"hostfwd_add lab udp:127.0.0.1:0-{self.address}:53")
        dns_port = self.forwarded_port("udp", 53)
        try:
            for name, address in [
                ("stationary", "10.1.1.1"),
                ("kuberack", "10.10.10.1"),
            ]:
                result = run(
                    "dig",
                    "@127.0.0.1",
                    "-p",
                    str(dns_port),
                    f"{name}.networking.kalski.xyz",
                    "A",
                    "+short",
                    "+time=2",
                    "+tries=1",
                    capture_output=True,
                )
                if result.stdout.strip() != address:
                    raise RuntimeError(
                        f"{self.name}: external DNS query for {name} failed: {result.stdout}"
                    )
            print(f"{self.name}: PASS DNS queries from outside the router", flush=True)
        finally:
            self.monitor(f"hostfwd_remove lab udp:127.0.0.1:{dns_port}")
        self.check(
            f':local received 0; :foreach reply in=[/ping address={peer} src-address={self.address} count=3 interval=200ms as-value] do={{:if ([:typeof ($reply->"time")] != "nil") do={{:set received ($received + 1)}}}}; :put $received',
            "3",
            "bidirectional routed IPv4 management",
        )
        self.check(
            ":put [/ip service get www-ssl disabled]",
            "false",
            "HTTPS management enabled",
        )
        self.check(
            ":put [/certificate get [find name=self] private-key]",
            "true",
            "HTTPS certificate has private key",
        )
        (self.directory / "export.rsc").write_text(self.ssh("/export terse"))


class Adoption:
    def __init__(self, root, routers):
        self.directory = root / "terraform"
        self.directory.mkdir()
        self.binary = shutil.which("tofu") or "terraform"
        self.env = dict(os.environ, TF_IN_AUTOMATION="1")
        for router in routers:
            self.env[f"TF_VAR_{router.name}_hosturl"] = (
                f"https://127.0.0.1:{router.https_port}"
            )
            self.env[f"TF_VAR_{router.name}_password"] = (
                router.directory / "password"
            ).read_text()
        shutil.copyfile(
            Path(__file__).parent / "terraform/main.tf", self.directory / "main.tf"
        )
        source = REPO / "local-networking"
        for name in (
            "bootstrap.tf",
            "bootstrap-config.tf",
            "network-topology.tf",
            "modules",
        ):
            (self.directory / name).symlink_to(
                source / name, target_is_directory=name == "modules"
            )
        shutil.copyfile(
            source / ".terraform.lock.hcl", self.directory / ".terraform.lock.hcl"
        )
        self.call("init", "init", "-backend=false")

    def call(self, label, *args):
        command = [self.binary, *args]
        command.insert(3 if args[0] == "state" else 2, "-no-color")
        result = subprocess.run(
            command,
            cwd=self.directory,
            env=self.env,
            text=True,
            capture_output=True,
            check=False,
        )
        (self.directory / f"{label}.log").write_text(result.stdout + result.stderr)
        if result.returncode:
            raise RuntimeError(
                f"Terraform {label} failed; see {self.directory / (label + '.log')}"
            )
        return result.stdout

    def adopt(self, recovery=False):
        command = [
            "python3",
            str(REPO / "local-networking/scripts/adopt-bootstrap.py"),
            "--terraform",
            self.binary,
            "--directory",
            str(self.directory),
            "--router",
            "stationary",
            "--router",
            "kuberack",
        ]
        for label, flags in [
            ("preview", []),
            ("adopt", ["--apply"]),
            ("repeat", ["--apply"]),
        ]:
            result = subprocess.run(
                command + flags,
                env=self.env,
                capture_output=True,
                text=True,
                check=False,
            )
            (self.directory / f"{label}.log").write_text(result.stdout + result.stderr)
            if result.returncode:
                raise RuntimeError(
                    f"Importer {label} failed; see {self.directory / (label + '.log')}"
                )
            if recovery and label == "adopt" and "rebind " not in result.stdout:
                raise RuntimeError("Reset did not exercise stale binding repair")
            if label == "repeat" and "No state changes needed." not in result.stdout:
                raise RuntimeError("Repeat adoption was not a no-op")
        self.call("plan", "plan", "-out=adopt.tfplan")
        plan = self.call("show", "show", "-json", "adopt.tfplan")
        verify_adoption_plan(plan, recovery=recovery)
        self.call("apply", "apply", "adopt.tfplan")
        self.call("settled", "plan", "-detailed-exitcode")
        for site in ("stationary", "kuberack"):
            generated = self.directory / "bootstrap/generated" / f"{site}.rsc"
            production = REPO / "local-networking/bootstrap/generated" / f"{site}.rsc"
            if generated.read_bytes() != production.read_bytes():
                raise RuntimeError(
                    f"{site}: generated script differs from the checked-in production script"
                )
        print(
            "PASS adoption, repeat no-op and empty full bootstrap-module plan",
            flush=True,
        )

    def repair_firewall_order(self, routers):
        before = [router.firewall_export() for router in routers]
        for router in routers:
            for family in ("ip", "ipv6"):
                router.ssh(
                    f'/{family} firewall filter move [find chain=forward action=fasttrack-connection] destination=[find chain=forward comment="bootstrap: drop invalid"]'
                )
        self.call("order-plan", "plan", "-out=order.tfplan")
        plan = self.call("order-show", "show", "-json", "order.tfplan")
        run(
            "jq", "-e",
            '[.resource_changes[] | select(.change.actions != ["no-op"])] | length == 4 and all(.[]; .type == "routeros_move_items" and .change.actions == ["update"])',
            input=plan, capture_output=True,
        )
        self.call("order-apply", "apply", "order.tfplan")
        self.call("order-settled", "plan", "-detailed-exitcode")
        if before != [router.firewall_export() for router in routers]:
            raise RuntimeError("Firewall ordering repair did not restore the original rules")
        print("PASS firewall order drift detection and repair", flush=True)

def experiment(parent):
    required = (
        "qemu-system-x86_64",
        "qemu-img",
        "ssh",
        "scp",
        "ssh-keygen",
        "curl",
        "dig",
        "jq",
    )
    missing = [command for command in required if not shutil.which(command)]
    if missing or not (shutil.which("tofu") or shutil.which("terraform")):
        raise RuntimeError(
            "Use nix develop .#chr-bootstrap to provide the test dependencies"
        )
    if not os.access("/dev/kvm", os.R_OK | os.W_OK):
        raise RuntimeError("Bootstrap E2E requires read/write access to /dev/kvm")
    root = parent.root / "bootstrap" / str(time.time_ns())
    root.mkdir(parents=True)
    print(f"Bootstrap E2E evidence: {root}", flush=True)
    transit = root / "transit.sock"
    routers = [
        BootstrapLab(parent, root, name, transit, index == 0)
        for index, name in enumerate(("stationary", "kuberack"))
    ]
    try:
        for router in routers:
            router.start()
        with ThreadPoolExecutor(max_workers=2) as executor:
            list(executor.map(lambda router: router.reset_bootstrap(), routers))
        for router in routers:
            router.verify()
        adoption = Adoption(root, routers)
        firewall_before = [router.firewall_export() for router in routers]
        adoption.adopt()
        if firewall_before != [router.firewall_export() for router in routers]:
            raise RuntimeError("Initial Terraform adoption changed firewall rules or ordering")
        adoption.repair_firewall_order(routers)
        with ThreadPoolExecutor(max_workers=2) as executor:
            list(executor.map(lambda router: router.reset_bootstrap(), routers))
        for router in routers:
            router.ssh(
                ":foreach id in=[/ip dns static find] do={:local n [/ip dns static get $id name]; :local t [/ip dns static get $id type]; :local a [/ip dns static get $id address]; :local d [/ip dns static get $id disabled]; :local c [/ip dns static get $id comment]; /ip dns static remove $id; /ip dns static add name=$n type=$t address=$a disabled=$d comment=$c}"
            )
            for family, next_comment in (
                ("ip", "bootstrap: drop all from WAN not DSTNATed"),
                ("ipv6", "bootstrap: drop packets with bad src ipv6"),
            ):
                router.ssh(
                    f'/{family} firewall filter remove [find chain=forward comment="bootstrap: drop invalid"]; '
                    f'/{family} firewall filter add chain=forward action=drop connection-state=invalid comment="bootstrap: drop invalid" place-before=[find chain=forward comment="{next_comment}"]'
                )
        firewall_before = [router.firewall_export() for router in routers]
        adoption.adopt(recovery=True)
        if firewall_before != [router.firewall_export() for router in routers]:
            raise RuntimeError("Reset recovery changed firewall rules or ordering")
        for router in routers:
            router.verify()
        print(
            "PASS: bootstrap adoption and recovery with retained state after reset",
            flush=True,
        )
    finally:
        errors = []
        for router in reversed(routers):
            try:
                router.stop()
            except (OSError, RuntimeError, subprocess.SubprocessError) as error:
                errors.append(str(error))
        if errors:
            raise RuntimeError("Could not stop all lab routers: " + "; ".join(errors))
