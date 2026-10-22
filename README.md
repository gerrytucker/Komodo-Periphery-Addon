# Komodo Periphery for Home Assistant OS

This fork of [cgfm/Komodo-Periphery-Addon](https://github.com/cgfm/Komodo-Periphery-Addon)
adds Komodo v2 onboarding and persistent authentication. Add-on version **2.1.1**
bundles **Periphery 2.3.3**. The binary is pinned for reproducible installs;
future upstream changes must be reviewed and merged into this fork.

## Install

In Home Assistant, open Settings → Apps → Install app → ⋮ → Repositories and add:

```
https://github.com/gerrytucker/Komodo-Periphery-Addon
```

Install the app from this repository. Stop the original app first to avoid a
port conflict. A different repository has separate app data: existing keys are
not automatically transferred. Do not run both as the same Komodo server.

## Connect to Komodo (recommended: outbound)

1. In Komodo Core, open Settings → Onboarding and create a short-lived key.
2. Configure the app with the example below, using your Core address and key.
3. Save and start the app. Check the log and confirm the server is connected in
   Komodo. You do not need to manually create the server first.
4. After successful onboarding, clear `onboarding_key` and restart the app.
   Confirm it reconnects before enabling Start on boot / Watchdog.

```yaml
core_url: "https://komodo.example.com"
connect_as: "homeassistant"
onboarding_key: "PASTE_YOUR_ONBOARDING_KEY_HERE"
core_public_keys: []
passkey: ""
ssl_enabled: true
logging_level: "info"
disable_terminals: true
disable_container_exec: true
monitoring_interval: "30-sec"
container_stats_interval: "1-min"
stack_directory: "/share/komodo/stacks"
repo_directory: "/share/komodo/repos"
build_directory: "/share/komodo/builds"
include_disk_mounts: []
exclude_disk_mounts: ["/dev", "/proc", "/sys"]
```

Use an HTTP(S) origin without a path; legacy `ws://` and `wss://` values are
normalized. The Core address must be reachable from HAOS. Reverse proxies must
forward WebSockets and must not interpose an interactive login page.
`connect_as` must be unique and remain unchanged after onboarding.

Outbound mode disables the inbound listener, so port 8120 is not required.
`ssl_enabled` applies to the inbound listener only; HTTPS Core certificate
validation stays enabled. Keys and learned Core trust are stored under
`/data/komodo/keys`, surviving app restarts and updates (not uninstalling).
Include the app in Home Assistant backups to preserve them.

## Inbound / legacy connections

Leave `core_url` empty and set `core_public_keys` to the Core public key(s).
Configure Core to reach the HAOS IP on the mapped port 8120. A legacy `passkey`
is supported for older Core setups. Without either authentication method the
app refuses to start. Credentials are never printed by the startup script.
Do not paste an onboarding key into the legacy passkey field.

## HAOS scope

Use Home Assistant to update and manage Supervisor-owned apps and containers.
Periphery has Docker access; disabling terminals does not make it read-only.
Containerized host statistics and filesystem access are limited to what HAOS
exposes to this app. This is not a general-purpose HAOS Docker host replacement.

## Development / validation

Run `python3 -m unittest discover -s tests -v`, `bash -n komodo-periphery/rootfs/run.sh`,
and `git diff --check`. Tests require jq. Build the image from `komodo-periphery/`
with Docker before releasing. The health check measures process liveness, not
Core connectivity; check connection status in Komodo.

The compatibility changes are intended for a later upstream pull request;
no upstream submission has been made yet.
