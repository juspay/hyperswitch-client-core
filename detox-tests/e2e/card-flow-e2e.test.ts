import * as testIds from "../../src/utility/test/TestUtils.bs.js";
import { device } from "detox";
import { profileId, visaSandboxCard, LAUNCH_PAYMENT_SHEET_BTN_TEXT } from "../fixtures/Constants";
import { 
  createTestLogger, 
  waitForDemoAppLoad, 
  launchPaymentSheet, 
  navigateToNormalPaymentSheet, 
  enterCardDetails, 
  completePayment
} from "../utils/DetoxHelpers";
import { CreateBody, setCreateBodyForTestAutomation } from "../utils/APIUtils";

const logger = createTestLogger();
let globalStartTime = Date.now();
let testStartTime = globalStartTime;

logger.log("Card Flow E2E Test Starting at:", globalStartTime);

describe('Card Flow E2E Test', () => {
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

  it('should load demo app successfully', async () => {
    testStartTime = Date.now();
    logger.log("Test starting at:", testStartTime);
    
    await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
    
    logger.log("Test finished in:", testStartTime, Date.now());
  });

  it('should open payment sheet', async () => {
    testStartTime = Date.now();
    logger.log("Test starting at:", testStartTime);

    await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);

    logger.log("Test finished in:", testStartTime, Date.now());
  });

  it('should navigate to normal payment sheet if needed', async () => {
    testStartTime = Date.now();
    logger.log("Test starting at:", testStartTime);

    await navigateToNormalPaymentSheet();

    logger.log("Test finished in:", testStartTime, Date.now());
  });

  it('should enter card details in form', async () => {
    testStartTime = Date.now();
    logger.log("Test starting at:", testStartTime);

    await enterCardDetails(
      visaSandboxCard.cardNumber,
      visaSandboxCard.expiryDate,
      visaSandboxCard.cvc,
      testIds
    );
    
    logger.log("Test finished in:", testStartTime, Date.now());
  });

  it('should complete card payment successfully', async () => {
    testStartTime = Date.now();
    logger.log("Test starting at:", testStartTime);

    await completePayment(testIds);
    
    logger.log("Test finished in:", testStartTime, Date.now());
    logger.log("Card Flow E2E Test finished in:", globalStartTime, Date.now());
  });
});
