import * as testIds from "../../src/utility/test/TestUtils.bs.js";
import { device, expect } from "detox";
import { profileId, visaSandboxCard, netceteraTestCard, LAUNCH_PAYMENT_SHEET_BTN_TEXT } from "../fixtures/Constants";
import { 
  createTestLogger, 
  waitForDemoAppLoad, 
  launchPaymentSheet, 
  navigateToNormalPaymentSheet, 
  enterCardDetails,
  typeTextInInput,
  waitForVisibility,
  waitForUIStabilization,
  isElementVisible
} from "../utils/DetoxHelpers";
import { CreateBody, setCreateBodyForTestAutomation } from "../utils/APIUtils";

const logger = createTestLogger();
let globalStartTime = Date.now();
let testStartTime = globalStartTime;

logger.log("Card Validation E2E Test Starting at:", globalStartTime);

// Test card data for validation scenarios
const INVALID_CARDS = {
  INVALID_NUMBER: { cardNumber: "1234567890123456", expiryDate: "04/44", cvc: "123" },
  INCOMPLETE_NUMBER: { cardNumber: "4242424242", expiryDate: "04/44", cvc: "123" },
  PAST_EXPIRY: { cardNumber: "4242424242424242", expiryDate: "01/20", cvc: "123" },
  INVALID_MONTH: { cardNumber: "4242424242424242", expiryDate: "13/25", cvc: "123" },
  INCOMPLETE_CVV: { cardNumber: "4242424242424242", expiryDate: "04/44", cvc: "12" },
};

