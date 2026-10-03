import json
from itertools import groupby
import os
import socket
import time
import subprocess
import unittest
import zipfile
from pathlib import Path
from tempfile import TemporaryDirectory
from types import SimpleNamespace
from unittest.mock import Mock, patch

from lab import Lab, download
from scenarios.bootstrap import BootstrapLab, verify_adoption_plan


class QemuPortTest(unittest.TestCase):
    def test_qemu_keeps_distinct_ports_bound_for_both_routers(self):
        with TemporaryDirectory(prefix="chr-ports-") as directory:
            root = Path(directory)
            routers = []
            processes = []
            try:
                for index in range(2):
                    router = BootstrapLab.__new__(BootstrapLab)
                    router.directory = root / str(index)
                    router.directory.mkdir()
                    router.prefix = f"10.{index + 1}.1"
                    router.address = f"{router.prefix}.1"
                    router.ssh_port = router.https_port = 0
                    router.listen = index == 0
                    router.transit_socket = root / "transit.sock"
                    router.running = Mock(return_value=True)
                    process = subprocess.Popen(
                        ["qemu-system-x86_64", "-S", "-nodefaults", "-m", "64",
                         "-display", "none", "-monitor",
                         f"unix:{router.directory / 'monitor.sock'},server=on,wait=off",
                         *router.network_args(router.directory / "capture.pcap")],
                        stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True,
                    )
                    processes.append(process)
                    deadline = time.monotonic() + 10
                    while not (router.directory / "monitor.sock").exists():
                        if process.poll() is not None or time.monotonic() > deadline:
                            self.fail("QEMU did not start its monitor")
                        time.sleep(0.01)
                    router.network_ready()
                    routers.append(router)
                ports = [port for router in routers for port in (router.ssh_port, router.https_port)]
                self.assertEqual(len(set(ports)), 4)
                for port in ports:
                    self.assertGreater(port, 0)
                    with socket.socket() as competitor, self.assertRaises(OSError):
                        competitor.bind(("127.0.0.1", port))
                router = routers[0]
                router.monitor(f"hostfwd_remove lab tcp:127.0.0.1:{router.ssh_port}")
                router.monitor(f"hostfwd_add lab tcp:127.0.0.1:0-{router.address}:22")
                router.network_ready()
                self.assertNotIn(router.ssh_port, [routers[1].ssh_port, routers[1].https_port, router.https_port])
                router.monitor(f"hostfwd_add lab udp:127.0.0.1:0-{router.address}:53")
                dns_port = router.forwarded_port("udp", 53)
                with socket.socket(type=socket.SOCK_DGRAM) as competitor, self.assertRaises(OSError):
                    competitor.bind(("127.0.0.1", dns_port))
                router.monitor(f"hostfwd_remove lab udp:127.0.0.1:{dns_port}")
            finally:
                for process in reversed(processes):
                    process.terminate()
                    try:
                        process.communicate(timeout=5)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.communicate()

    def test_missing_or_ambiguous_forward_is_rejected(self):
        router = BootstrapLab.__new__(BootstrapLab)
        row = "TCP[HOST_FORWARD] 8 127.0.0.1 34589 10.0.2.15 22 0 0\n"
        for output in ("", row + row):
            router.monitor = Mock(return_value=output)
            with self.subTest(output=output), self.assertRaisesRegex(RuntimeError, "Expected one"):
                router.forwarded_port("tcp", 22)


class BootstrapFirewallOrderTest(unittest.TestCase):
    def test_generated_scripts_preserve_original_table_order(self):
        directory = Path(__file__).resolve().parents[2] / "local-networking/bootstrap/generated"
        expected = [
            "/ip/firewall/nat", "/ip/firewall/filter",
            "/ipv6/firewall/address-list", "/ipv6/firewall/filter",
        ]
        for site in ("stationary", "kuberack"):
            with self.subTest(site=site):
                tables = [
                    line.split(" add ", 1)[0]
                    for line in (directory / f"{site}.rsc").read_text().splitlines()
                    if line.startswith(("/ip/firewall/", "/ipv6/firewall/"))
                ]
                self.assertEqual([table for table, _ in groupby(tables)], expected)


