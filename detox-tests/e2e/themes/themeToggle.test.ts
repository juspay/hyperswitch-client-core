import * as testIds from '../../../src/utility/test/TestUtils.bs.js';
import {device} from 'detox';
import {
  profileId,
  LAUNCH_PAYMENT_SHEET_BTN_TEXT,
} from '../../fixtures/Constants';
import {
  createTestLogger,
  waitForDemoAppLoad,
  launchPaymentSheet,
} from '../../utils/DetoxHelpers';
import {CreateBody, setCreateBodyForTestAutomation} from '../../utils/APIUtils';
import {
  setDeviceAppearance,
  toggleDeviceAppearance,
  resetToLightTheme,
  resetToDarkTheme,
} from '../../helpers/themeHelpers';
import {
  assertCompleteThemeConsistency,
  assertPaymentFormTheme,
} from '../../utils/themeAssertions';

const logger = createTestLogger();
let globalStartTime = Date.now();
let testStartTime = globalStartTime;

logger.log('Theme Toggle E2E Test Starting at:', globalStartTime);

describe('Theme Toggle E2E Test', () => {
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
    // Reset to light theme before each test
    await resetToLightTheme();
  });

  it('should load demo app successfully', async () => {
    testStartTime = Date.now();
    logger.log('Test starting at:', testStartTime);

    await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);

    logger.log('Test finished in:', testStartTime, Date.now());
  });

  it('should switch from light to dark theme', async () => {
    testStartTime = Date.now();
    logger.log('Light to Dark theme test starting at:', testStartTime);

    await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);

    // Initially should be light theme
    await assertCompleteThemeConsistency('light');

    // Switch to dark theme
    await setDeviceAppearance('dark');

    // Assert dark theme is applied
    await assertCompleteThemeConsistency('dark');

    logger.log(
      'Light to Dark theme test finished in:',
      testStartTime,
      Date.now(),
    );
  });

  it('should switch from dark to light theme', async () => {
    testStartTime = Date.now();
    logger.log('Dark to Light theme test starting at:', testStartTime);

    await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);

    // Switch to dark theme first
    await setDeviceAppearance('dark');
    await assertCompleteThemeConsistency('dark');

    // Switch back to light theme
    await setDeviceAppearance('light');

    // Assert light theme is applied
    await assertCompleteThemeConsistency('light');

    logger.log(
      'Dark to Light theme test finished in:',
      testStartTime,
      Date.now(),
    );
  });

  it('should maintain theme consistency during payment flow in light mode', async () => {
    testStartTime = Date.now();
    logger.log('Payment flow light theme test starting at:', testStartTime);

    await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);

    // Ensure light theme
    await resetToLightTheme();
    await assertPaymentFormTheme('light');

    // Navigate through payment flow
    // Add navigation steps here if needed

    logger.log(
      'Payment flow light theme test finished in:',
      testStartTime,
      Date.now(),
    );
  });

  it('should maintain theme consistency during payment flow in dark mode', async () => {
    testStartTime = Date.now();
    logger.log('Payment flow dark theme test starting at:', testStartTime);

    await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);

    // Switch to dark theme
    await setDeviceAppearance('dark');
    await assertPaymentFormTheme('dark');

    // Navigate through payment flow
    // Add navigation steps here if needed

    logger.log(
      'Payment flow dark theme test finished in:',
      testStartTime,
      Date.now(),
    );
  });

  it('should persist theme across app restarts', async () => {
    testStartTime = Date.now();
    logger.log('Theme persistence test starting at:', testStartTime);

    await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);

    // Set dark theme
    await setDeviceAppearance('dark');
    await assertCompleteThemeConsistency('dark');

    // Close and relaunch app
    await device.terminateApp();
    await device.launchApp({
      launchArgs: {detoxEnableSynchronization: 1},
      newInstance: false, // Don't create new instance to test persistence
    });

    await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
    await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);

    // Theme should persist (follows system theme)
    await assertCompleteThemeConsistency('dark');

    logger.log(
      'Theme persistence test finished in:',
      testStartTime,
      Date.now(),
    );
  });

  // Note: System theme following test would require changing system settings
  // which is complex in Detox. This would need to be tested manually or with
  // additional setup.

  afterAll(async () => {
    logger.log(
      'Theme Toggle E2E Test finished in:',
      globalStartTime,
      Date.now(),
    );
  });
});
