import * as testIds from '../../src/utility/test/TestUtils.bs.js';
import {device, element, by, waitFor} from 'detox';
import {
  profileId,
  visaSandboxCard,
  LAUNCH_PAYMENT_SHEET_BTN_TEXT,
} from '../fixtures/Constants';
import {
  createTestLogger,
  waitForDemoAppLoad,
  launchPaymentSheet,
  navigateToNormalPaymentSheet,
  enterCardDetails,
  completePayment,
  waitForVisibility,
  isElementVisible,
  typeTextInInput,
  dismissKeyboard,
  waitForUIStabilization,
} from '../utils/DetoxHelpers';
import {
  CreateBody2,
  setCreateBodyForTestAutomation,
  fetchPaymentMethods,
} from '../utils/APIUtils';

const logger = createTestLogger();
const {expect: jestExpect} = require('@jest/globals');
let globalStartTime = Date.now();
let testStartTime = globalStartTime;
let clientSecret: string;
let requiredFieldsFromAPI: string[] = [];

logger.log('Superposition Billing Fields Test Starting at:', globalStartTime);

describe('Superposition Billing Fields Rendering Test', () => {
  beforeAll(async () => {
    testStartTime = Date.now();
    logger.log('CPI & Device Sync Starting at:', testStartTime);

    const createPaymentBody = new CreateBody2();
    createPaymentBody.addKey('profile_id', profileId);
    createPaymentBody.addKey('request_external_three_ds_authentication', false);

    // Explicitly remove billing and shipping to test superposition
    createPaymentBody.removeBilling().removeShipping();

    const requestBody = createPaymentBody.get();
    console.log(
      'Create Intent Request Body:',
      JSON.stringify(requestBody, null, 2),
    );
    console.log(
      'Billing address present in request:',
      requestBody.hasOwnProperty('billing'),
    );
    console.log(
      'Shipping address present in request:',
      requestBody.hasOwnProperty('shipping'),
    );

    if (requestBody.hasOwnProperty('billing')) {
      console.warn('WARNING: Billing address is still present in the request!');
    }
    if (requestBody.hasOwnProperty('shipping')) {
      console.warn(
        'WARNING: Shipping address is still present in the request!',
      );
    }

    clientSecret = await setCreateBodyForTestAutomation(
      createPaymentBody.get(),
    );
    console.log('Client secret obtained:', clientSecret);

    await device.launchApp({
      launchArgs: {detoxEnableSynchronization: 1},
      newInstance: true,
    });
    await device.enableSynchronization();

    logger.log('CPI & Device Sync finished in:', testStartTime, Date.now());
  });

  it('should load demo app successfully', async () => {
    testStartTime = Date.now();
    logger.log('Test starting at:', testStartTime);

    await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);

    logger.log('Test finished in:', testStartTime, Date.now());
  });

  it('should open payment sheet', async () => {
    testStartTime = Date.now();
    logger.log('Test starting at:', testStartTime);

    await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);

    logger.log('Test finished in:', testStartTime, Date.now());
  });

  it('should navigate to normal payment sheet if needed', async () => {
    testStartTime = Date.now();
    logger.log('Test starting at:', testStartTime);

    await navigateToNormalPaymentSheet();

    logger.log('Test finished in:', testStartTime, Date.now());
  });

  it('should fetch and validate required fields from payment methods API', async () => {
    testStartTime = Date.now();
    logger.log('Test starting at:', testStartTime);

    // Fetch payment methods data which contains required fields
    const paymentMethodsData = await fetchPaymentMethods(clientSecret);
    console.log('Payment methods data fetched successfully');

    // Extract required fields from payment methods list
    requiredFieldsFromAPI = [];

    if (
      paymentMethodsData.payment_methods &&
      Array.isArray(paymentMethodsData.payment_methods)
    ) {
      paymentMethodsData.payment_methods.forEach((pm: any) => {
        if (
          pm.payment_method === 'card' &&
          pm.payment_method_types &&
          Array.isArray(pm.payment_method_types)
        ) {
          pm.payment_method_types.forEach((pmt: any) => {
            if (pmt.required_fields) {
              Object.keys(pmt.required_fields).forEach((fieldKey: string) => {
                const field = pmt.required_fields[fieldKey];
                if (field && field.required_field) {
                  requiredFieldsFromAPI.push(field.required_field);
                }
              });
            }
          });
        }
      });
    }

    console.log('Required fields from API:', requiredFieldsFromAPI);
    jestExpect(requiredFieldsFromAPI.length).toBeGreaterThan(0);

    logger.log('Test finished in:', testStartTime, Date.now());
  });

  it('should render all required billing address fields and validate against API', async () => {
    testStartTime = Date.now();
    logger.log('Test starting at:', testStartTime);

    // Scroll down to reveal billing fields below the card form
    await element(by.id(testIds.paymentSheetScrollViewTestId)).swipe(
      'up',
      'slow',
      0.5,
    );
    await waitForUIStabilization(500);

    // Define expected billing field paths
    // Note: first_name and last_name are combined into one "Card Holder Name" field
    // rendered by FullNameElement. The testID is set to first_name's outputPath.
    // There is NO separate last_name element in the UI.
    const billingFieldPaths = [
      'payment_method_data.billing.address.line1',
      'payment_method_data.billing.address.city',
      'payment_method_data.billing.address.state',
      'payment_method_data.billing.address.zip',
      'payment_method_data.billing.address.country',
      'payment_method_data.billing.address.first_name',
    ];

    // Check which required fields are actually rendered
    const renderedFields: string[] = [];

    for (const fieldPath of billingFieldPaths) {
      // Try scrolling to make the field visible
      try {
        await waitFor(element(by.id(fieldPath)))
          .toBeVisible()
          .whileElement(by.id(testIds.paymentSheetScrollViewTestId))
          .scroll(100, 'down');
      } catch (e) {
        // Field may already be visible or may not exist
      }

      const fieldElement = element(by.id(fieldPath));
      const isVisible = await isElementVisible(fieldElement);

      if (isVisible) {
        renderedFields.push(fieldPath);
        console.log(`✓ Billing field rendered: ${fieldPath}`);
      } else {
        console.log(`✗ Billing field NOT rendered: ${fieldPath}`);
      }
    }

    // Compare required fields from API with rendered fields
    const apiFieldNames = requiredFieldsFromAPI.map((field: string) => {
      const parts = field.split('.');
      return parts[parts.length - 1];
    });

    const renderedFieldNames = renderedFields.map((field: string) => {
      const parts = field.split('.');
      return parts[parts.length - 1];
    });

    console.log('API field names:', apiFieldNames);
    console.log('Rendered field names:', renderedFieldNames);

    // Verify all required billing fields are rendered
    // last_name is excluded because it shares a combined input with first_name
    const requiredBillingFields = apiFieldNames.filter((name: string) =>
      ['line1', 'city', 'state', 'zip', 'country', 'first_name'].includes(name),
    );

    const missingRequiredFields: string[] = [];
    for (const requiredField of requiredBillingFields) {
      if (!renderedFieldNames.includes(requiredField)) {
        console.error(`✗ Required field not rendered: ${requiredField}`);
        missingRequiredFields.push(requiredField);
      } else {
        console.log(`✓ Required field rendered: ${requiredField}`);
      }
    }

    // Assert that all required billing fields are rendered
    jestExpect(missingRequiredFields).toEqual([]);

    logger.log('Test finished in:', testStartTime, Date.now());
  });

  it('should show validation errors when clicking pay now without entering fields', async () => {
    testStartTime = Date.now();
    logger.log('Test starting at:', testStartTime);

    // Dismiss keyboard if present
    await dismissKeyboard();
    await waitForUIStabilization(1000);

    // Scroll down to make pay button visible
    try {
      await waitFor(element(by.id(testIds.payButtonTestId)))
        .toBeVisible()
        .whileElement(by.id(testIds.paymentSheetScrollViewTestId))
        .scroll(100, 'down');
    } catch (e) {
      // Button may already be visible
    }

    // Click pay now button without entering any details
    const payNowButton = element(by.id(testIds.payButtonTestId));
    await payNowButton.tap();

    await waitForUIStabilization(2000);

    // Scroll back up to see validation errors near the top of the form
    await element(by.id(testIds.paymentSheetScrollViewTestId)).swipe(
      'down',
      'slow',
      0.8,
    );
    await waitForUIStabilization(500);

    // Check for validation error messages by their text content.
    // ErrorText component renders text without a testID, so we must match by text.
    // Billing address "Required" fields show "This field is mandatory".
    // Card Holder Name shows "Card Holder's name required".
    // Card fields show their own errors too (e.g. "Card number is invalid.").
    const expectedErrorTexts = [
      "Card Holder's name required",
      'This field is mandatory',
    ];

    let validationErrorsFound = 0;

    for (const errText of expectedErrorTexts) {
      // Try scrolling to find the error text
      try {
        await waitFor(element(by.text(errText)).atIndex(0))
          .toBeVisible()
          .whileElement(by.id(testIds.paymentSheetScrollViewTestId))
          .scroll(100, 'down');
        console.log(`✓ Validation error text shown: "${errText}"`);
        validationErrorsFound++;
      } catch (e) {
        // Also try checking if already visible without scrolling
        try {
          await waitFor(element(by.text(errText)).atIndex(0))
            .toBeVisible()
            .withTimeout(2000);
          console.log(
            `✓ Validation error text shown (no scroll): "${errText}"`,
          );
          validationErrorsFound++;
        } catch (e2) {
          console.log(`⚠ Validation error text NOT shown: "${errText}"`);
        }
      }
    }

    console.log(`Total validation errors found: ${validationErrorsFound}`);
    jestExpect(validationErrorsFound).toBeGreaterThan(0);

    logger.log('Test finished in:', testStartTime, Date.now());
  });

  it('should enter card details and verify validation errors disappear', async () => {
    testStartTime = Date.now();
    logger.log('Test starting at:', testStartTime);

    // Scroll back up to card fields at the top of the form
    await element(by.id(testIds.paymentSheetScrollViewTestId)).swipe(
      'down',
      'fast',
      0.8,
    );
    await waitForUIStabilization(500);

    // Enter card details
    await enterCardDetails(
      visaSandboxCard.cardNumber,
      visaSandboxCard.expiryDate,
      visaSandboxCard.cvc,
      testIds,
    );

    await waitForUIStabilization(1000);

    // Dismiss keyboard and check pay button is enabled or errors are cleared
    await dismissKeyboard();
    await waitForUIStabilization(1000);

    console.log('Card details entered successfully');

    logger.log('Test finished in:', testStartTime, Date.now());
  });

  it('should enter billing fields one by one and verify errors disappear', async () => {
    testStartTime = Date.now();
    logger.log('Test starting at:', testStartTime);

    // Note: FullNameElement combines first_name + last_name into a single
    // "Card Holder Name" input. The testID is set to the first_name outputPath.
    const billingFields = [
      {
        path: 'payment_method_data.billing.address.first_name',
        value: 'John Doe',
      },
      {
        path: 'payment_method_data.billing.address.line1',
        value: '1467 Harrison Street',
      },
      {
        path: 'payment_method_data.billing.address.city',
        value: 'San Francisco',
      },
      {path: 'payment_method_data.billing.address.zip', value: '94122'},
    ];

    for (const field of billingFields) {
      // Scroll to make the field visible
      try {
        await waitFor(element(by.id(field.path)))
          .toBeVisible()
          .whileElement(by.id(testIds.paymentSheetScrollViewTestId))
          .scroll(100, 'down');
      } catch (e) {
        // Field may already be visible
      }

      // Enter field value
      const fieldInput = element(by.id(field.path));
      await fieldInput.tap();
      await fieldInput.clearText();
      await typeTextInInput(fieldInput, field.value);
      console.log(`Entered value for ${field.path}: ${field.value}`);

      await waitForUIStabilization(500);
      await dismissKeyboard();
      await waitForUIStabilization(300);
    }

    // IMPORTANT: Select country BEFORE state, because the state dropdown
    // depends on the selected country to populate its options.

    // Scroll to country selector
    try {
      await waitFor(
        element(by.id('payment_method_data.billing.address.country')),
      )
        .toBeVisible()
        .whileElement(by.id(testIds.paymentSheetScrollViewTestId))
        .scroll(100, 'down');
    } catch (e) {
      // May already be visible
    }

    // Select country - tapping opens a fullscreen picker modal with search
    const countrySelect = element(
      by.id('payment_method_data.billing.address.country'),
    );
    if (await isElementVisible(countrySelect)) {
      await countrySelect.tap();
      await waitForUIStabilization(1500);

      // The modal has a search CustomInput with testID="picker_search_<name>".
      // We MUST use typeText (not replaceText) because replaceText sets native text
      // without firing React's onChangeText, so the filter state never updates.
      const countrySearchId =
        'picker_search_payment_method_data.billing.address.country';
      let countrySelected = false;
      try {
        const searchInput = element(by.id(countrySearchId));
        await searchInput.tap();
        await waitForUIStabilization(500);
        // typeText types lowercase on Android, but the search filter is case-insensitive
        await searchInput.typeText('United States');
        await waitForUIStabilization(1000);

        // Tap the FlatList item by its testID (picker_item_<country_code>).
        // Tapping by.text() on the TextWrapper child doesn't propagate to
        // the CustomPressable's onPress on Android/Espresso.
        await element(by.id('picker_item_US')).tap();
        countrySelected = true;
      } catch (e) {
        // Fallback: try tapping by text or closing modal
        try {
          await element(by.text('🇺🇸   United States')).tap();
          countrySelected = true;
        } catch (e2) {
          console.log('Country search/select failed');
        }
      }

      if (!countrySelected) {
        // Close modal via the close (X) button, NOT device.pressBack()
        console.log('Country not selected, closing modal via close button');
        try {
          await element(by.type('com.horcrux.svg.SvgView')).atIndex(0).tap();
        } catch (e3) {
          console.log('Could not find close button, trying back gesture');
          await device.pressBack();
        }
      }
      if (countrySelected) {
        console.log('Selected country: United States');
      } else {
        console.log('WARNING: Country was NOT selected');
      }
      // Wait longer for country context to propagate to state picker
      await waitForUIStabilization(2000);

      // Check if payment sheet is still visible after country selection
      const sheetAfterCountry = await isElementVisible(
        element(by.id(testIds.paymentSheetScrollViewTestId)),
      );
      console.log(
        'Payment sheet visible after country selection:',
        sheetAfterCountry,
      );
    }

    // Now select state (after country is set, state list will be populated)
    // Scroll to state selector
    try {
      await waitFor(element(by.id('payment_method_data.billing.address.state')))
        .toBeVisible()
        .whileElement(by.id(testIds.paymentSheetScrollViewTestId))
        .scroll(100, 'down');
    } catch (e) {
      // May already be visible
    }

    const stateSelect = element(
      by.id('payment_method_data.billing.address.state'),
    );
    if (await isElementVisible(stateSelect)) {
      await stateSelect.tap();
      await waitForUIStabilization(2000);

      // The modal contains a search input and a scrollable list of states.
      // States for US are displayed as just the state name (e.g. "California")
      // because the JSON data has no "label" field.
      // California is alphabetically ~7th in the US states list.
      const stateSearchId =
        'picker_search_payment_method_data.billing.address.state';
      let stateSelected = false;

      // State items are rendered as just the state name (e.g. "California")
      // because the JSON data has no "label" field, so getStateData returns
      // item.value directly (not "California - CA").
      // Each FlatList item has testID="picker_item_<value>". For states,
      // the value is the state code (e.g. "CA" for California).
      const stateItemId = 'picker_item_CA';

      // Strategy 1: Wait for the item to be visible and tap by testID
      try {
        await waitFor(element(by.id(stateItemId)))
          .toBeVisible()
          .withTimeout(5000);
        await element(by.id(stateItemId)).tap();
        stateSelected = true;
        console.log('Selected state via testID: California');
      } catch (e) {
        console.log(
          'State item not found by testID, trying scroll approach...',
        );

        // Strategy 2: Scroll down in the FlatList to find the item
        try {
          const flatList = element(
            by.type('com.facebook.react.views.scroll.ReactScrollView'),
          ).atIndex(0);
          for (let i = 0; i < 5; i++) {
            try {
              await waitFor(element(by.id(stateItemId)))
                .toBeVisible()
                .withTimeout(1000);
              await element(by.id(stateItemId)).tap();
              stateSelected = true;
              console.log(
                `Selected state via scroll (attempt ${i + 1}): California`,
              );
              break;
            } catch (_) {
              await flatList.swipe('up', 'slow', 0.15);
              await waitForUIStabilization(300);
            }
          }
        } catch (e2) {
          console.log('All scroll attempts failed for state picker');
        }
      }

      if (!stateSelected) {
        console.log(
          'WARNING: State was NOT selected - closing modal via close button',
        );
        // Close the modal using the close (X) button - NOT device.pressBack()
        try {
          await element(by.type('com.horcrux.svg.SvgView')).atIndex(0).tap();
        } catch (e4) {
          console.log('Could not find close button for state picker');
          // Last resort: pressBack
          console.log('WARNING: Using device.pressBack() to close state modal');
          await device.pressBack();
        }
      }
      await waitForUIStabilization(500);
    }

    // After picker interactions, no keyboard should be open.
    // Do NOT call dismissKeyboard() here as it may fallback to device.pressBack()
    // which could close the entire payment sheet.
    // Instead, verify the payment sheet is still visible.
    const sheetStillVisible = await isElementVisible(
      element(by.id(testIds.paymentSheetScrollViewTestId)),
    );
    if (!sheetStillVisible) {
      console.log(
        'WARNING: Payment sheet ScrollView not visible after billing fields entry!',
      );
      // Diagnostics: check what IS visible on screen
      const testModeVisible = await isElementVisible(
        element(by.text('Test Mode')),
      );
      console.log('Test Mode text visible:', testModeVisible);
      const launchBtnVisible = await isElementVisible(
        element(by.text('Launch Payment Sheet')),
      );
      console.log('Launch Payment Sheet button visible:', launchBtnVisible);
      const succeededVisible = await isElementVisible(
        element(by.text('succeeded')),
      );
      console.log('succeeded text visible:', succeededVisible);
      const failedVisible = await isElementVisible(
        element(by.text('payment failed')),
      );
      console.log('payment failed text visible:', failedVisible);
    } else {
      console.log(
        'Payment sheet still visible after all billing fields entered',
      );
    }

    logger.log('Test finished in:', testStartTime, Date.now());
  });

  it('should complete payment with all fields filled', async () => {
    testStartTime = Date.now();
    logger.log('Test starting at:', testStartTime);

    // Dismiss keyboard first
    await dismissKeyboard();
    await waitForUIStabilization(500);

    // Check if the payment sheet is still visible
    const scrollViewVisible = await isElementVisible(
      element(by.id(testIds.paymentSheetScrollViewTestId)),
    );
    if (!scrollViewVisible) {
      console.log(
        'Payment sheet not visible! It may have been dismissed. Trying to find pay button directly.',
      );
    }

    // Scroll down to make pay button visible
    if (scrollViewVisible) {
      await element(by.id(testIds.paymentSheetScrollViewTestId)).swipe(
        'up',
        'slow',
        0.8,
      );
      await waitForUIStabilization(500);

      // Try scrolling further if needed
      try {
        await waitFor(element(by.id(testIds.payButtonTestId)))
          .toBeVisible()
          .whileElement(by.id(testIds.paymentSheetScrollViewTestId))
          .scroll(200, 'down');
      } catch (e) {
        // Button may already be visible
      }
    }

    await completePayment(testIds);

    logger.log('Test finished in:', testStartTime, Date.now());
    logger.log(
      'Superposition Billing Fields Test finished in:',
      globalStartTime,
      Date.now(),
    );
  });
});
