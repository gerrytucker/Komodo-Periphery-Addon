"""Regression tests for HA options -> Periphery v2.3.3 configuration."""
import json
import subprocess
import unittest
from pathlib import Path

FILTER = Path(__file__).resolve().parents[1] / 'komodo-periphery/rootfs/periphery-config.jq'

def generate(options):
    result = subprocess.run(['jq', '-e', '-f', str(FILTER)], input=json.dumps(options), text=True, capture_output=True)
    if result.returncode:
        raise ValueError(result.stderr)
    return json.loads(result.stdout)

class ConfigTests(unittest.TestCase):
    def test_outbound_onboarding(self):
        c = generate(dict(core_url='wss://core.example.com', connect_as='HAOS', onboarding_key='test-key'))
        self.assertEqual(c['core_addresses'], ['https://core.example.com'])
        self.assertEqual(c['onboarding_key'], 'test-key')
        self.assertFalse(c['server_enabled'])
        self.assertEqual(c['private_key'], 'file:/data/komodo/keys/periphery.key')
        self.assertNotIn('core_public_keys', c)  # use persisted Core trust, not an empty allowlist

    def test_core_url_trailing_slash(self):
        c = generate(dict(core_url="https://core.example.com/", connect_as="HAOS"))
        self.assertEqual(c["core_addresses"], ["https://core.example.com"])

    def test_restart_without_onboarding(self):
        c = generate(dict(core_url='http://192.0.2.10:9120', connect_as='HAOS'))
        self.assertNotIn('onboarding_key', c)
        self.assertEqual(c['root_directory'], '/data/komodo')

    def test_inbound_public_key(self):
        c = generate(dict(core_public_keys=['test-public-key'], ssl_enabled=False, disable_container_exec=True))
        self.assertTrue(c['server_enabled'])
        self.assertFalse(c['ssl_enabled'])
        self.assertTrue(c['disable_container_terminals'])
        self.assertEqual(c['core_public_keys'], ['test-public-key'])

    def test_legacy_passkey_escaping(self):
        secret = 'quotes" backslash\\ newline\n$(not-a-command)'
        c = generate(dict(passkey=secret))
        self.assertEqual(c['passkeys'], [secret])

    def test_reject_unauthenticated_listener(self):
        with self.assertRaises(ValueError): generate({})

    def test_reject_missing_server_name(self):
        with self.assertRaises(ValueError): generate(dict(core_url='https://core.example.com'))

    def test_reject_invalid_url(self):
        for url in ['ftp://example.com', 'https://example.com/path', 'https://bad host']:
            with self.assertRaises(ValueError): generate(dict(core_url=url, connect_as='HAOS'))

if __name__ == '__main__': unittest.main()
