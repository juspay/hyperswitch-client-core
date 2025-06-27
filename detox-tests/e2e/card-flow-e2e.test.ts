import * as testIds from "../../src/utility/test/TestUtils.bs.js";
import { device } from "detox"
import { visaSandboxCard, LAUNCH_PAYMENT_SHEET_BTN_TEXT } from "../fixtures/Constants"
import {
  waitForVisibility,
  waitForUIStabilization,
  ensureNormalPaymentSheet,
  enterCardDetails,
  completePayment,
  takeScreenshot
} from "../utils/DetoxHelpers"

describe('card-flow-e2e-test', () => {
  jest.retryTimes(6);
  beforeAll(async () => {
    await device.launchApp({
      launchArgs: { detoxEnableSynchronization: 1 },
      newInstance: true,
    });
    await device.enableSynchronization();
  });

  it('demo app should load successfully', async () => {
    console.log("Waiting for demo app to load...");
    await waitForUIStabilization(2000);
    await takeScreenshot('01-demo-app-loaded');
    await waitForVisibility(element(by.text(LAUNCH_PAYMENT_SHEET_BTN_TEXT)), 20000);
    await takeScreenshot('02-launch-button-visible');
  });

  it('payment sheet should open', async () => {
    console.log("Opening payment sheet...");
    await element(by.text(LAUNCH_PAYMENT_SHEET_BTN_TEXT)).tap();
    console.log("Waiting for payment sheet to load...");
    await waitForUIStabilization(3000);
    await takeScreenshot('03-payment-sheet-opening');
    await waitForVisibility(element(by.text('Test Mode')), 40000);
    await waitForUIStabilization(3000);
    await takeScreenshot('04-payment-sheet-loaded');
  });
  
  it('should detect payment sheet type and navigate to normal payment sheet if needed', async () => {
    console.log("Starting payment sheet detection and navigation...");
    await takeScreenshot('05-before-sheet-detection');
    const initialSheetType = await ensureNormalPaymentSheet();
    console.log(`Initial payment sheet type detected: ${initialSheetType}`);
    await waitForUIStabilization(2000);
    await takeScreenshot('06-after-sheet-navigation');
    console.log("Payment sheet detection and navigation completed successfully");
  });

  it('should enter details in card form', async () => {
    console.log("Starting card details entry...");
    await takeScreenshot('07-before-card-entry');
    await enterCardDetails(
      visaSandboxCard.cardNumber,
      visaSandboxCard.expiryDate,
      visaSandboxCard.cvc,
      testIds
    );
    await takeScreenshot('08-after-card-entry');
    console.log("Card details entry completed successfully");
  });

  it('should be able to successfully complete card payment', async () => {
    console.log("Starting payment completion...");
    await takeScreenshot('09-before-payment-completion');
    await completePayment(testIds);
    await takeScreenshot('10-after-payment-completion');
    console.log("Payment completion test finished successfully");
  });
});
