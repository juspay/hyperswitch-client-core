import * as testIds from '../../src/utility/test/TestUtils.bs.js';
import {device, element, by, waitFor} from 'detox';
import {
  createPaymentBody,
  setCreateBodyForTestAutomation,
} from '../utils/APIUtils';
import {visaSandboxCard} from '../fixtures/Constants';
import {
  typeTextInInput,
  waitForDemoAppLoad,
  launchPaymentSheet,
  navigateToNormalPaymentSheet,
  waitForUIStabilization,
  dismissKeyboard,
  completePayment,
} from '../utils/DetoxHelpers';
import {
  TIMEOUT_CONFIG,
  LAUNCH_PAYMENT_SHEET_BTN_TEXT,
  SAVED_PAYMENT_SHEET_INDICATORS,
  profileId,
} from '../fixtures/Constants';

describe('Saved Card Flow Test', () => {
  it('should save card and use it for second payment with same customer ID', async () => {
    // ==========================================
    // STEP 1: Generate customer ID (used for BOTH payments)
    // ==========================================
    const customerId = `save_card_test_${Date.now()}_${Math.random()
      .toString(36)
      .substring(2, 9)}`;

    console.log('========================================');
    console.log('CUSTOMER ID (for both payments):', customerId);
    console.log('========================================');

    // ==========================================
    // FIRST PAYMENT: Save the card
    // ==========================================
    console.log('\n=== FIRST PAYMENT: Save Card ===');

    // Build first payment body WITH setup_future_usage to save card
    // IMPORTANT: Must call setCreateBodyForTestAutomation BEFORE launching the app,
    // because the app makes a GET /create-payment-intent on startup which needs
    // the cached body to use the correct customer_id.
    const firstPaymentBody = {
      ...createPaymentBody,
      customer_id: customerId,
      profile_id: profileId,
      setup_future_usage: 'on_session',
    };

    console.log(
      'First Payment Body customer_id:',
      firstPaymentBody.customer_id,
    );
    await setCreateBodyForTestAutomation(firstPaymentBody);
    console.log('First payment intent created with customer ID:', customerId);

    // Launch app AFTER setting payment body so the app's GET picks up the cached body
    await device.launchApp({
      newInstance: true,
      launchArgs: {
        detoxEnableSynchronization: 1,
      },
    });

    // Navigate to payment sheet
    await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
    await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
    await navigateToNormalPaymentSheet();

    // Wait for the payment sheet to fully load with customer data
    console.log('Waiting for payment sheet to load...');
    await waitForUIStabilization(5000);

    // Enter card details
    console.log('Entering card details...');

    // Card number
    console.log('Entering card number...');
    const cardNumberInput = element(by.id(testIds.cardNumberInputTestId));
    await waitFor(cardNumberInput).toBeVisible().withTimeout(10000);
    await cardNumberInput.tap();
    await cardNumberInput.replaceText(visaSandboxCard.cardNumber);
    console.log('Card number entered');
    await waitForUIStabilization(1500);

    // Expiry date
    console.log('Entering expiry date...');
    const expiryInput = element(by.id(testIds.expiryInputTestId));
    await waitFor(expiryInput).toBeVisible().withTimeout(10000);
    await expiryInput.tap();
    await expiryInput.replaceText(visaSandboxCard.expiryDate);
    console.log('Expiry date entered');
    await waitForUIStabilization(1000);

    // CVC
    console.log('Entering CVC...');
    const cvcInput = element(by.id(testIds.cvcInputTestId));
    await waitFor(cvcInput).toBeVisible().withTimeout(10000);
    await cvcInput.tap();
    await cvcInput.replaceText(visaSandboxCard.cvc);
    console.log('CVC entered');
    await waitForUIStabilization(2000);

    // // Dismiss keyboard first to see the full UI
    // await element(by.text('Test Mode')).tap();
    // await waitForUIStabilization(1000);
    // AFTER (Fixed):
    // await device.pressBack(); // ✅ Keeps app instance, preserves savedCustomerId
    // await waitForUIStabilization(2000);

    // Check "Save card details" checkbox exists and tap it
    console.log('========================================');
    console.log('Checking save card checkbox...');
    console.log('SaveCardCheckboxTestId:', testIds.saveCardCheckboxTestId);
    console.log('========================================');

    let saveCardCheckboxFound = false;
    let saveCardCheckbox;

    try {
      saveCardCheckbox = element(by.id(testIds.saveCardCheckboxTestId));
      await waitFor(saveCardCheckbox).toBeVisible().withTimeout(10000);
      saveCardCheckboxFound = true;
      console.log('✓ Save card checkbox is VISIBLE');

      // Take a screenshot before tapping
      await device.takeScreenshot('before-checkbox-tap');

      // Tap the checkbox
      await saveCardCheckbox.tap();
      console.log('✓ Tapped on save card checkbox');

      // Wait and take screenshot after
      await waitForUIStabilization(2000);
      await device.takeScreenshot('after-checkbox-tap');
      console.log('✓ Screenshot taken after checkbox tap');
    } catch (e) {
      console.log(
        '⚠ Save card checkbox NOT found - may be hidden (guest user)',
      );
      console.log('   The checkbox only shows for non-guest customers');
      console.log('   Continuing without saving card...');
    }

    // Make successful payment
    console.log('========================================');
    console.log('Completing first payment...');

    // Dismiss keyboard and tap pay
    await dismissKeyboard();
    const payButton = element(by.id(testIds.payButtonTestId));
    await waitFor(payButton).toBeVisible().withTimeout(10000);
    await payButton.tap();
    console.log('✓ Pay button tapped');

    // Wait for payment completion - payment sheet closes on success
    console.log('Waiting for payment sheet to close...');
    try {
      // Check if returned to main screen (payment sheet closed)
      await waitFor(element(by.text(LAUNCH_PAYMENT_SHEET_BTN_TEXT)))
        .toBeVisible()
        .withTimeout(20000);
      console.log('✓ First payment completed (returned to main screen)!');
    } catch (e) {
      console.log('⚠ Payment sheet did not close as expected');
      await device.takeScreenshot('payment-unclear');
    }

    // ==========================================
    // SECOND PAYMENT: Use saved card
    // ==========================================
    console.log('\n=== SECOND PAYMENT: Use Saved Card ===');
    console.log('Using SAME customer ID:', customerId);

    // Build second payment body with SAME customer_id
    // IMPORTANT: Explicitly set setup_future_usage to 'on_session' because
    // mockData.paymentIntentBody has setup_future_usage: 'off_session' by default,
    // and the mock server merges mockData with req.body. Without overriding it,
    // the second payment would inherit 'off_session' from mockData.
    const secondPaymentBody = {
      ...createPaymentBody,
      customer_id: customerId,
      profile_id: profileId,
      setup_future_usage: 'on_session',
    };

    console.log(
      'Second Payment Body customer_id:',
      secondPaymentBody.customer_id,
    );
    console.log(
      'Customer IDs match:',
      firstPaymentBody.customer_id === secondPaymentBody.customer_id
        ? '✅ YES'
        : '❌ NO',
    );

    // IMPORTANT: Set payment body BEFORE launching app (same pattern as first payment)
    await setCreateBodyForTestAutomation(secondPaymentBody);
    console.log('Second payment intent created with customer ID:', customerId);

    // Relaunch app to fetch new payment intent with same customer
    console.log('Relaunching app to load second payment intent...');
    await device.launchApp({
      newInstance: true,
      launchArgs: {
        detoxEnableSynchronization: 1,
      },
    });

    // Wait for app to fully load
    await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
    await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);

    // Wait for payment sheet to fully render
    await waitForUIStabilization(3000);

    // Verify we are on the SAVED CARD sheet (not the normal payment sheet)
    // The saved card sheet shows "Add new payment method" text
    console.log('Checking for saved card payment sheet...');
    const addNewPmText = element(
      by.text(SAVED_PAYMENT_SHEET_INDICATORS.ADD_NEW_PAYMENT_METHOD_TEXT),
    );
    await waitFor(addNewPmText).toBeVisible().withTimeout(15000);
    console.log(
      '✓ Saved card payment sheet detected (found "Add new payment method")',
    );

    // The first saved card should be auto-selected, and the CVC input should be visible
    // (since requires_cvv is true for saved cards)
    console.log('Looking for saved card CVC input...');
    const savedCardCvcInput = element(by.id(testIds.savedCardCvcInputTestId));
    await waitFor(savedCardCvcInput).toBeVisible().withTimeout(10000);
    console.log('✓ Saved card CVC input is visible');

    // Enter CVC for the saved card
    console.log('Entering CVC for saved card payment...');
    await savedCardCvcInput.tap();
    await typeTextInInput(savedCardCvcInput, visaSandboxCard.cvc);
    await waitForUIStabilization(1000);
    console.log('✓ CVC entered for saved card');

    // For on_session flows, payment_type is NORMAL so the terms checkbox
    // is NOT shown (it only appears for NEW_MANDATE/SETUP_MANDATE flows).
    // Skip straight to completing payment.
    console.log(
      'Terms checkbox not required for on_session flow (payment_type=NORMAL)',
    );

    // Complete payment using the existing helper (handles dismiss keyboard + tap pay + wait for result)
    console.log('Completing payment with saved card...');
    await completePayment(testIds);
    console.log('✓ Saved card payment completed successfully!');

    console.log('========================================');
    console.log('✅ Saved Card Flow Test completed!');
    console.log('Customer ID used for both payments:', customerId);
    console.log('========================================');
  }, 300000);
});