class AdoptionPlanTest(unittest.TestCase):
    def plan(self, resource_type, actions, name="management"):
        return json.dumps({
            "resource_changes": [{
                "address": f"module.bootstrap_stationary.{resource_type}.{name}",
                "type": resource_type,
                "name": name,
                "change": {"actions": actions},
            }]
        })

    def test_accepts_unchanged_router_settings(self):
        verify_adoption_plan(self.plan("routeros_ip_address", ["no-op"]))

    def test_rejects_router_drift_before_apply(self):
        for actions in (["update"], ["create"], ["delete"], ["delete", "create"]):
            with self.subTest(actions=actions), self.assertRaisesRegex(
                RuntimeError, "routeros_ip_address.management"
            ):
                verify_adoption_plan(self.plan("routeros_ip_address", actions))

    def test_only_allows_initial_firewall_order_creation(self):
        for name in ("ipv4_filter", "ipv6_filter"):
            verify_adoption_plan(self.plan("routeros_move_items", ["create"], name))
            for actions in (["update"], ["delete"], ["delete", "create"]):
                with self.assertRaises(RuntimeError):
                    verify_adoption_plan(self.plan("routeros_move_items", actions, name))
        with self.assertRaises(RuntimeError):
            verify_adoption_plan(self.plan("routeros_move_items", ["create"], "other"))

    def test_recovery_allows_rebinding_order_ids_only(self):
        verify_adoption_plan(
            self.plan("routeros_move_items", ["update"], "ipv4_filter"), recovery=True
        )
        with self.assertRaises(RuntimeError):
            verify_adoption_plan(self.plan("routeros_ip_address", ["update"]), recovery=True)
        with self.assertRaises(RuntimeError):
            verify_adoption_plan(
                self.plan("routeros_move_items", ["delete", "create"], "ipv4_filter"),
                recovery=True,
            )

    def test_only_allows_script_file_creation(self):
        for resource_type in ("local_file", "routeros_file"):
            verify_adoption_plan(self.plan(resource_type, ["create"], "script"))
            for actions, name in (
                (["update"], "script"),
                (["delete", "create"], "script"),
                (["create"], "other"),
            ):
                with (
                    self.subTest(resource_type=resource_type, actions=actions, name=name),
                    self.assertRaises(RuntimeError),
                ):
                    verify_adoption_plan(self.plan(resource_type, actions, name))


class StoreImageTest(unittest.TestCase):
    def setUp(self):
        directory = TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        self.lab = Lab(SimpleNamespace(version="7.21.3", state=self.root / "state", ssh_port=2222))
        self.image = self.root / "store/chr-7.21.3"
        self.image.mkdir(parents=True)
        (self.image / "chr-7.21.3.img").write_bytes(b"base image")

    def test_store_image_is_rooted_before_overlay_creation(self):
        self.lab.key.touch()
        with (
            patch.dict(os.environ, CHR_IMAGE=str(self.image)),
            patch("lab.run") as command,
            patch.object(self.lab, "downloaded_image") as download_image,
        ):
            self.lab.prepare()
        download_image.assert_not_called()
        root_call, overlay_call = command.call_args_list
        self.assertEqual(root_call.args[:3], ("nix-store", "--realise", str(self.image)))
        self.assertIn("--indirect", root_call.args)
        self.assertIn(str(self.lab.root / "images/nix-roots" / self.image.name), root_call.args)
        self.assertEqual(overlay_call.args[:2], ("qemu-img", "create"))
        self.assertIn(str(self.image / "chr-7.21.3.img"), overlay_call.args)

    def test_shared_image_directory_uses_a_stable_gc_root_path(self):
        shared = self.root / "shared-images"
        shared.mkdir()
        (self.lab.root / "images").symlink_to(shared, target_is_directory=True)
        with patch.dict(os.environ, CHR_IMAGE=str(self.image)), patch("lab.run") as command:
            self.lab.base_image()
        self.assertIn(str(shared / "nix-roots" / self.image.name), command.call_args.args)

    def test_other_versions_use_download_cache(self):
        self.lab.version = "other"
        with (
            patch.dict(os.environ, CHR_IMAGE=str(self.image)),
            patch("lab.run") as command,
            patch.object(self.lab, "downloaded_image", return_value="downloaded") as download_image,
        ):
            self.assertEqual(self.lab.base_image(), "downloaded")
        download_image.assert_called_once()
        command.assert_not_called()

    def test_gc_root_failure_prevents_overlay_creation(self):
        with (
            patch.dict(os.environ, CHR_IMAGE=str(self.image)),
            patch("lab.run", side_effect=subprocess.CalledProcessError(1, "nix-store")) as command,
            self.assertRaises(subprocess.CalledProcessError),
        ):
            self.lab.prepare()
        command.assert_called_once()


