import contextlib
import importlib.util
import io
import json
import sys
import ssl
import urllib.error
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

spec = importlib.util.spec_from_file_location(
    "adopt_bootstrap", Path(__file__).with_name("adopt-bootstrap.py")
)
adopt = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = adopt
spec.loader.exec_module(adopt)

PROVIDER = 'provider["registry.terraform.io/terraform-routeros/routeros"].stationary'
BINDING = adopt.Binding(
    "stationary",
    "routeros_ip_address.lan",
    "ip/address",
    json.dumps({"address": "10.1.1.1/24", "interface": "bridge"}),
    False,
)


def state(bindings):
    return json.dumps(
        {
            "version": 4,
            "serial": 1,
            "resources": [
                {
                    "mode": "managed",
                    "type": "routeros_ip_address",
                    "name": name,
                    "provider": PROVIDER,
                    "instances": [{"attributes": {"id": identifier}}],
                }
                for name, identifier in bindings.items()
            ],
        }
    )


class BootstrapTlsTest(unittest.TestCase):
    def manifest(self, insecure=False):
        return json.dumps({"routers": {"stationary": {
            "url": "https://router.test", "username": "admin",
            "password": "test", "insecure": insecure,
        }}})

    def test_certificate_failure_explains_explicit_bootstrap_override(self):
        failure = urllib.error.URLError(ssl.SSLCertVerificationError(1, "self-signed"))
        with patch.object(adopt.urllib.request, "urlopen", side_effect=failure) as request:
            with self.assertRaisesRegex(RuntimeError, "TF_VAR_ALLOW_INSECURE=true"):
                adopt.rest_fetch(self.manifest())("stationary", "ip/address")
        request.assert_called_once()
        self.assertEqual(request.call_args.kwargs["context"].verify_mode, ssl.CERT_REQUIRED)

    def test_explicit_override_uses_unverified_context(self):
        with patch.object(adopt.urllib.request, "urlopen") as request:
            request.return_value.__enter__.return_value.read.return_value = b"[]"
            self.assertEqual(adopt.rest_fetch(self.manifest(True))("stationary", "ip/address"), "[]")
        self.assertEqual(request.call_args.kwargs["context"].verify_mode, ssl.CERT_NONE)

    def test_network_failure_does_not_suggest_disabling_tls(self):
        with patch.object(adopt.urllib.request, "urlopen", side_effect=urllib.error.URLError("refused")):
            with self.assertRaisesRegex(RuntimeError, "Cannot read stationary /ip/address: refused") as error:
                adopt.rest_fetch(self.manifest())("stationary", "ip/address")
        self.assertNotIn("ALLOW_INSECURE", str(error.exception))


class FakeTerraform:
    def __init__(self, initial):
        self.bindings = dict(initial)
        self.calls = []

    def state(self):
        return state(self.bindings)

    def call(self, *args):
        self.calls.append(args)
        if args[:2] == ("state", "rm"):
            for address in args[3:]:
                del self.bindings[address.split(".")[-1]]
        elif args[0] == "import":
            self.bindings[args[-2].split(".")[-1]] = args[-1]
        else:
            raise AssertionError(args)


def response(identifier="*9"):
    return json.dumps(
        [{".id": identifier, "address": "10.1.1.1/24", "interface": "bridge"}]
    )


