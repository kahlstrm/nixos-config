#!/usr/bin/env python3
"""Preview or reconcile bootstrap resource bindings without changing router configuration."""

import argparse
import base64
import os
import shutil
import ssl
import subprocess
import sys
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import urlsplit


def jq(document, expression, *args):
    result = subprocess.run(
        ["jq", *args, expression],
        input=document,
        text=True,
        capture_output=True,
        check=True,
    )
    return result.stdout


def rows(document, expression):
    output = jq(document, f"({expression}) | map(tostring | @base64) | @tsv", "-r")
    return [
        [base64.b64decode(field).decode() for field in line.split("\t")]
        for line in output.splitlines()
    ]


@dataclass(frozen=True)
class Binding:
    router: str
    address: str
    path: str
    selector: str
    optional: bool


@dataclass(frozen=True)
class Entry:
    address: str
    id: str
    provider: str
    type: str


@dataclass(frozen=True)
class Change:
    binding: Binding
    before: str | None
    after: str | None

    @property
    def action(self):
        if self.after is None:
            return "forget" if self.before is not None else "absent"
        if self.before == self.after:
            return "keep"
        return "import" if self.before is None else "rebind"


def state_entries(document):
    return [
        Entry(*record)
        for record in rows(
            document,
            """
      .resources[]? | select(.mode == "managed") as $resource |
      .instances[]? | select(.deposed == null) |
      [([$resource.module, ($resource.type + "." + $resource.name)] | map(select(. != null)) | join(".")) +
       (if has("index_key") then "[" + (.index_key | tojson) + "]" else "" end),
       (.attributes.id // ""), $resource.provider, $resource.type]
    """,
        )
    ]


def match_id(binding, document):
    if binding.path == "ipv6/settings":
        jq(
            document,
            'if type == "object" and has("disable-ipv6") then true else error("Invalid IPv6 settings response") end',
            "-e",
        )
        return "ipv6.settings"
    matches = rows_with_selector(document, binding.selector)
    if len(matches) > 1:
        raise RuntimeError(f"Ambiguous router objects: {binding.address}")
    if not matches:
        if binding.optional:
            return None
        raise RuntimeError(
            f"Bootstrap object missing: {binding.address}; run bootstrap first"
        )
    identifier = matches[0]
    if not identifier.startswith("*"):
        raise RuntimeError(f"Invalid RouterOS ID for {binding.address}")
    return identifier


def rows_with_selector(document, selector):
    result = jq(
        document,
        """
      if type != "array" then error("Expected RouterOS object list") else . end |
      .[] | select(. as $item | $selector | to_entries | all(.[]; $item[.key] == .value)) |
      .[".id"]
    """,
        "-r",
        "--argjson",
        "selector",
        selector,
    )
    return result.splitlines()


def changes_for(bindings, entries, fetch):
    by_address = {entry.address: entry for entry in entries}
    changes = []
    cache = {}
    for binding in bindings:
        key = binding.router, binding.path
        if key not in cache:
            cache[key] = fetch(*key)
        after = match_id(binding, cache[key])
        before = by_address.get(binding.address)
        if before and not before.provider.endswith(f"].{binding.router}"):
            raise RuntimeError(
                f"Unexpected provider binding for {binding.address}: {before.provider}"
            )
        changes.append(Change(binding, before.id if before else None, after))
    replacements = {
        change.binding.address
        for change in changes
        if change.action in ("rebind", "forget")
    }
    for change in changes:
        if change.after is None:
            continue
        # Module prefixes do not identify provider ownership for root resources.
        for entry in entries:
            if (
                entry.address != change.binding.address
                and entry.address not in replacements
                and entry.provider.endswith(f"].{change.binding.router}")
                and entry.id == change.after
                and (f"{entry.type}." in change.binding.address)
            ):
                raise RuntimeError(
                    f"Router object for {change.binding.address} is already bound to {entry.address}"
                )
    return changes


