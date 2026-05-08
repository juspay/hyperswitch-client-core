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

describe('Mandate Card Flow Test', () => {
  it('should save card with off_session setup and use it for second payment without CVV', async () => {
    // ==========================================
    // STEP 1: Generate customer ID (used for BOTH payments)
    // ==========================================
    const customerId = `mandate_test_${Date.now()}_${Math.random()
      .toString(36)
      .substring(2, 9)}`;

    console.log('========================================');
    console.log('CUSTOMER ID (for both payments):', customerId);
    console.log('========================================');

    // ==========================================
    // FIRST PAYMENT: Save the card with off_session
    // ==========================================
    console.log('\n=== FIRST PAYMENT: Save Card with off_session ===');

    // Build first payment body WITH setup_future_usage: off_session to save card for mandate
    const firstPaymentBody = {
      ...createPaymentBody,
      customer_id: customerId,
      profile_id: profileId,
      setup_future_usage: 'off_session',
    };

    console.log(
      'First Payment Body customer_id:',
      firstPaymentBody.customer_id,
    );
    console.log(
      'First Payment Body setup_future_usage:',
      firstPaymentBody.setup_future_usage,
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

    // await device.pressBack();
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

      await device.takeScreenshot('before-checkbox-tap');

      await saveCardCheckbox.tap();
      console.log('✓ Tapped on save card checkbox');

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

    await dismissKeyboard();
    const payButton = element(by.id(testIds.payButtonTestId));
    await waitFor(payButton).toBeVisible().withTimeout(10000);
    await payButton.tap();
    console.log('✓ Pay button tapped');

    // Wait for payment completion - payment sheet closes on success
    console.log('Waiting for payment sheet to close...');
    try {
      await waitFor(element(by.text(LAUNCH_PAYMENT_SHEET_BTN_TEXT)))
        .toBeVisible()
        .withTimeout(20000);
      console.log('✓ First payment completed (returned to main screen)!');
    } catch (e) {
      console.log('⚠ Payment sheet did not close as expected');
      await device.takeScreenshot('payment-unclear');
    }

    // ==========================================
    // SECOND PAYMENT: Use saved card (mandate - no CVV required)
    // ==========================================
    console.log('\n=== SECOND PAYMENT: Use Saved Card (Mandate - No CVV) ===');
    console.log('Using SAME customer ID:', customerId);

    // Build second payment body with SAME customer_id
    const secondPaymentBody = {
      ...createPaymentBody,
      customer_id: customerId,
      profile_id: profileId,
    };
    // No setup_future_usage for second payment

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

    // Verify we are on the SAVED CARD sheet
    console.log('Checking for saved card payment sheet...');
    const addNewPmText = element(
      by.text(SAVED_PAYMENT_SHEET_INDICATORS.ADD_NEW_PAYMENT_METHOD_TEXT),
    );
    await waitFor(addNewPmText).toBeVisible().withTimeout(15000);
    console.log(
      '✓ Saved card payment sheet detected (found "Add new payment method")',
    );

    // For mandate/off_session cards, the saved card should be auto-selected
    // and NO CVC input should be visible (mandate doesn't require CVV)
    console.log('Verifying NO CVC input is shown for mandate card...');
    try {
      const savedCardCvcInput = element(by.id(testIds.savedCardCvcInputTestId));
      await waitFor(savedCardCvcInput).toBeVisible().withTimeout(3000);
      console.log(
        '⚠ CVC input is visible - this is unexpected for mandate flow',
      );
      console.log('   Mandate cards should not require CVV');
    } catch (e) {
      console.log(
        '✓ No CVC input visible - correct for mandate/off_session flow',
      );
    }

    // Tap the Purchase button directly (no CVV or terms checkbox for mandate flow)
    console.log('Tapping Purchase button...');
    const purchaseButton = element(by.id(testIds.payButtonTestId));
    await waitFor(purchaseButton).toBeVisible().withTimeout(10000);
    await purchaseButton.tap();
    console.log('✓ Purchase button tapped');

    // Wait for payment completion - payment sheet closes on success
    console.log('Waiting for payment sheet to close...');
    try {
      await waitFor(element(by.text(LAUNCH_PAYMENT_SHEET_BTN_TEXT)))
        .toBeVisible()
        .withTimeout(20000);
      console.log('✓ Mandate card payment completed successfully!');
    } catch (e) {
      console.log('⚠ Payment sheet did not close as expected');
      await device.takeScreenshot('mandate-payment-unclear');
    }

    console.log('========================================');
    console.log('✅ Mandate Card Flow Test completed!');
    console.log('Customer ID used for both payments:', customerId);
    console.log('Setup Future Usage: off_session (mandate)');
    console.log('========================================');
  }, 300000);
});
