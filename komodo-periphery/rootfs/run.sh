#!/command/with-contenv bashio
# Home Assistant supplies options.json; keep authentication state in persistent /data.
set -euo pipefail
umask 077
mkdir -p /data/komodo/keys /data/komodo/ssl
config=/data/komodo/periphery.config.json
pending=$(mktemp /data/komodo/config.XXXXXX)
trap 'rm -f "$pending"' EXIT
if ! jq -e -f /periphery-config.jq /data/options.json > "$pending"; then
    bashio::log.error "Invalid Periphery options; refusing to start."
    exit 1
fi
mv "$pending" "$config"
for field in stack_dir repo_dir build_dir; do
    directory=$(jq -r --arg field "$field" '.[$field]' "$config")
    mkdir -p -- "$directory"
done
# Periphery generates its TLS certificate and Noise key if absent, and reuses
# them on subsequent starts. The trusted Core public key also lives under /data.
bashio::log.info "Starting Komodo Periphery with persistent authentication state"
# Do not log the configuration or credentials. exec preserves signals and errors.
exec /usr/local/bin/periphery --config-path "$config"
