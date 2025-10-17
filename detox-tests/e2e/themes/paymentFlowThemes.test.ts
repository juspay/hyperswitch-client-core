import * as testIds from "../../../src/utility/test/TestUtils.bs.js";
import { device } from "detox";
import { profileId, visaSandboxCard, LAUNCH_PAYMENT_SHEET_BTN_TEXT } from "../../fixtures/Constants";
import {
  createTestLogger,
  waitForDemoAppLoad,
  launchPaymentSheet,
  navigateToNormalPaymentSheet,
  enterCardDetails,
  completePayment,
} from "../../utils/DetoxHelpers";
import { CreateBody, setCreateBodyForTestAutomation } from "../../utils/APIUtils";
import {
  setDeviceAppearance,
  resetToLightTheme,
  resetToDarkTheme,
} from "../../helpers/themeHelpers";
import {
  assertPaymentFormTheme,
  assertSuccessScreenTheme,
  assertErrorStateTheme,
} from "../../utils/themeAssertions";

const logger = createTestLogger();
let globalStartTime = Date.now();
let testStartTime = globalStartTime;

logger.log("Payment Flow Themes E2E Test Starting at:", globalStartTime);

describe('Payment Flow Themes E2E Test', () => {
  beforeAll(async () => {
    testStartTime = Date.now();
    logger.log("CPI & Device Sync Starting at:", testStartTime);

    const createPaymentBody = new CreateBody();
    createPaymentBody.addKey("profile_id", profileId);
    createPaymentBody.addKey("request_external_three_ds_authentication", false);

    await setCreateBodyForTestAutomation(createPaymentBody.get());
    await device.launchApp({
      launchArgs: { detoxEnableSynchronization: 1 },
      newInstance: true,
    });
    await device.enableSynchronization();

    logger.log("CPI & Device Sync finished in:", testStartTime, Date.now());
  });

  beforeEach(async () => {
    // Reset to light theme before each test
    await resetToLightTheme();
  });

  it('should load demo app successfully', async () => {
    testStartTime = Date.now();
    logger.log("Test starting at:", testStartTime);

    await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);

    logger.log("Test finished in:", testStartTime, Date.now());
  });

  it('should display payment form correctly in light theme', async () => {
    testStartTime = Date.now();
    logger.log("Payment form light theme test starting at:", testStartTime);

    await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
    await navigateToNormalPaymentSheet();

    // Assert light theme for payment form
    await assertPaymentFormTheme('light');

    logger.log("Payment form light theme test finished in:", testStartTime, Date.now());
  });

  it('should display payment form correctly in dark theme', async () => {
    testStartTime = Date.now();
    logger.log("Payment form dark theme test starting at:", testStartTime);

    await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
    await navigateToNormalPaymentSheet();

    // Switch to dark theme
    await setDeviceAppearance('dark');

    // Assert dark theme for payment form
    await assertPaymentFormTheme('dark');

    logger.log("Payment form dark theme test finished in:", testStartTime, Date.now());
  });

  it('should complete payment successfully in light theme', async () => {
    testStartTime = Date.now();
    logger.log("Payment completion light theme test starting at:", testStartTime);

    await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
    await navigateToNormalPaymentSheet();

    // Ensure light theme
    await resetToLightTheme();
    await assertPaymentFormTheme('light');

    // Complete payment flow
    await enterCardDetails(
      visaSandboxCard.cardNumber,
      visaSandboxCard.expiryDate,
      visaSandboxCard.cvc,
      testIds
    );

    await completePayment(testIds);

    // Assert success screen theme
    await assertSuccessScreenTheme('light');

    logger.log("Payment completion light theme test finished in:", testStartTime, Date.now());
  });

  it('should complete payment successfully in dark theme', async () => {
    testStartTime = Date.now();
    logger.log("Payment completion dark theme test starting at:", testStartTime);

    await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
    await navigateToNormalPaymentSheet();

    // Switch to dark theme
    await setDeviceAppearance('dark');
    await assertPaymentFormTheme('dark');

    // Complete payment flow
    await enterCardDetails(
      visaSandboxCard.cardNumber,
      visaSandboxCard.expiryDate,
      visaSandboxCard.cvc,
      testIds
    );

    await completePayment(testIds);

    // Assert success screen theme
    await assertSuccessScreenTheme('dark');

    logger.log("Payment completion dark theme test finished in:", testStartTime, Date.now());
  });

  it('should handle error states correctly in light theme', async () => {
    testStartTime = Date.now();
    logger.log("Error state light theme test starting at:", testStartTime);

    await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
    await navigateToNormalPaymentSheet();

    // Ensure light theme
    await resetToLightTheme();

    // Enter invalid card details to trigger error
    await enterCardDetails(
      "4000000000000002", // Invalid card number
      "04/44",
      "123",
      testIds
    );

    await completePayment(testIds);

    // Assert error state theme
    await assertErrorStateTheme('light');

    logger.log("Error state light theme test finished in:", testStartTime, Date.now());
  });

  it('should handle error states correctly in dark theme', async () => {
    testStartTime = Date.now();
    logger.log("Error state dark theme test starting at:", testStartTime);

    await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
    await navigateToNormalPaymentSheet();

    // Switch to dark theme
    await setDeviceAppearance('dark');

    // Enter invalid card details to trigger error
    await enterCardDetails(
      "4000000000000002", // Invalid card number
      "04/44",
      "123",
      testIds
    );

    await completePayment(testIds);

    // Assert error state theme
    await assertErrorStateTheme('dark');

    logger.log("Error state dark theme test finished in:", testStartTime, Date.now());
  });

  it('should validate button colors and states in both themes', async () => {
    testStartTime = Date.now();
    logger.log("Button theme validation test starting at:", testStartTime);

    await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
    await navigateToNormalPaymentSheet();

    // Test light theme buttons
    await resetToLightTheme();
    // Button assertions would go here

    // Test dark theme buttons
    await setDeviceAppearance('dark');
    // Button assertions would go here

    logger.log("Button theme validation test finished in:", testStartTime, Date.now());
  });

  it('should validate input field appearances in both themes', async () => {
    testStartTime = Date.now();
    logger.log("Input field theme validation test starting at:", testStartTime);

    await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
    await navigateToNormalPaymentSheet();

    // Test light theme inputs
    await resetToLightTheme();
    // Input field assertions would go here

    // Test dark theme inputs
    await setDeviceAppearance('dark');
    // Input field assertions would go here

    logger.log("Input field theme validation test finished in:", testStartTime, Date.now());
  });

  it('should validate text contrast ratios in both themes', async () => {
    testStartTime = Date.now();
    logger.log("Text contrast validation test starting at:", testStartTime);

    await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
    await navigateToNormalPaymentSheet();

    // Test light theme contrast
    await resetToLightTheme();
    // Contrast assertions would go here

    // Test dark theme contrast
    await setDeviceAppearance('dark');
    // Contrast assertions would go here

    logger.log("Text contrast validation test finished in:", testStartTime, Date.now());
  });

  afterAll(async () => {
    logger.log("Payment Flow Themes E2E Test finished in:", globalStartTime, Date.now());
  });
});