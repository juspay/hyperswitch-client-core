import { expect as jestExpect } from "@jest/globals";
import { by, device, element, waitFor } from "detox";
import { execFileSync } from "node:child_process";
import { TIMEOUT_CONFIG, visaSandboxCard } from "../fixtures/Constants";

/*
 * The Payment Methods SDK, driven as an app would drive it: the demo screen asks the mock
 * server (mockServer.js, port 5252) for a session, places the SDK's native field views, and
 * tokenizes. Every step below is a round trip over the hosted bridge: the form opening
 * (PM_FORM_READY), the typed card being reported without its number (PM_FORM_CHANGE) and a
 * command being answered (PM_COMMAND_RESULT).
 */

/* The vault's own input ids (CardTestIds.res); a Payment Methods field draws that input. */
const INPUT = {
  number: "CardNumberInputTestId",
  expiry: "ExpiryInputTestId",
  cvc: "CVCInputTestId",
};

/* The demo status line: an accessibility identifier on iOS, a view tag on Android. */
const STATUS_ID = "pm_status";

const LONG = TIMEOUT_CONFIG.get("LONG");

/* Android only: the emulator's settings, which Detox has no call for. */
const adb = (...args: string[]) =>
  execFileSync(
    process.env.ANDROID_HOME ? `${process.env.ANDROID_HOME}/platform-tools/adb` : "adb",
    ["-s", device.id, ...args],
    { encoding: "utf8" }
  );

const statusText = async (): Promise<string> => {
  const attributes = (await element(by.id(STATUS_ID)).getAttributes()) as { text?: string };
  return attributes.text ?? "";
};

/* Detox matches a text whole, so a status that starts a certain way is read and polled. */
const waitForStatus = async (pattern: RegExp, timeout: number): Promise<string> => {
  const until = Date.now() + timeout;
  let status = await statusText();
  while (!pattern.test(status) && Date.now() < until) {
    await new Promise((resolve) => setTimeout(resolve, 500));
    status = await statusText();
  }
  return status;
};

describe("Payment Methods SDK: native card form", () => {
  beforeAll(async () => {
    /* The demo's payments screen keeps a network round trip and timers going, which Detox's
       idle-wait would sit behind. Every step below waits for what it needs explicitly. */
    await device.launchApp({
      newInstance: true,
      /* iOS: the demo opens its "PM" tab from this argument (ContentView.swift). */
      launchArgs: { detoxEnableSynchronization: 0, hsDemoSegment: 6 },
    });
  });

  it("opens a card form on a session from the server", async () => {
    if (device.getPlatform() === "android") {
      const launch = element(by.text("Launch Payment Methods"));
      await waitFor(launch).toBeVisible().withTimeout(LONG);
      await launch.tap();
    }
    await waitFor(element(by.text("Form ready."))).toBeVisible().withTimeout(LONG);
    await waitFor(element(by.id(INPUT.number))).toBeVisible().withTimeout(LONG);
  });

  it("takes a card into the SDK's fields", async () => {
    const number = element(by.id(INPUT.number));
    await number.tap();
    await number.typeText(visaSandboxCard.cardNumber);
    await element(by.id(INPUT.expiry)).typeText(visaSandboxCard.expiryDate.replace("/", ""));
    await element(by.id(INPUT.cvc)).typeText(visaSandboxCard.cvc);
    /* The status line is the app's, not the SDK's: a card number must never reach it. */
    jestExpect(await statusText()).not.toContain(visaSandboxCard.cardNumber);
  });

  it("keeps nothing typed when Android recreates the screen from saved state", async () => {
    if (device.getPlatform() !== "android") return;
    /* A rotation destroys the screen and recreates it from its saved instance state, which is
       where Android would otherwise put every input's text. A card field takes no part in it,
       so the new screen opens a fresh session with empty fields. The rotation is driven through
       settings: Detox's own call leaves this emulator unrotated. */
    const instances = () =>
      new Set(
        adb("logcat", "-d", "-s", "LifecycleMonitor:D").match(
          /PaymentMethodsActivity@[0-9a-f]+ in: PRE_ON_CREATE/g
        ) ?? []
      ).size;
    /* A rotation can relaunch the screen more than once; wait until it has stopped. */
    const recreated = async (before: number): Promise<number> => {
      const until = Date.now() + 20000;
      let seen = instances();
      let stableSince = Date.now();
      while (Date.now() < until) {
        await new Promise((resolve) => setTimeout(resolve, 250));
        const now = instances();
        if (now !== seen) {
          seen = now;
          stableSince = Date.now();
        } else if (now > before && Date.now() - stableSince > 2000) {
          break;
        }
      }
      jestExpect(seen).toBeGreaterThan(before);
      return seen;
    };
    adb("logcat", "-c");
    adb("shell", "settings", "put", "system", "accelerometer_rotation", "0");
    try {
      adb("shell", "settings", "put", "system", "user_rotation", "1");
      const landscape = await recreated(0);
      await waitFor(element(by.text("Form ready."))).toBeVisible().withTimeout(LONG);
      await waitFor(element(by.id(INPUT.number))).toBeVisible().withTimeout(LONG);
      const restored = (await element(by.id(INPUT.number)).getAttributes()) as { text?: string };
      jestExpect(restored.text ?? "").toBe("");

      adb("shell", "settings", "put", "system", "user_rotation", "0");
      await recreated(landscape);
      await waitFor(element(by.text("Form ready."))).toBeVisible().withTimeout(LONG);
      await waitFor(element(by.id(INPUT.number))).toBeVisible().withTimeout(LONG);
      await new Promise((resolve) => setTimeout(resolve, 1000));
    } finally {
      adb("shell", "settings", "put", "system", "user_rotation", "0");
      adb("shell", "settings", "put", "system", "accelerometer_rotation", "1");
    }
    /* Typed again for the steps below. */
    const number = element(by.id(INPUT.number));
    await number.tap();
    await number.typeText(visaSandboxCard.cardNumber);
    await element(by.id(INPUT.expiry)).typeText(visaSandboxCard.expiryDate.replace("/", ""));
    await element(by.id(INPUT.cvc)).typeText(visaSandboxCard.cvc);
  });

  it("tokenizes from the app and gets an answer", async () => {
    /* Tokenize stays disabled until the SDK reported the form complete and valid, so the
       status changing at all proves that report arrived and the command was answered. */
    await element(by.text("Tokenize")).tap();
    const status = await waitForStatus(/^(Token: |Failed \()/, LONG);
    jestExpect(status).toMatch(/^(Token: |Failed \()/);
    jestExpect(status).not.toContain(visaSandboxCard.cardNumber);
    jestExpect(status).not.toContain(visaSandboxCard.cvc);
  });

  it("gets a token back from the sandbox vault", async () => {
    jestExpect(await statusText()).toMatch(/^Token: /);
  });
});
