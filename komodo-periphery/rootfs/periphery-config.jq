# JSON avoids interpolating secrets and paths into TOML or shell code.
def nonempty: type == "string" and length > 0;
. as $o |
($o.core_url // "" | sub("^ws://"; "http://") | sub("^wss://"; "https://")) as $core |
if ($core != "" and ($core | test("^https?://[^/[:space:]]+/?$" ) | not)) then
  error("core_url must be an http(s) or ws(s) origin, without a path")
elif ($core != "" and (($o.connect_as // "") | nonempty | not)) then
  error("connect_as is required for outbound mode")
elif ($core == "" and (($o.passkey // "") | nonempty | not) and (($o.core_public_keys // []) | length) == 0) then
  error("Inbound mode requires core_public_keys or a legacy passkey")
else
  {
    port: 8120, bind_ip: "[::]", root_directory: "/data/komodo",
    private_key: "file:/data/komodo/keys/periphery.key",
    core_addresses: (if $core == "" then [] else [($core | rtrimstr("/"))] end),
    connect_as: ($o.connect_as // ""),
    server_enabled: ($core == ""),
    ssl_enabled: (if $o | has("ssl_enabled") then $o.ssl_enabled else true end),
    ssl_key_file: "/data/komodo/ssl/key.pem",
    ssl_cert_file: "/data/komodo/ssl/cert.pem",
    stack_dir: ($o.stack_directory // "/share/komodo/stacks"),
    repo_dir: ($o.repo_directory // "/share/komodo/repos"),
    build_dir: ($o.build_directory // "/share/komodo/builds"),
    disable_terminals: ($o.disable_terminals // false),
    disable_container_terminals: ($o.disable_container_exec // false),
    stats_polling_rate: ($o.monitoring_interval // "30-sec"),
    container_stats_polling_rate: ($o.container_stats_interval // "1-min"),
    include_disk_mounts: ($o.include_disk_mounts // []),
    exclude_disk_mounts: ($o.exclude_disk_mounts // ["/dev", "/proc", "/sys"]),
    logging: {level: ($o.logging_level // "info"), stdio: "standard", pretty: false}
  }
  + (if ($o.onboarding_key // "" | nonempty) then {onboarding_key: $o.onboarding_key} else {} end)
  + (if (($o.core_public_keys // []) | length) > 0 then {core_public_keys: $o.core_public_keys} else {} end)
  + (if ($o.passkey // "" | nonempty) then {passkeys: [$o.passkey]} else {} end)
end