class AdoptionTest(unittest.TestCase):
    def run_reconcile(self, terraform, fetch=None, apply=True):
        with (
            tempfile.TemporaryDirectory() as directory,
            contextlib.redirect_stdout(io.StringIO()),
        ):
            adopt.reconcile(
                terraform,
                [BINDING],
                fetch or (lambda *_: response()),
                apply,
                Path(directory),
            )
            return list(Path(directory).rglob("*.tfstate")) != []

    def test_firewall_selector_disambiguates_chain_and_ignores_dynamic_rules(self):
        binding = adopt.Binding(
            "stationary", 'routeros_ip_firewall_filter.rules["input_invalid"]',
            "ip/firewall/filter",
            json.dumps({"chain": "input", "comment": "bootstrap: drop invalid", "dynamic": "false"}),
            False,
        )
        rows = [
            {".id": "*1", "chain": "forward", "comment": "bootstrap: drop invalid", "dynamic": "false"},
            {".id": "*2", "chain": "input", "comment": "bootstrap: drop invalid", "dynamic": "true"},
            {".id": "*3", "chain": "input", "comment": "bootstrap: drop invalid", "dynamic": "false"},
        ]
        self.assertEqual(adopt.match_id(binding, json.dumps(rows)), "*3")
        rows[-1][".id"] = "*A"
        self.assertEqual(adopt.match_id(binding, json.dumps(rows)), "*A")
        rows.append(dict(rows[-1], **{".id": "*B"}))
        with self.assertRaisesRegex(RuntimeError, "Ambiguous"):
            adopt.match_id(binding, json.dumps(rows))
        with self.assertRaisesRegex(RuntimeError, "missing"):
            adopt.match_id(binding, json.dumps(rows[:2]))

    def test_old_address_is_rejected_without_state_changes(self):
        terraform = FakeTerraform({"old": "*9"})
        with self.assertRaisesRegex(RuntimeError, "already bound to routeros_ip_address.old"):
            self.run_reconcile(terraform)
        self.assertEqual(terraform.calls, [])

    def test_preview_never_mutates_state(self):
        terraform = FakeTerraform({"lan": "*2"})
        self.assertFalse(self.run_reconcile(terraform, apply=False))
        self.assertEqual(terraform.calls, [])

    def test_fresh_import_then_repeat_is_noop(self):
        terraform = FakeTerraform({})
        self.assertTrue(self.run_reconcile(terraform))
        self.assertEqual(terraform.bindings, {"lan": "*9"})
        terraform.calls.clear()
        self.assertFalse(self.run_reconcile(terraform))
        self.assertEqual(terraform.calls, [])

    def test_stale_id_rebound_without_touching_other_resources(self):
        terraform = FakeTerraform({"lan": "*2", "other": "*7"})
        self.run_reconcile(terraform)
        self.assertEqual(terraform.bindings, {"lan": "*9", "other": "*7"})
        self.assertEqual(
            terraform.calls[0], ("state", "rm", "-lock-timeout=30s", BINDING.address)
        )

    def test_ambiguous_matches_fail_before_any_write(self):
        terraform = FakeTerraform({"lan": "*2"})
        data = response().replace(
            "}]", '}, {".id":"*8","address":"10.1.1.1/24","interface":"bridge"}]'
        )
        with self.assertRaisesRegex(RuntimeError, "Ambiguous"):
            self.run_reconcile(terraform, lambda *_: data)
        self.assertEqual(terraform.calls, [])

    def test_missing_required_object_does_not_forget_old_binding(self):
        terraform = FakeTerraform({"lan": "*2"})
        with self.assertRaisesRegex(RuntimeError, "missing"):
            self.run_reconcile(terraform, lambda *_: "[]")
        self.assertEqual(terraform.calls, [])

    def test_id_owned_by_another_resource_is_not_stolen(self):
        terraform = FakeTerraform({"lan": "*2", "other": "*9"})
        with self.assertRaisesRegex(RuntimeError, "already bound"):
            self.run_reconcile(terraform)
        self.assertEqual(terraform.calls, [])

    def test_selector_checks_interface_as_well_as_address(self):
        with self.assertRaisesRegex(RuntimeError, "missing"):
            adopt.match_id(BINDING, response().replace('"bridge"', '"wrong-bridge"'))

    def test_state_change_during_discovery_aborts(self):
        terraform = FakeTerraform({"lan": "*2"})
        terraform.state = Mock(side_effect=[state({"lan": "*2"}), state({"lan": "*3"})])
        with self.assertRaisesRegex(RuntimeError, "state changed"):
            self.run_reconcile(terraform)
        self.assertEqual(terraform.calls, [])

    def test_optional_missing_object_forgets_stale_binding(self):
        binding = adopt.Binding(
            "stationary", BINDING.address, BINDING.path, BINDING.selector, True
        )
        terraform = FakeTerraform({"lan": "*2"})
        with (
            tempfile.TemporaryDirectory() as directory,
            contextlib.redirect_stdout(io.StringIO()),
        ):
            adopt.reconcile(
                terraform, [binding], lambda *_: "[]", True, Path(directory)
            )
            self.assertEqual(terraform.bindings, {})
            terraform.calls.clear()
            adopt.reconcile(
                terraform, [binding], lambda *_: "[]", True, Path(directory)
            )
            self.assertEqual(terraform.calls, [])

    def test_partial_failure_can_be_retried(self):
        terraform = FakeTerraform({"lan": "*2"})
        call = terraform.call

        def fail_import(*args):
            if args[0] == "import":
                raise RuntimeError("temporary failure")
            return call(*args)

        terraform.call = fail_import
        with self.assertRaisesRegex(RuntimeError, "stopped partway"):
            self.run_reconcile(terraform)
        self.assertEqual(terraform.bindings, {})
        terraform.call = call
        self.run_reconcile(terraform)
        self.assertEqual(terraform.bindings, {"lan": "*9"})

    def test_check_result_order_does_not_look_like_a_state_write(self):
        first = '{"serial":1,"check_results":[{"config_addr":"b"},{"config_addr":"a"}]}'
        second = (
            '{"check_results":[{"config_addr":"a"},{"config_addr":"b"}],"serial":1}'
        )
        self.assertEqual(
            adopt.state_fingerprint(first), adopt.state_fingerprint(second)
        )
        self.assertNotEqual(
            adopt.state_fingerprint(first),
            adopt.state_fingerprint(second.replace('"serial":1', '"serial":2')),
        )

    def test_wrong_router_provider_is_rejected(self):
        entries = [
            adopt.Entry(
                BINDING.address,
                "*9",
                PROVIDER.replace("stationary", "kuberack"),
                "routeros_ip_address",
            )
        ]
        with self.assertRaisesRegex(RuntimeError, "Unexpected provider"):
            adopt.changes_for([BINDING], entries, lambda *_: response())

    def test_backup_contains_original_state_with_private_permissions(self):
        terraform = FakeTerraform({"lan": "*2"})
        original = terraform.state()
        with (
            tempfile.TemporaryDirectory() as directory,
            contextlib.redirect_stdout(io.StringIO()),
        ):
            adopt.reconcile(
                terraform, [BINDING], lambda *_: response(), True, Path(directory)
            )
            (backup,) = Path(directory).rglob("*.tfstate")
            self.assertEqual(backup.read_text(), original)
            self.assertEqual(backup.stat().st_mode & 0o777, 0o600)
            self.assertEqual(backup.parent.stat().st_mode & 0o777, 0o700)

    def test_indexed_module_addresses_preserved(self):
        document = json.dumps(
            {
                "resources": [
                    {
                        "mode": "managed",
                        "module": "module.stationary.module.dns",
                        "type": "routeros_ip_dns_record",
                        "name": "a_record",
                        "provider": PROVIDER,
                        "instances": [
                            {"index_key": "router.example", "attributes": {"id": "*4"}}
                        ],
                    }
                ]
            }
        )
        self.assertEqual(
            adopt.state_entries(document)[0].address,
            'module.stationary.module.dns.routeros_ip_dns_record.a_record["router.example"]',
        )

    def test_binary_selection_follows_initialized_lock_file(self):
        with (
            tempfile.TemporaryDirectory() as directory,
            patch.object(
                adopt.shutil, "which", side_effect=lambda name: f"/bin/{name}"
            ),
        ):
            directory = Path(directory)
            lock = directory / ".terraform.lock.hcl"
            lock.write_text(
                'provider "registry.terraform.io/terraform-routeros/routeros" {}'
            )
            self.assertEqual(adopt.terraform_binary(directory), "/bin/terraform")
            lock.write_text(
                'provider "registry.opentofu.org/terraform-routeros/routeros" {}'
            )
            self.assertEqual(adopt.terraform_binary(directory), "/bin/tofu")

    def test_manifest_console_decodes_without_logging_credentials(self):
        terraform = adopt.Terraform("terraform", Path("."))
        expected = '{"bindings":[],"routers":{}}'
        terraform.call = Mock(
            return_value="Acquiring state lock...\n" + json.dumps(expected) + "\n"
        )
        self.assertEqual(terraform.manifest().strip(), expected)


if __name__ == "__main__":
    unittest.main()
