import * as testIds from "../../src/utility/test/TestUtils.bs.js";
import { device, element, by, waitFor } from "detox"
import { visaSandboxCard, LAUNCH_PAYMENT_SHEET_BTN_TEXT } from "../fixtures/Constants"
import { waitForVisibility, typeTextInInput, takeScreenshot } from "../utils/DetoxHelpers"

describe('card-flow-e2e-test', () => {
  jest.retryTimes(6);
  beforeAll(async () => {
    await device.launchApp({
      launchArgs: { detoxEnableSynchronization: 1 },
      newInstance: true,
    });
    await device.enableSynchronization();

    // Take screenshot of initial app state
    await takeScreenshot('initial_app_state', 'app_launch');
  });

  it('demo app should load successfully', async () => {
    await waitForVisibility(element(by.text(LAUNCH_PAYMENT_SHEET_BTN_TEXT)))
    await takeScreenshot('demo_app_loaded', 'app_launch');
  });

  it('payment sheet should open', async () => {
    await element(by.text(LAUNCH_PAYMENT_SHEET_BTN_TEXT)).tap();
    await takeScreenshot('after_payment_button_tap', 'payment_sheet');

    try {
      await waitForVisibility(element(by.text('Test Mode')), 60000)
      await takeScreenshot('test_mode_visible', 'payment_sheet');
    } catch (error) {
      console.log('Test Mode not found, looking for card number input instead');
      await waitForVisibility(element(by.id(testIds.cardNumberInputTestId)), 30000);
      await takeScreenshot('card_form_loaded', 'payment_sheet');
    }
  })

  it('should enter details in card form', async () => {
    const cardNumberInput = await element(by.id(testIds.cardNumberInputTestId))
    const expiryInput = await element(by.id(testIds.expiryInputTestId))
    const cvcInput = await element(by.id(testIds.cvcInputTestId))

    // Take screenshot before entering card details
    await takeScreenshot('before_card_details', 'card_form');

    await waitFor(cardNumberInput).toExist();
    await waitForVisibility(cardNumberInput);
    await cardNumberInput.tap();
    await takeScreenshot('card_number_field_tapped', 'card_form');

    await cardNumberInput.clearText();
    await typeTextInInput(cardNumberInput, visaSandboxCard.cardNumber)
    await takeScreenshot('after_card_number_entry', 'card_form');

    await waitFor(expiryInput).toExist();
    await waitForVisibility(expiryInput);
    await expiryInput.typeText(visaSandboxCard.expiryDate);
    await takeScreenshot('after_expiry_entry', 'card_form');

    await waitFor(cvcInput).toExist();
    await waitForVisibility(cvcInput);
    await cvcInput.typeText(visaSandboxCard.cvc);
    await takeScreenshot('after_cvc_entry', 'card_form');

    // Add a small delay to ensure all inputs are processed
    await new Promise(resolve => setTimeout(resolve, 1000));
    await takeScreenshot('all_card_details_entered', 'card_form');
  });

  it('should be able to succesfully complete card payment', async () => {
    // Try to scroll down to make the button visible
    try {
      await element(by.id('card-form-scroll-view')).scrollTo('bottom');
      await takeScreenshot('after_scroll_to_bottom', 'payment_button');
    } catch (error) {
      console.log("Scroll failed, continuing anyway");
      await takeScreenshot('scroll_failed', 'payment_button');
    }

    // Try multiple ways to find the payment button
    let buttonFound = false;

    // First try the exact text
    try {
      const exactPayButton = element(by.text('Purchase ($2.00)'));
      await waitFor(exactPayButton).toBeVisible().withTimeout(10000);
      await takeScreenshot('exact_button_found', 'payment_button');
      await exactPayButton.tap();
      buttonFound = true;
      await takeScreenshot('after_exact_button_tap', 'payment_button');
    } catch (error) {
      console.log("Exact button text not found, trying by ID");
      await takeScreenshot('exact_button_not_found', 'payment_button');
    }

    // If that fails, try by ID
    if (!buttonFound) {
      try {
        const payNowButton = element(by.id(testIds.payButtonTestId));
        await waitFor(payNowButton).toExist().withTimeout(10000);
        await waitForVisibility(payNowButton);
        await takeScreenshot('id_button_found', 'payment_button');
        await payNowButton.tap();
        buttonFound = true;
        await takeScreenshot('after_id_button_tap', 'payment_button');
      } catch (error) {
        console.log("Button by ID not found, trying pattern match");
        await takeScreenshot('id_button_not_found', 'payment_button');
      }
    }

    // As a last resort, try pattern matching
    if (!buttonFound) {
      try {
        const payButtonTextMatcher = element(by.text(/Purchase|Pay|Continue/i));
        await waitFor(payButtonTextMatcher).toBeVisible().withTimeout(20000);
        await takeScreenshot('pattern_button_found', 'payment_button');
        await payButtonTextMatcher.tap();
        await takeScreenshot('after_pattern_button_tap', 'payment_button');
      } catch (error) {
        console.log("All button finding methods failed");
        await takeScreenshot('all_button_methods_failed', 'payment_button');
        throw error; // Re-throw to fail the test
      }
    }

    // Take screenshot during payment processing
    await takeScreenshot('payment_processing', 'payment_result');

    // Wait for payment success message
    if (device.getPlatform() === "ios") {
      try {
        await waitForVisibility(element(by.text('Payment complete')), 60000);
        await takeScreenshot('ios_payment_complete', 'payment_result');
      } catch (error) {
        await takeScreenshot('ios_payment_timeout', 'payment_result');
        throw error; // Re-throw to fail the test
      }
    } else {
      try {
        await waitForVisibility(element(by.text('succeeded')), 30000);
        await takeScreenshot('android_payment_succeeded', 'payment_result');
      } catch (error) {
        try {
          await waitForVisibility(element(by.text(/success|completed|approved/i)), 30000);
          await takeScreenshot('android_payment_generic_success', 'payment_result');
        } catch (innerError) {
          await takeScreenshot('android_payment_failure', 'payment_result');
          throw innerError; // Re-throw to fail the test
        }
      }
    }
  })
});