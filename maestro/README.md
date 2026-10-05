# Maestro end-to-end tests

End-to-end flows for the payment sheet and the payment widgets, written for [Maestro](https://maestro.dev).
They drive the demo apps through the accessibility tree, the way a user would, and run the real SDK against
the Hyperswitch **sandbox**. The same YAML files cover the Android demo app (`io.hyperswitch.demoapp`) and
the iOS demo app (`io.hyperswitch`); CI runs them on an Android emulator.

## Layout

```
maestro/
  config.yaml   `maestro test maestro/` runs flows/* only
  flows/        one scenario per file: <area>_<scenario>.yaml
  subflows/     shared steps; the only files that know how the two demo apps differ
  scripts/      prepare-android-device.sh (emulator setup)
  server/       e2e-server.js (test backend), scenarios.js (payment-intent scenarios), loopback-only.js
```

### Subflows

All inputs are passed with `runFlow: {file, env}`. Nested subflows inherit the caller's env.

| Subflow | What it does | Inputs |
| --- | --- | --- |
| `open_payment_sheet.yaml` | set scenario, restart the app, wait until ready, open the sheet, wait for `Test Mode`, dismiss the debug toast | `SCENARIO`, `KEEP_SCENARIO`, `MOCK_PORT` |
| `launch_host_app.yaml` | the first half of the above: set scenario, close Chrome (Android), restart, point Android at the e2e server, wait for the ready signal | same + `READY: "false"` to skip the wait |
| `set_scenario.js` | `POST /scenario` on the e2e server (runs on the host) | `SCENARIO`, `MOCK_PORT` |
| `assert_scenario.js` | with `KEEP_SCENARIO: "true"`: fails unless the server still has the same scenario and customer | `MOCK_PORT` |
| `ensure_android_server_url.yaml` | rewrites the Android app's saved server URL to `http://10.0.2.2:<MOCK_PORT>` | `MOCK_PORT` |
| `tap_launch_payment_sheet.yaml` | taps the host's Launch button | |
| `fill_card.yaml` | types number, expiry and CVC one after another (each checked, retried once), then closes the keyboard; `""` skips a field | `CARD_NUMBER`, `EXPIRY`, `CVC`, `KEYBOARD_DISMISS` |
| `hide_keyboard.yaml` | taps `Test Mode` (Android: Back only while the keyboard is up and the header was pushed off-screen); `KEYBOARD_DISMISS: widget` presses Enter, then taps `Or pay using` (on the widget screen Back would close it) | `KEYBOARD_DISMISS` |
| `pay.yaml` | dismisses the debug toast, scrolls to and taps `PayButtonTestId` | |
| `wait_for_result.yaml` | waits for a final host result; `OUTCOMES: paid` ignores a leftover cancel | `OUTCOMES` |
| `expect_payment_succeeded.yaml` / `_failed` / `_cancelled` | asserts the host result | `STATUS` / `ERROR` |
| `expect_sheet_open.yaml` | no payment happened: sheet still open, host has no result | |
| `check_backend_payment.yaml` / `.js` | asserts the sandbox record of the scenario's latest intent | `EXPECT_STATUS`, `EXPECT_LAST4`, `EXPECT_NETWORK`, `EXPECT_AUTH`, `MOCK_PORT` |
| `open_android_widget.yaml` | Android: opens the demo's "Launch Widget" screen | `SCENARIO`, ... |
| `tap_host_button.yaml` | Android widget screen: scrolls to a native button by id, taps it, scrolls back | `BUTTON_ID` |
| `dismiss_dev_overlays.yaml` | removes React Native's LogBox toast (debug builds only) | |

Most payment flows end with `check_backend_payment.yaml`. It checks what the sandbox recorded (status, last 4
digits, network), not only what the host app displays, so "the right card was charged" is verified.

## Prerequisites

| Thing | Check / start |
| --- | --- |
| Maestro CLI 2.10.0 | `curl -fsSL https://get.maestro.mobile.dev \| bash`; `export PATH="$PATH:$HOME/.maestro/bin" MAESTRO_CLI_NO_ANALYTICS=1`; `maestro --version` |
| `.env` | copy `.en`. Needs sandbox `HYPERSWITCH_PUBLISHABLE_KEY`, `HYPERSWITCH_SECRET_KEY`, `PROFILE_ID`, **and** `HYPERSWITCH_SANDBOX_URL=https://sandbox.hyperswitch.io`, `SANDBOX_ASSETS_END_POINT=https://beta.hyperswitch.io`. Without the two URLs the debug bundle has no backend and every sheet fails with "Unable to load the payment configuration". |
| e2e server | `yarn e2e:server` → `curl localhost:5252/health`. Use it instead of `yarn server` (both use port 5252). Restart it after editing `.env` or `maestro/server/scenarios.js`. |
| Metro | `yarn start`; Android debug builds load the JS from it. Restart with `--reset-cache` after changing `.env`: values are inlined at bundle time. |
| Sentry | leave `SENTRY_DSN` empty in `.env` while running flows, so test crashes and logs are not sent to Sentry |
| Android | emulator running, demo app installed, then `maestro/scripts/prepare-android-device.sh <serial>` (turns off Chrome's first-run screens, which otherwise replace every redirect page on a fresh emulator) |

## Running

```bash
yarn e2e:server     # in its own terminal
yarn e2e:android    # every flow; HTML report in maestro-reports/
```

```bash
export PATH="$PATH:$HOME/.maestro/bin" MAESTRO_CLI_NO_ANALYTICS=1
# what CI runs on pull requests
maestro -p android test maestro/ --include-tags smoke
# one flow
maestro --device emulator-5554 test maestro/flows/card_success_no_3ds.yaml
# JUnit report
maestro --device emulator-5554 test maestro/ --format junit --output out/android/report.xml --test-output-dir out/android
```

The active scenario is global to one e2e server, so run flows **sequentially** against one server. To use
several Android emulators at once, give each device its own server and pass its port:

```bash
E2E_PORT=5253 yarn e2e:server
maestro --device emulator-5556 test -e MOCK_PORT=5253 maestro/
```

`MOCK_PORT` works on Android only. The iOS demo always calls `localhost:5252`, and `launch_host_app.yaml` fails
fast if a different port is passed on iOS.

Leave the device alone while flows run; a run where someone touched it is invalid and must be repeated. When
another emulator boots, adb can drop the devices briefly ("Device … is not connected"); rerun such runs too.

### Triage a failing flow

Look at the failure screenshot, `commands.json` and the `Tapping on element` lines in `maestro.log` first.

| Signature | Meaning | Action |
| --- | --- | --- |
| `Scenario … unavailable (502)` from `set_scenario.js`, or non-JSON errors from the sandbox | Sandbox trouble | Rerun later |
| `Device … is not connected` within seconds | adb dropped the device | Rerun |
| A tap landed on a neighbour (see `Tapping on element`), element not found after a layout change | Test problem | Fix the flow or subflow; never weaken the assertion |
| Deterministic wrong behaviour that the assertion describes correctly | Product bug | Keep the assertion and report the bug |

### Tags

| Tag | Meaning |
| --- | --- |
| `smoke` | the pull-request gate (CI runs these on every pull request) |
| `pr` | fast and deterministic |
| `android-only` | the behaviour or the Maestro command only exists on Android (system Back, the widget demo) |
| `card`, `saved`, `sheet`, `host`, `widget`, `validation`, `decline`, `3ds` | area |

## e2e server and scenarios

`maestro/server/e2e-server.js` is the test backend. It starts the repo's `mockServer.js` unchanged on an
internal port and stands in front of it:

| Request | Handled by |
| --- | --- |
| `POST /scenario {"name"}` | e2e server: activates a scenario; `400` bad body, `404` unknown, `412` + missing `.env` names, `502` if preparing saved cards failed |
| `GET /scenario`, `DELETE /scenario`, `GET /scenarios` | e2e server: show / clear / list with availability |
| `GET /scenario/last-payment` | e2e server: sandbox record of the latest intent created for the active scenario |
| `GET /create-payment-intent` | e2e server while a scenario with a `body` is active; otherwise `mockServer.js` |
| everything else | `mockServer.js`, forwarded as it is |

With no scenario selected the demo apps get exactly what `yarn server` gives them.

Both servers listen on `127.0.0.1` only, so nothing else on the network can reach them (their answers carry the
publishable key, and `mockServer.js` creates payments with the secret key). The Android emulator reaches the
host's loopback as `10.0.2.2`. `mockServer.js` listens on `0.0.0.0` by itself; `loopback-only.js`, preloaded
when the e2e server starts it, keeps it on `127.0.0.1` without changing the file.

`maestro/server/scenarios.js` defines the payment intent each flow gets (options at the top of the file).
`open_payment_sheet.yaml` sends `SCENARIO` to the server **before** `launchApp`, because the app creates its
intent on launch. Every flow sets its scenario.

| Scenario | Intent |
| --- | --- |
| `default` | no changes: `mockServer.js` creates the intent |
| `guest` | no customer |
| `saved_card` / `saved_card_multiple` | fresh customer with a saved Visa 4242 (+ Mastercard 4444, last used; 4242 set as default), saved server-side |
| `no_three_ds`, `three_ds` | fresh customer; authentication variants |

A fresh customer id is created when the scenario is set and kept until the next `POST /scenario`. A flow can pay,
relaunch with `KEEP_SCENARIO: "true"` and see what was saved; `assert_scenario.js` guards against a server restart
in between. After a run, the server keeps the last scenario: run `curl -X DELETE localhost:5252/scenario` (or
restart it) before using the demo apps by hand.

| Variable (`.env` or shell) | Use |
| --- | --- |
| `E2E_PORT`, `E2E_BACKEND_PORT` | the e2e server's port (default 5252) and `mockServer.js`'s internal port (default `E2E_PORT` + 10) |
| `HS_<NAME>_PROFILE_ID` (+ `HS_<NAME>_SECRET_KEY` / `HS_<NAME>_PUBLISHABLE_KEY` for another merchant) | a scenario with `account: '<NAME>'` |
| `PMM_CUSTOMER_ID` | a v2 customer id; payment method sessions are created for it (their v2 customers are separate from the v1 customers above) |

## Selectors

Use `testID` (`id:` in Maestro). React Native maps it to the Android `resource-id` and the iOS
`accessibilityIdentifier`. The two demo apps configure different copy ("Pay Now" vs "Purchase ($2.00)",
"Select a payment method" vs "Select payment method", "Saved payment method" vs "Payment methods"), so those
controls are only ever selected by id. SDK strings that are the same for both demos (tab labels, the `●●●●`
mask, validation messages) may be selected by text. Constants live in `src/utility/test/TestUtils.res`:

| testID | Element |
| --- | --- |
| `CardNumberInputTestId`, `ExpiryInputTestId`, `CVCInputTestId` | new-card form |
| `PayButtonTestId` | the sheet's Pay button |
| `SheetCloseButtonTestId` | header close (x) |
| `AddNewPaymentMethodTestId` / `UseSavedPaymentMethodsTestId` | the link that toggles saved and new-card views (the id follows the text shown) |
| `SaveCardCheckboxTestId` | "Save card details" |
| `SavedCardCvcInputTestId` | CVC on the selected saved card (also the express-checkout widget CVC) |
| `PaymentMethodTabBarTestId` | the payment-method tab bar (swipe anchor) |
| `CvcWidgetInputTestId` | the standalone CVC widget |
| `PayPalButtonTestId` | the PayPal wallet button |

Text selectors are full-match regexes. The saved-card mask is `●●●●` (U+25CF), not `••••`.

## CI

`.github/workflows/build_and_test_android.yml` bundles this branch's JS into the Android demo app and builds it,
starts the e2e server, and runs the flows on an API 35 emulator: the `smoke` flows on every pull request, every
flow on a manual run. CI does not use Metro: a debug build that cannot reach Metro loads the bundles packed in
the android repo, which can be older than the branch under test.
Pull requests from forks skip the job (they get no repository secrets).

Results: the run's **Summary** page shows a table of every flow (✅/❌, file, duration, failure reason),
failed flows first (`maestro/scripts/ci-report.js`, from Maestro's JUnit report). When a flow fails, the
screenshots of the failed flows are uploaded as the `maestro-failure-screenshots` artifact (bottom of the
Summary page, kept 7 days; the last screenshot in each folder is the moment it failed). Only screenshots are
uploaded: device and Maestro logs stay on the runner, because they can carry the sandbox publishable key and
payment session tokens, and anything uploaded from this public repository can be downloaded by anyone signed
in to GitHub. For logs, run the failed flow locally.

## Things that already cost time

- **Debug LogBox toast.** "Open debugger to view warnings." appears in debug builds. On Android its container
  reaches about 110 px above the visible toast and swallows taps there (e.g. "Add new payment method"). Run
  `dismiss_dev_overlays.yaml` before taps near the bottom; `open_payment_sheet.yaml` and `pay.yaml` already do.
- **Ready signal.** Tapping Launch before the intent exists does nothing. Android: `resultText` = `Last used:.*`.
  iOS: `Connected to Server`.
- **Leftover browser tabs.** A redirect page left open by a failed flow stays above the relaunched app;
  `launch_host_app.yaml` stops Chrome first.
- **Keyboard.** `fill_card.yaml` types all fields without closing the keyboard in between (closing it blurs
  the field and flashes its "cannot be empty" error) and closes it once at the end. Android `hideKeyboard` is
  a plain Back (`input keyevent 4`): it closes the sheet if no keyboard is up, so it is only used right after
  typing. On iOS, never `eraseText` before typing: the text then never lands.
- **Expiry input** takes digits (`0444` renders `04 / 44`). A month above 12 is rewritten (`13` → `01 / 3`) and
  focus jumps to CVC once the date is complete.
- **Stale results.** `resultText` keeps the previous result; flows that reopen the sheet wait with `OUTCOMES: paid`.
- **Maestro 2.10 quirks.** Flow-level `env:` overrides CLI `-e`. Quote every `${...}` that contains `? :`.
  `scrollUntilVisible` does not evaluate `${...}` inside its element selector (use `repeat`/`while`). JavaScript
  regexes in scripts have no inline `(?i)` (Maestro's own text matching does). `runScript` and `http.*` run on
  the host, so the e2e server is `localhost` there.
- **Swipes on the Android widget screen** must start on the host's native buttons; a screen-centre swipe starts on
  the embedded React Native element and does not scroll the page.
- **Debugging a failure:** `--test-output-dir <dir>` keeps `commands.json`, `maestro.log` (`Tapping on element`
  lines show what was hit), screenshots, hierarchy JSON and `logs/device-logcat.txt`. Maestro clears logcat at the
  start of each run, so read the crash or JS log from there.
- **Maestro analytics:** set `MAESTRO_CLI_NO_ANALYTICS=1`. Record videos with `maestro record --local` only.
- **Keep run output local.** `maestro-reports/` (gitignored) holds device logs with the sandbox publishable key
  and payment session tokens; do not attach it to issues or pull requests. Screenshots show only the app.