class DownloadTest(unittest.TestCase):
    def setUp(self):
        directory = TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.destination = Path(directory.name) / "chr.img.zip"
        self.member = "chr.img"
        sleep = patch("lab.time.sleep")
        sleep.start()
        self.addCleanup(sleep.stop)

    def valid_download(self, *args):
        with zipfile.ZipFile(args[-1], "w") as archive:
            archive.writestr(self.member, b"router image")

    def test_retries_interrupted_transfer_without_caching_partial_file(self):
        def transfer(*args):
            if command.call_count == 1:
                Path(args[-1]).write_bytes(b"partial")
                raise subprocess.CalledProcessError(56, args)
            self.assertFalse(Path(args[-1]).exists())
            self.valid_download(*args)

        with patch("lab.run", side_effect=transfer) as command:
            download("https://example.test/chr.zip", self.destination, self.member)
        self.assertEqual(command.call_count, 2)
        with zipfile.ZipFile(self.destination) as archive:
            self.assertEqual(archive.read(self.member), b"router image")

    def test_retries_invalid_content_even_when_curl_succeeds(self):
        def transfer(*args):
            if command.call_count == 1:
                Path(args[-1]).write_bytes(b"not a zip")
            else:
                self.valid_download(*args)

        with patch("lab.run", side_effect=transfer) as command:
            download("https://example.test/chr.zip", self.destination, self.member)
        self.assertEqual(command.call_count, 2)

    def test_replaces_invalid_cache_and_reuses_valid_cache(self):
        self.destination.write_bytes(b"broken cache")
        with patch("lab.run", side_effect=self.valid_download) as command:
            download("https://example.test/chr.zip", self.destination, self.member)
            download("https://example.test/chr.zip", self.destination, self.member)
        command.assert_called_once()

    def test_wrong_archive_member_exhausts_retries_without_cached_files(self):
        def transfer(*args):
            with zipfile.ZipFile(args[-1], "w") as archive:
                archive.writestr("wrong.img", b"wrong image")

        with patch("lab.run", side_effect=transfer) as command:
            with self.assertRaisesRegex(RuntimeError, "valid CHR image"):
                download("https://example.test/chr.zip", self.destination, self.member)
        self.assertEqual(command.call_count, 3)
        self.assertEqual(list(self.destination.parent.iterdir()), [])

    def test_failed_extraction_does_not_leave_an_image(self):
        lab = Lab(SimpleNamespace(version="test", state=self.destination.parent, ssh_port=2222))
        with patch("lab.download") as fetch, patch("lab.run") as command:
            fetch.side_effect = lambda url, path, member: self.valid_download(str(path))
            self.member = "chr-test.img"
            with patch("lab.shutil.copyfileobj", side_effect=OSError("disk full")):
                with self.assertRaisesRegex(OSError, "disk full"):
                    lab.prepare()
        command.assert_not_called()
        self.assertFalse((lab.root / "images/chr-test.img").exists())
        self.assertFalse((lab.root / "images/chr-test.img.part").exists())


