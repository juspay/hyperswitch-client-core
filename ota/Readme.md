# OTA Configuration Guide

Explanation of Configuration Keys

- `enable_ota_updates` → Enables or disables OTA updates. When `false`, only Release Config (RC) is updated. `(Optional)` `(default - true)`

- `target_platform` → Specifies the platform for the update (`android` or `ios`).

- `target_version` → Defines the `platform version`.

- `release_tag_version` → Specifies the `Git tag version` used for the build and deployment process.


- `enable_rollback` → If `true`, allows rolling back to the previous version in case of failure.`(Optional)` `(default - false)`

- `release_config_timeout_ms` → Timeout (in `milliseconds`) for retrieving the release configuration. `(Optional)` `(default - from Config.json)`

- `package_timeout_ms` → Timeout (in `milliseconds`) for downloading and applying the application package update. `(Optional)` `(default - from Config.json)`

- `release_env` → Specify the release environment  [`sandbox` , `prod`] `(Optional)` `(default - sandbox)`

- `test` → Enables or disables Test updates for local mobile testing.