describe('Card Validation E2E Test', () => {
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
    await device.launchApp({
      launchArgs: { detoxEnableSynchronization: 1 },
      newInstance: true,
    });
  });

  describe('Card Number Validation', () => {
    it('should show error for invalid card number format', async () => {
      testStartTime = Date.now();
      logger.log("Test starting at:", testStartTime);

      await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await navigateToNormalPaymentSheet();

      const cardNumberInput = element(by.id(testIds.cardNumberInputTestId));
      await cardNumberInput.tap();
      await cardNumberInput.clearText();
      await typeTextInInput(cardNumberInput, INVALID_CARDS.INVALID_NUMBER.cardNumber);

      const expiryInput = element(by.id(testIds.expiryInputTestId));
      await expiryInput.tap();

      await waitForUIStabilization();
      
      // Validate that error message appears for invalid card number
      // Using exact text from UI screenshot: "Card number is invalid." (note capital C)
      const errorMessage = element(by.text('Card number is invalid.'));
      await expect(errorMessage).toBeVisible();

      logger.log("Test finished in:", testStartTime, Date.now());
    });

    it('should accept valid Visa card number', async () => {
      testStartTime = Date.now();
      logger.log("Test starting at:", testStartTime);

      await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await navigateToNormalPaymentSheet();

      await enterCardDetails(
        visaSandboxCard.cardNumber,
        visaSandboxCard.expiryDate,
        visaSandboxCard.cvc,
        testIds
      );

      const payButton = element(by.id(testIds.payButtonTestId));
      await waitForVisibility(payButton);

      logger.log("Test finished in:", testStartTime, Date.now());
    });

    it('should accept valid Mastercard number', async () => {
      testStartTime = Date.now();
      logger.log("Test starting at:", testStartTime);

      await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await navigateToNormalPaymentSheet();

      await enterCardDetails(
        netceteraTestCard.cardNumber,
        netceteraTestCard.expiryDate,
        netceteraTestCard.cvc,
        testIds
      );

      const payButton = element(by.id(testIds.payButtonTestId));
      await waitForVisibility(payButton);

      logger.log("Test finished in:", testStartTime, Date.now());
    });
  });

  describe('Expiry Date Validation', () => {
    it('should handle past expiry date', async () => {
      testStartTime = Date.now();
      logger.log("Test starting at:", testStartTime);

      await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await navigateToNormalPaymentSheet();

      const cardNumberInput = element(by.id(testIds.cardNumberInputTestId));
      await cardNumberInput.tap();
      await cardNumberInput.clearText();
      await typeTextInInput(cardNumberInput, INVALID_CARDS.PAST_EXPIRY.cardNumber);

      const expiryInput = element(by.id(testIds.expiryInputTestId));
      await expiryInput.tap();
      await typeTextInInput(expiryInput, INVALID_CARDS.PAST_EXPIRY.expiryDate);

      const cvcInput = element(by.id(testIds.cvcInputTestId));
      await cvcInput.tap();
      await typeTextInInput(cvcInput, INVALID_CARDS.PAST_EXPIRY.cvc);

      await waitForUIStabilization();

      const errorMessage = element(by.text('Your card\'s expiration date is invalid.'));
      await expect(errorMessage).toBeVisible();

      logger.log("Test finished in:", testStartTime, Date.now());
    });

    it('should accept valid future expiry date', async () => {
      testStartTime = Date.now();
      logger.log("Test starting at:", testStartTime);

      await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await navigateToNormalPaymentSheet();

      await enterCardDetails(
        visaSandboxCard.cardNumber,
        visaSandboxCard.expiryDate,
        visaSandboxCard.cvc,
        testIds
      );

      const payButton = element(by.id(testIds.payButtonTestId));
      await waitForVisibility(payButton);

      logger.log("Test finished in:", testStartTime, Date.now());
    });
  });

  describe('CVV Validation', () => {
    it('should handle incomplete CVV', async () => {
      testStartTime = Date.now();
      logger.log("Test starting at:", testStartTime);

      await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await navigateToNormalPaymentSheet();

      const cardNumberInput = element(by.id(testIds.cardNumberInputTestId));
      await cardNumberInput.tap();
      await cardNumberInput.clearText();
      await typeTextInInput(cardNumberInput, INVALID_CARDS.INCOMPLETE_CVV.cardNumber);

      const expiryInput = element(by.id(testIds.expiryInputTestId));
      await expiryInput.tap();
      await typeTextInInput(expiryInput, INVALID_CARDS.INCOMPLETE_CVV.expiryDate);

      const cvcInput = element(by.id(testIds.cvcInputTestId));
      await cvcInput.tap();
      await typeTextInInput(cvcInput, INVALID_CARDS.INCOMPLETE_CVV.cvc);

      await waitForUIStabilization();
      
      // Click Purchase button to trigger validation
      const payButton = element(by.id(testIds.payButtonTestId));
      await payButton.tap();
      
      await waitForUIStabilization();
      
      // Validate that error message appears for incomplete CVV
      const errorMessage = element(by.text('Your card\'s security code is invalid.'));
      await expect(errorMessage).toBeVisible();

      logger.log("Test finished in:", testStartTime, Date.now());
    });


    it('should accept valid CVV for Visa', async () => {
      testStartTime = Date.now();
      logger.log("Test starting at:", testStartTime);

      await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await navigateToNormalPaymentSheet();

      await enterCardDetails(
        visaSandboxCard.cardNumber,
        visaSandboxCard.expiryDate,
        visaSandboxCard.cvc,
        testIds
      );

      const payButton = element(by.id(testIds.payButtonTestId));
      await waitForVisibility(payButton);

      logger.log("Test finished in:", testStartTime, Date.now());
    });
  });

 describe('Empty field validation', () => {
    it('empty field validation', async () => {
      testStartTime = Date.now();
      logger.log("Test starting at:", testStartTime);

      await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await navigateToNormalPaymentSheet();

      await waitForUIStabilization();
      
      // Click Purchase button to trigger validation
      const payButton = element(by.id(testIds.payButtonTestId));
      await payButton.tap();
      
      await waitForUIStabilization();
      
      // Validate that error message appears for incomplete CVV
      const errorMessage = element(by.text('Card Number cannot be empty'));
      await expect(errorMessage).toBeVisible();

      logger.log("Test finished in:", testStartTime, Date.now());
    });

    it('empty expiry date validation',async()=>{
      testStartTime= Date.now();
      logger.log("Test starting at:",testStartTime);

      await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await navigateToNormalPaymentSheet();

      await waitForUIStabilization();

      const cardNumberInput =element(by.id(testIds.cardNumberInputTestId));
      await cardNumberInput.tap();
      await typeTextInInput(cardNumberInput,visaSandboxCard.cardNumber);

      const payButton=element(by.id(testIds.payButtonTestId));
      await payButton.tap();

      await waitForUIStabilization();

     const errorMessage = element(by.text('Card expiry date cannot be empty'));
     await expect(errorMessage).toBeVisible();

     logger.log("Test finished in:", testStartTime,Date.now());

    })

    it('empty evv validation',async()=>{
      testStartTime=Date.now();
      logger.log("Test starting at:",testStartTime);

      await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await navigateToNormalPaymentSheet();

      await waitForUIStabilization();

      const cardNumberInput=element(by.id(testIds.cardNumberInputTestId));
      await cardNumberInput.tap();
      await typeTextInInput(cardNumberInput,visaSandboxCard.cardNumber);

      const expiryInput=element(by.id(testIds.expiryInputTestId));
      await expiryInput.tap();
      await typeTextInInput(expiryInput,visaSandboxCard.expiryDate);

      const payButton =element(by.id(testIds.payButtonTestId));
      await payButton.tap();

      await waitForUIStabilization();

      const errorMessage= element(by.text('CVC Number cannot be empty'));

      await expect(errorMessage).toBeVisible();

      logger.log("Test finished in:", testStartTime, Date.now());

    })
  });



  describe('Field Interaction', () => {
    it('should handle clearing and re-entering data', async () => {
      testStartTime = Date.now();
      logger.log("Test starting at:", testStartTime);

      await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await navigateToNormalPaymentSheet();

      const cardNumberInput = element(by.id(testIds.cardNumberInputTestId));
      await cardNumberInput.tap();
      await typeTextInInput(cardNumberInput, INVALID_CARDS.INVALID_NUMBER.cardNumber);

      await waitForUIStabilization();

      await cardNumberInput.clearText();
      await typeTextInInput(cardNumberInput, visaSandboxCard.cardNumber);

      const expiryInput = element(by.id(testIds.expiryInputTestId));
      await expiryInput.tap();
      await typeTextInInput(expiryInput, visaSandboxCard.expiryDate);

      const cvcInput = element(by.id(testIds.cvcInputTestId));
      await cvcInput.tap();
      await typeTextInInput(cvcInput, visaSandboxCard.cvc);

      const payButton = element(by.id(testIds.payButtonTestId));
      await waitForVisibility(payButton);

      logger.log("Test finished in:", testStartTime, Date.now());
    });
  });
});

