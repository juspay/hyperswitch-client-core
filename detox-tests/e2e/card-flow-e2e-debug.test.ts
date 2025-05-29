import * as testIds from "../../src/utility/test/TestUtils.bs.js";
import { device } from "detox"
import { visaSandboxCard, LAUNCH_PAYMENT_SHEET_BTN_TEXT } from "../fixtures/Constants"
import { waitForVisibility, typeTextInInput } from "../utils/DetoxHelpers"

describe('card-flow-e2e-debug-test', () => {
  jest.retryTimes(1); // Reduce retries for debugging
  
  beforeAll(async () => {
    console.log('🚀 Starting debug test...');
    console.log('Platform:', device.getPlatform());
    
    await device.launchApp({
      launchArgs: { detoxEnableSynchronization: 1 },
      newInstance: true,
    });
    await device.enableSynchronization();
    console.log('✅ App launched successfully');
  });

  it('demo app should load successfully', async () => {
    console.log('🔍 Looking for launch button...');
    await waitForVisibility(element(by.text(LAUNCH_PAYMENT_SHEET_BTN_TEXT)));
    console.log('✅ Launch button found');
  });

  it('payment sheet should open', async () => {
    console.log('🔍 Tapping launch button...');
    await element(by.text(LAUNCH_PAYMENT_SHEET_BTN_TEXT)).tap();
    console.log('🔍 Looking for Test Mode text...');
    await waitForVisibility(element(by.text('Test Mode')), 30000);
    console.log('✅ Payment sheet opened');
  });

  it('debug card form elements', async () => {
    console.log('🔍 Starting card form debug...');
    
    // Take screenshot before looking for elements
    await device.takeScreenshot('before-card-form');
    
    // Add delay and log app state
    console.log('⏳ Adding delay for UI to settle...');
    await device.disableSynchronization();
    await new Promise(resolve => setTimeout(resolve, 5000));
    await device.enableSynchronization();
    
    // Take screenshot after delay
    await device.takeScreenshot('after-delay');
    
    console.log('🔍 Looking for card number input...');
    console.log('Card number test ID:', testIds.cardNumberInputTestId);
    
    try {
      // Try multiple ways to find the element
      const cardNumberInput = element(by.id(testIds.cardNumberInputTestId));
      
      console.log('🔍 Checking if card number input exists...');
      await waitFor(cardNumberInput).toExist().withTimeout(10000);
      console.log('✅ Card number input exists');
      
      console.log('🔍 Checking if card number input is visible...');
      await waitFor(cardNumberInput).toBeVisible().withTimeout(10000);
      console.log('✅ Card number input is visible');
      
      // Try alternative selectors
    } catch (error) {
      console.log('❌ Card number input not found with ID selector');
      console.log('Error:', error.message);
      
      // Take screenshot of current state
      await device.takeScreenshot('card-input-not-found');
      
      // Try to find any text inputs
      console.log('🔍 Looking for any text inputs...');
      try {
        const anyTextInput = element(by.type('android.widget.EditText'));
        await waitFor(anyTextInput).toExist().withTimeout(5000);
        console.log('✅ Found some text input');
      } catch (e) {
        console.log('❌ No text inputs found');
      }
      
      // Try to find by placeholder or other attributes
      console.log('🔍 Looking for card number by placeholder...');
      try {
        const cardByPlaceholder = element(by.text('1234 1234 1234 1234'));
        await waitFor(cardByPlaceholder).toExist().withTimeout(5000);
        console.log('✅ Found card input by placeholder');
      } catch (e) {
        console.log('❌ Card input not found by placeholder');
      }
      
      // Dump the entire view hierarchy
      console.log('🔍 Dumping view hierarchy...');
      try {
        // This will help us see what elements are actually available
        await element(by.id('non-existent-id')).tap();
      } catch (hierarchyError) {
        console.log('View hierarchy error (this is expected):', hierarchyError.message);
      }
      
      throw error;
    }
  });

  it('debug expiry and cvc inputs', async () => {
    console.log('🔍 Looking for expiry input...');
    console.log('Expiry test ID:', testIds.expiryInputTestId);
    
    try {
      const expiryInput = element(by.id(testIds.expiryInputTestId));
      await waitFor(expiryInput).toExist().withTimeout(10000);
      await waitFor(expiryInput).toBeVisible().withTimeout(10000);
      console.log('✅ Expiry input found');
    } catch (error) {
      console.log('❌ Expiry input not found');
      console.log('Error:', error.message);
      await device.takeScreenshot('expiry-input-not-found');
    }
    
    console.log('🔍 Looking for CVC input...');
    console.log('CVC test ID:', testIds.cvcInputTestId);
    
    try {
      const cvcInput = element(by.id(testIds.cvcInputTestId));
      await waitFor(cvcInput).toExist().withTimeout(10000);
      await waitFor(cvcInput).toBeVisible().withTimeout(10000);
      console.log('✅ CVC input found');
    } catch (error) {
      console.log('❌ CVC input not found');
      console.log('Error:', error.message);
      await device.takeScreenshot('cvc-input-not-found');
    }
  });

  it('debug pay button', async () => {
    console.log('🔍 Looking for pay button...');
    console.log('Pay button test ID:', testIds.payButtonTestId);
    
    try {
      const payButton = element(by.id(testIds.payButtonTestId));
      await waitFor(payButton).toExist().withTimeout(10000);
      await waitFor(payButton).toBeVisible().withTimeout(10000);
      console.log('✅ Pay button found');
    } catch (error) {
      console.log('❌ Pay button not found');
      console.log('Error:', error.message);
      await device.takeScreenshot('pay-button-not-found');
    }
  });
});
