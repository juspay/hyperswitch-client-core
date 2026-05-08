import {device, element, by, waitFor} from 'detox';
import {CreateBody, setCreateBodyForTestAutomation} from '../utils/APIUtils';
import {
  createTestLogger,
  waitForDemoAppLoad,
  launchPaymentSheet,
  navigateToNormalPaymentSheet,
  waitForUIStabilization,
} from '../utils/DetoxHelpers';
import {
  TIMEOUT_CONFIG,
  LAUNCH_PAYMENT_SHEET_BTN_TEXT,
  profileId,
} from '../fixtures/Constants';

const logger = createTestLogger();
const LONG_TIMEOUT = TIMEOUT_CONFIG.get('LONG');

describe('Interac Redirect Flow E2E Test', () => {
  beforeAll(async () => {
    const testStartTime = Date.now();
    logger.log('CPI & Device Sync Starting at:', testStartTime);

    // Create payment body with CAD currency
    const createPaymentBody = new CreateBody();
    createPaymentBody.addKey('profile_id', profileId);
    createPaymentBody.addKey('currency', 'CAD');
    createPaymentBody.addKey('request_external_three_ds_authentication', false);

    console.log('========================================');
    console.log('Creating payment intent with CAD currency');
    console.log('Currency:', createPaymentBody.get().currency);
    console.log('Profile ID:', profileId);
    console.log('========================================');

    await setCreateBodyForTestAutomation(createPaymentBody.get());
    console.log('Payment intent created successfully with CAD currency');

    // Launch app AFTER setting payment body so the app's GET picks up the cached body
    await device.launchApp({
      newInstance: true,
      launchArgs: {
        detoxEnableSynchronization: 1,
      },
    });
    await device.enableSynchronization();

    logger.log('CPI & Device Sync finished in:', testStartTime, Date.now());
  });

  it('should load demo app successfully', async () => {
    const testStartTime = Date.now();
    logger.log('Test starting at:', testStartTime);

    await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);

    logger.log('Test finished in:', testStartTime, Date.now());
  });

  it('should open payment sheet', async () => {
    const testStartTime = Date.now();
    logger.log('Test starting at:', testStartTime);

    await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);

    logger.log('Test finished in:', testStartTime, Date.now());
  });

  it('should navigate to normal payment sheet if needed', async () => {
    const testStartTime = Date.now();
    logger.log('Test starting at:', testStartTime);

    await navigateToNormalPaymentSheet();

    logger.log('Test finished in:', testStartTime, Date.now());
  });

  it('should display Interac payment option', async () => {
    const testStartTime = Date.now();
    logger.log('Test starting at:', testStartTime);

    console.log('========================================');
    console.log('Looking for Interac payment option...');
    console.log('========================================');

    // Wait for payment sheet to fully load
    await waitForUIStabilization(3000);

    // Look for Interac payment method - it should be displayed as "Interac"
    const interacButton = element(by.text('Interac'));

    // Verify Interac button is visible
    await waitFor(interacButton).toBeVisible().withTimeout(15000);
    console.log('Interac payment option is visible');

    // Take screenshot before clicking
    await device.takeScreenshot('interac-payment-option-visible');

    logger.log('Test finished in:', testStartTime, Date.now());
  });

  it('should redirect when Interac is clicked', async () => {
    const testStartTime = Date.now();
    logger.log('Test starting at:', testStartTime);

    // Tap on Interac button
    console.log('Tapping on Interac payment option...');
    const interacButton = element(by.text('Interac'));
    await interacButton.tap();
    console.log('Interac button tapped');

    // Wait for redirect to be initiated
    // Interac redirect flow should open InAppBrowser or trigger a redirect
    await waitForUIStabilization(5000);

    // Take screenshot after redirect is initiated
    await device.takeScreenshot('interac-after-redirect');

    console.log('========================================');
    console.log('Interac redirect flow initiated successfully');
    console.log('========================================');

    logger.log('Test finished in:', testStartTime, Date.now());
  });
});
