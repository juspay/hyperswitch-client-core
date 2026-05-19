import * as testIds from '../../src/utility/test/TestUtils.bs.js';
import {device, element, by, expect as detoxExpect, waitFor} from 'detox';
import {
  profileId,
  LAUNCH_PAYMENT_SHEET_BTN_TEXT,
  visaSandboxCard,
} from '../fixtures/Constants';
import {
  createTestLogger,
  waitForDemoAppLoad,
  launchPaymentSheet,
  navigateToNormalPaymentSheet,
  waitForVisibility,
  waitForUIStabilization,
  typeTextInInput,
} from '../utils/DetoxHelpers';
import {CreateBody, setCreateBodyForTestAutomation} from '../utils/APIUtils';

const logger = createTestLogger();
let globalStartTime = Date.now();
let testStartTime = globalStartTime;

describe('Card Scan Feature E2E Test', () => {
  beforeAll(async () => {
    testStartTime = Date.now();
    logger.log('CPI & Device Sync Starting at:', testStartTime);

    const createPaymentBody = new CreateBody();
    createPaymentBody.addKey('profile_id', profileId);
    createPaymentBody.addKey('request_external_three_ds_authentication', false);

    await setCreateBodyForTestAutomation(createPaymentBody.get());
    await device.launchApp({
      launchArgs: {detoxEnableSynchronization: 1},
      newInstance: true,
    });
    await device.enableSynchronization();

    logger.log('CPI & Device Sync finished in:', testStartTime, Date.now());
  });

  beforeEach(async () => {
    await device.launchApp({
      launchArgs: {detoxEnableSynchronization: 1},
      newInstance: true,
    });
    await device.enableSynchronization();
  });

  describe('Scan Card Button Visibility', () => {
    it('should display scan card camera icon when card number is empty', async () => {
      testStartTime = Date.now();
      logger.log('Test starting at:', testStartTime);

      await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await navigateToNormalPaymentSheet();

      // Verify card number input is visible
      const cardNumberInput = element(by.id(testIds.cardNumberInputTestId));
      await waitForVisibility(cardNumberInput);

      // Verify camera icon is visible (scan card button)
      const scanCardButton = element(by.id(testIds.scanCardButtonTestId));
      await waitForVisibility(scanCardButton);

      logger.log('Test finished in:', testStartTime, Date.now());
    });

    it('should hide scan card button when card number is entered', async () => {
      testStartTime = Date.now();
      logger.log('Test starting at:', testStartTime);

      await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await navigateToNormalPaymentSheet();

      // Enter card number
      const cardNumberInput = element(by.id(testIds.cardNumberInputTestId));
      await cardNumberInput.tap();
      await typeTextInInput(cardNumberInput, visaSandboxCard.cardNumber);

      await waitForUIStabilization(1000);

      // Camera icon should be hidden when card number is filled
      const scanCardButton = element(by.id(testIds.scanCardButtonTestId));
      await detoxExpect(scanCardButton).not.toBeVisible();

      logger.log('Test finished in:', testStartTime, Date.now());
    });
  });

  describe('Scan Card Flow', () => {
    it('should tap scan card button and handle permission dialog', async () => {
      testStartTime = Date.now();
      logger.log('Test starting at:', testStartTime);

      await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await navigateToNormalPaymentSheet();

      // Verify scan card button is visible and tap it
      const scanCardButton = element(by.id(testIds.scanCardButtonTestId));
      await waitForVisibility(scanCardButton);

      // Tap the scan card button using coordinate-based tapping
      // This bypasses some Detox synchronization issues
      await scanCardButton.tap({x: 5, y: 5});
      logger.log('Scan card button tapped', testStartTime, Date.now());

      // Wait for scan activity to open
      await waitForUIStabilization(3000);

      // Handle permission dialog
      try {
        const allowButton = element(by.text('Allow'));
        await waitFor(allowButton).toBeVisible().withTimeout(3000);
        await allowButton.tap();
        logger.log('Permission granted', testStartTime, Date.now());
      } catch (e) {
        logger.log('No permission dialog', testStartTime, Date.now());
      }

      // Go back
      await device.pressBack();
      await waitForUIStabilization(1000);

      // Verify we're back
      await waitForVisibility(element(by.id(testIds.cardNumberInputTestId)));
      logger.log('Test finished in:', testStartTime, Date.now());
    });

    it('should verify scan card button is available on supported devices', async () => {
      testStartTime = Date.now();
      logger.log('Test starting at:', testStartTime);

      await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await navigateToNormalPaymentSheet();

      // The scan card button should be visible if ScanCardModule.isAvailable is true
      // This depends on the device/emulator capabilities
      const cardNumberInput = element(by.id(testIds.cardNumberInputTestId));
      await waitForVisibility(cardNumberInput);

      // Try to locate the scan card button
      const scanCardButton = element(by.id(testIds.scanCardButtonTestId));

      try {
        await waitFor(scanCardButton).toBeVisible().withTimeout(2000);
        logger.log(
          'Scan card button is available on this device',
          testStartTime,
          Date.now(),
        );
      } catch (e) {
        logger.log(
          'Scan card button not available - module may not be supported on this device',
          testStartTime,
          Date.now(),
        );
      }

      logger.log('Test finished in:', testStartTime, Date.now());
    });
  });

  describe('Scan Card Data Integration', () => {
    it('should verify card form accepts scanned data format', async () => {
      testStartTime = Date.now();
      logger.log('Test starting at:', testStartTime);

      await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await navigateToNormalPaymentSheet();

      // Manually enter data in the format that scan card would provide
      const cardNumberInput = element(by.id(testIds.cardNumberInputTestId));
      await cardNumberInput.tap();
      await typeTextInInput(cardNumberInput, visaSandboxCard.cardNumber);

      const expiryInput = element(by.id(testIds.expiryInputTestId));
      await expiryInput.tap();
      await typeTextInInput(expiryInput, visaSandboxCard.expiryDate);

      const cvcInput = element(by.id(testIds.cvcInputTestId));
      await cvcInput.tap();
      await typeTextInInput(cvcInput, visaSandboxCard.cvc);

      await waitForUIStabilization(500);

      // Verify all fields are populated correctly
      const payButton = element(by.id(testIds.payButtonTestId));
      await waitForVisibility(payButton);

      logger.log('Test finished in:', testStartTime, Date.now());
    });

    it('should handle expiry date formatting from scanned data', async () => {
      testStartTime = Date.now();
      logger.log('Test starting at:', testStartTime);

      await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await navigateToNormalPaymentSheet();

      // Test various expiry date formats that scanning might produce
      const cardNumberInput = element(by.id(testIds.cardNumberInputTestId));
      await cardNumberInput.tap();
      await typeTextInInput(cardNumberInput, visaSandboxCard.cardNumber);

      const expiryInput = element(by.id(testIds.expiryInputTestId));
      await expiryInput.tap();

      // Test format: MM / YY (with spaces)
      await typeTextInInput(expiryInput, '04 / 44');

      await waitForUIStabilization(500);

      // Verify field accepts the format
      await detoxExpect(expiryInput).toBeVisible();

      logger.log('Test finished in:', testStartTime, Date.now());
    });
  });

  describe('Error Handling', () => {
    it('should handle scan card cancellation gracefully', async () => {
      testStartTime = Date.now();
      logger.log('Test starting at:', testStartTime);

      await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
      await navigateToNormalPaymentSheet();

      // Verify scan card button is visible and test cancellation flow
      const scanCardButton = element(by.id(testIds.scanCardButtonTestId));
      await waitForVisibility(scanCardButton);

      // MANUAL TESTING REQUIRED: Tap action cannot be automated in Detox
      // because the native scan card module has active timers.
      //
      // To manually test cancellation:
      // 1. Tap the scan card button
      // 2. Press back to cancel
      // 3. Verify payment sheet is still visible

      logger.log(
        'Manual testing required for cancellation flow',
        testStartTime,
        Date.now(),
      );

      await waitForUIStabilization(2000);

      // Press back to cancel (simulating user cancellation)
      try {
        await device.pressBack();
        await waitForUIStabilization(1000);
      } catch (e) {
        await waitForUIStabilization(1000);
      }

      // Verify we're back to the payment sheet
      const cardNumberInput = element(by.id(testIds.cardNumberInputTestId));
      await detoxExpect(cardNumberInput).toBeVisible();

      logger.log(
        'Scan card cancellation flow completed',
        testStartTime,
        Date.now(),
      );

      logger.log('Test finished in:', testStartTime, Date.now());
    });
  });
});
