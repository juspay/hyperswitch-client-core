type envTypes = {
  "HYPERSWITCH_PRODUCTION_URL": string,
  "HYPERSWITCH_PRODUCTION_URL": string,
  "HYPERSWITCH_INTEG_URL": string,
  "HYPERSWITCH_SANDBOX_URL": string,
  "HYPERSWITCH_LOGS_PATH": string,
  "PROD_ASSETS_END_POINT": string,
  "SANDBOX_ASSETS_END_POINT": string,
  "INTEG_ASSETS_END_POINT": string,
}
type process = {env: envTypes}
@val external process: process = "process"