class BootstrapConsoleTest(unittest.TestCase):
    def test_retries_saved_password_after_blank_login_fails(self):
        with TemporaryDirectory() as directory:
            lab = Lab(SimpleNamespace(version="7.21.3", state=Path(directory), ssh_port=2222))
            (lab.directory / "password").write_text("saved-password")
            lab.key.with_suffix(".pub").write_text("ssh-ed25519 test")
            console = Mock()
            console.recv.side_effect = [
                b"Login:", b"Password:",
                b"Login failed, incorrect username or password\r\nLogin:",
                b"Password:", b"[admin@chr-lab] >",
                *([b"[admin@chr-lab] >"] * 5),
            ]
            with patch("lab.socket.socket") as socket, patch("lab.select.select", return_value=([console], [], [])):
                socket.return_value.__enter__.return_value = console
                lab.bootstrap()
            sent = [call.args[0] for call in console.sendall.call_args_list]
            self.assertEqual(sent[:5], [b"\r", b"admin+ct\r", b"\r", b"admin+ct\r", b"saved-password\r"])
            self.assertEqual((lab.directory / "password").read_text(), "saved-password")

    def test_rejected_saved_password_fails_without_repeated_attempts(self):
        with TemporaryDirectory() as directory:
            lab = Lab(SimpleNamespace(version="7.21.3", state=Path(directory), ssh_port=2222))
            (lab.directory / "password").write_text("saved-password")
            lab.key.with_suffix(".pub").write_text("ssh-ed25519 test")
            console = Mock()
            console.recv.side_effect = [
                b"Login:", b"Password:", b"Login failed", b"Login:",
                b"Password:", b"Login failed",
            ]
            with patch("lab.socket.socket") as socket, patch("lab.select.select", return_value=([console], [], [])):
                socket.return_value.__enter__.return_value = console
                with self.assertRaisesRegex(RuntimeError, "saved lab password"):
                    lab.bootstrap()
            sent = [call.args[0] for call in console.sendall.call_args_list]
            self.assertEqual(sent.count(b"saved-password\r"), 1)

    def test_repeated_password_prompt_does_not_send_password_as_command(self):
        with TemporaryDirectory() as directory:
            lab = Lab(
                SimpleNamespace(version="7.21.3", state=Path(directory), ssh_port=2222)
            )
            lab.key.with_suffix(".pub").write_text("ssh-ed25519 test")
            console = Mock()
            console.recv.side_effect = [
                b"Login:",
                b"Password:",
                b"Do you want to see the software license",
                b"new password>",
                b"new password>",
                b"repeat new password>",
                b"repeat new password>",
                b"Password changed\r\n[admin@MikroTik] >",
                *([b"\r\n[admin@chr-lab] >"] * 5),
            ]
            with (
                patch("lab.socket.socket") as socket,
                patch("lab.select.select", return_value=([console], [], [])),
            ):
                socket.return_value.__enter__.return_value = console
                lab.bootstrap()
            password = (lab.directory / "password").read_text().encode() + b"\r"
            self.assertEqual(
                sum(
                    call.args[0] == password for call in console.sendall.call_args_list
                ),
                2,
            )


class ForwardTest(unittest.TestCase):
    def setUp(self):
        self.lab = Lab.__new__(Lab)
        self.lab.ssh_port = 2222
        self.lab.monitor = Mock()

    def test_removes_forward_after_scenario_failure(self):
        with (
            self.assertRaisesRegex(RuntimeError, "experiment failed"),
            self.lab.forward("udp", 1053, 53),
        ):
            raise RuntimeError("experiment failed")
        self.assertEqual(
            [call.args[0] for call in self.lab.monitor.call_args_list],
            [
                "hostfwd_add lab udp:127.0.0.1:1053-:53",
                "hostfwd_remove lab udp:127.0.0.1:1053",
            ],
        )

    def test_failed_add_does_not_remove_an_existing_forward(self):
        self.lab.monitor.side_effect = RuntimeError("port in use")
        with (
            self.assertRaisesRegex(RuntimeError, "port in use"),
            self.lab.forward("tcp", 1053, 53),
        ):
            self.fail("scenario must not run")
        self.lab.monitor.assert_called_once()

    def test_forward_cannot_replace_management_port(self):
        with (
            self.assertRaisesRegex(ValueError, "SSH management port"),
            self.lab.forward("tcp", 2222, 80),
        ):
            self.fail("scenario must not run")
        self.lab.monitor.assert_not_called()

    def test_validates_forward_before_sending_monitor_commands(self):
        for protocol, host_port, guest_port in [
            ("icmp", 1053, 53),
            ("udp", 53, 53),
            ("tcp", 8080, 65536),
        ]:
            with (
                self.subTest(
                    protocol=protocol, host_port=host_port, guest_port=guest_port
                ),
                self.assertRaises(ValueError),
                self.lab.forward(protocol, host_port, guest_port),
            ):
                self.fail("scenario must not run")
        self.lab.monitor.assert_not_called()


if __name__ == "__main__":
    unittest.main()
