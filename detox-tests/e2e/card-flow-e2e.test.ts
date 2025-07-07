import * as testIds from "../../src/utility/test/TestUtils.bs.js";
import { device } from "detox"
import { visaSandboxCard, LAUNCH_PAYMENT_SHEET_BTN_TEXT } from "../fixtures/Constants"
import {
  waitForVisibility,
  waitForUIStabilization,
  ensureNormalPaymentSheet,
  enterCardDetails,
  completePayment
} from "../utils/DetoxHelpers"
import { CreateBody, setCreateBodyForTestAutomation } from "../utils/APIUtils";

describe('card-flow-e2e-test', () => {
  jest.retryTimes(6);
  beforeAll(async () => {
    const createPaymentBody = new CreateBody();
    createPaymentBody.addKey("request_external_three_ds_authentication", false)
    await setCreateBodyForTestAutomation(createPaymentBody.get());
    await device.launchApp({
      launchArgs: { detoxEnableSynchronization: 1 },
      newInstance: true,
    });
    await device.enableSynchronization();
  });

  it('demo app should load successfully', async () => {
    console.log("Waiting for demo app to load...");
    await waitForUIStabilization(2000);
    await waitForVisibility(element(by.text(LAUNCH_PAYMENT_SHEET_BTN_TEXT)), 20000);
  });

  it('payment sheet should open', async () => {
    console.log("Opening payment sheet...");
    await element(by.text(LAUNCH_PAYMENT_SHEET_BTN_TEXT)).tap();
    console.log("Waiting for payment sheet to load...");
    await waitForUIStabilization(3000);
    await waitForVisibility(element(by.text('Test Mode')), 40000);
    await waitForUIStabilization(3000);
  });
  it('should detect payment sheet type and navigate to normal payment sheet if needed', async () => {
    console.log("Starting payment sheet detection and navigation...");
    const initialSheetType = await ensureNormalPaymentSheet();
    console.log(`Initial payment sheet type detected: ${initialSheetType}`);
    await waitForUIStabilization(2000);
    console.log("Payment sheet detection and navigation completed successfully");
  });

  it('should enter details in card form', async () => {
    console.log("Starting card details entry...");
    await enterCardDetails(
      visaSandboxCard.cardNumber,
      visaSandboxCard.expiryDate,
      visaSandboxCard.cvc,
      testIds
    );
    console.log("Card details entry completed successfully");
  });

  it('should be able to successfully complete card payment', async () => {
    console.log("Starting payment completion...");
    await completePayment(testIds);
    console.log("Payment completion test finished successfully");
  });
});
