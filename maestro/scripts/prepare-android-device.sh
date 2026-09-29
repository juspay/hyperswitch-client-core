#!/usr/bin/env bash
# Prepares an Android emulator for the Maestro suite.
#   usage: maestro/scripts/prepare-android-device.sh <adb-serial> [path/to/demo-app.apk]
# - Installs the demo app if an APK is given.
# - Turns off Chrome's first-run screens. Redirect payment methods and 3DS challenges open in a Chrome
#   Custom Tab; on a fresh emulator Chrome shows its welcome flow there instead of the provider page.
set -euo pipefail
serial=${1:?usage: prepare-android-device.sh <adb-serial> [demo-app.apk]}
apk=${2:-}

adb -s "$serial" wait-for-device
until [ "$(adb -s "$serial" shell getprop sys.boot_completed | tr -d '\r')" = "1" ]; do sleep 2; done

if [ -n "$apk" ]; then
  adb -s "$serial" install -r "$apk"
fi

adb -s "$serial" shell 'echo "chrome --disable-fre --no-default-browser-check --no-first-run" > /data/local/tmp/chrome-command-line'
adb -s "$serial" shell am set-debug-app --persistent com.android.chrome
adb -s "$serial" shell am force-stop com.android.chrome

adb -s "$serial" shell pm list packages | grep -q '^package:io.hyperswitch.demoapp$' \
  || { echo "io.hyperswitch.demoapp is not installed on $serial" >&2; exit 1; }
echo "$serial ready"