class Terraform:
    def __init__(self, binary, directory):
        self.binary = binary
        self.directory = directory

    def call(self, *args, input=None):
        result = subprocess.run(
            [self.binary, *args],
            cwd=self.directory,
            input=input,
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode:
            raise RuntimeError(
                f"Terraform {' '.join(args[:2])} failed: {result.stderr.strip()}"
            )
        return result.stdout

    def state(self):
        result = subprocess.run(
            [self.binary, "state", "pull"],
            cwd=self.directory,
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode and "no state file" not in result.stderr.lower():
            raise RuntimeError(f"Cannot read Terraform state: {result.stderr.strip()}")
        return result.stdout.strip() or '{"version":4,"serial":0,"resources":[]}'

    def manifest(self):
        output = self.call(
            "console",
            "-no-color",
            input="nonsensitive(jsonencode(local.bootstrap_adoption))\n",
        )
        return jq(output, 'select(startswith("\\"")) | fromjson', "-Rr")


def rest_fetch(routers):
    connections = {}
    for name, url, username, password, insecure in rows(
        routers,
        ".routers | to_entries[] | [.key, .value.url, .value.username, .value.password, (.value.insecure // false)]",
    ):
        url = url if "://" in url else f"https://{url}"
        parsed = urlsplit(url)
        if (
            parsed.scheme != "https"
            or parsed.username
            or parsed.query
            or parsed.fragment
        ):
            raise RuntimeError(f"Expected an HTTPS management URL for {name}")
        connections[name] = url.rstrip("/"), username, password, insecure == "true"

    def fetch(router, path):
        url, username, password, insecure = connections[router]
        context = (
            ssl._create_unverified_context()
            if insecure
            else ssl.create_default_context()
        )
        request = urllib.request.Request(
            f"{url}/rest/{path}",
            headers={
                "Authorization": "Basic "
                + base64.b64encode(f"{username}:{password}".encode()).decode()
            },
        )
        try:
            with urllib.request.urlopen(
                request, context=context, timeout=15
            ) as response:
                return response.read().decode()
        except urllib.error.URLError as error:
            if isinstance(error.reason, ssl.SSLCertVerificationError):
                raise RuntimeError(
                    f"TLS certificate verification failed for {router}. "
                    "After bootstrap/reset, use TF_VAR_ALLOW_INSECURE=true for adoption "
                    "and the initial Terraform apply that installs managed certificates. "
                    "Remove the override afterward. For an already commissioned router, "
                    "check its certificate and hostname."
                ) from error
            raise RuntimeError(
                f"Cannot read {router} /{path}: {error.reason}"
            ) from error

    return fetch


def state_fingerprint(document):
    # OpenTofu emits validation results in an unstable order between state pulls.
    return jq(
        document,
        "if .check_results != null then .check_results |= sort_by(.config_addr) else . end",
        "-Sc",
    )


def reconcile(terraform, bindings, fetch, apply, backup_root):
    snapshot = terraform.state()
    entries = state_entries(snapshot)
    changes = changes_for(bindings, entries, fetch)
    for change in changes:
        print(
            f"{change.action:6} {change.binding.address}: {change.before or '-'} -> {change.after or '-'}"
        )
    pending = [
        change for change in changes if change.action in ("import", "rebind", "forget")
    ]
    if not pending:
        print("No state changes needed.")
        return
    if not apply:
        print("Preview only. Use --apply to reconcile these state bindings.")
        return
    if state_fingerprint(terraform.state()) != state_fingerprint(snapshot):
        raise RuntimeError(
            "Terraform state changed during discovery; rerun the command"
        )
    if changes_for(bindings, entries, fetch) != changes:
        raise RuntimeError("Router objects changed during discovery; rerun the command")
    backup = backup_root / str(time.time_ns())
    backup.mkdir(parents=True, mode=0o700)
    (backup / "terraform.tfstate").write_text(snapshot)
    (backup / "terraform.tfstate").chmod(0o600)
    print(f"State backup: {backup / 'terraform.tfstate'}")
    stale = [
        change.binding.address
        for change in pending
        if change.action in ("rebind", "forget")
    ]
    try:
        if stale:
            terraform.call("state", "rm", "-lock-timeout=30s", *stale)
        for change in pending:
            if change.after is None:
                continue
            terraform.call(
                "import",
                "-no-color",
                "-input=false",
                "-lock-timeout=30s",
                change.binding.address,
                change.after,
            )
    except RuntimeError as error:
        raise RuntimeError(
            f"{error}\nAdoption stopped partway through; fix the error and rerun. "
            f"The original state is backed up at {backup / 'terraform.tfstate'}."
        ) from error
    actual = {entry.address: entry.id for entry in state_entries(terraform.state())}
    for change in changes:
        if actual.get(change.binding.address) != change.after:
            raise RuntimeError(
                f"Import did not establish the expected binding: {change.binding.address}"
            )
    print("Bootstrap state reconciled. Review a normal Terraform plan next.")


def terraform_binary(directory):
    lock = directory / ".terraform.lock.hcl"
    preferred = (
        "tofu"
        if lock.exists() and "registry.opentofu.org/" in lock.read_text()
        else "terraform"
    )
    return shutil.which(preferred) or shutil.which("terraform") or shutil.which("tofu")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--directory", type=Path, default=Path(__file__).resolve().parents[1]
    )
    parser.add_argument(
        "--router",
        action="append",
        required=True,
        help="Router to reconcile; repeat for multiple routers",
    )
    parser.add_argument(
        "--terraform",
        help="Override the binary inferred from the directory lock file",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Update state bindings; default is preview only",
    )
    args = parser.parse_args()
    args.terraform = args.terraform or terraform_binary(args.directory)
    if not args.terraform:
        parser.error("terraform or tofu is required")
    os.umask(0o077)
    terraform = Terraform(args.terraform, args.directory.resolve())
    manifest = terraform.manifest()
    bindings = [
        Binding(router, address, path, selector, optional == "true")
        for router, address, path, selector, optional in rows(
            manifest,
            ".bindings[] | [.router, .address, .path, (.match | tojson), (.optional // false)]",
        )
    ]
    known = {binding.router for binding in bindings}
    if set(args.router) - known:
        parser.error("Unknown router selection")
    bindings = [binding for binding in bindings if binding.router in args.router]
    backup_root = (
        Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
        / "infra-bootstrap-adopt"
    )
    reconcile(
        terraform,
        bindings,
        rest_fetch(manifest),
        args.apply,
        backup_root,
    )


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"Error: {error}", file=sys.stderr)
        sys.exit(1)
