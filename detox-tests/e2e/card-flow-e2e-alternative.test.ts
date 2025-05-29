import * as testIds from "../../src/utility/test/TestUtils.bs.js";
import { device } from "detox"
import { visaSandboxCard, LAUNCH_PAYMENT_SHEET_BTN_TEXT } from "../fixtures/Constants"

describe('card-flow-e2e-alternative-test', () => {
  jest.retryTimes(3);
  
  beforeAll(async () => {
    await device.launchApp({
      launchArgs: { 
        detoxEnableSynchronization: 0, // Try with synchronization disabled
        detoxURLBlacklistRegex: '.*' // Disable network synchronization
      },
      newInstance: true,
    });
    // Keep synchronization disabled for CI
    await device.disableSynchronization();
  });

  it('demo app should load successfully', async () => {
    // Use longer timeout and manual delays
    await new Promise(resolve => setTimeout(resolve, 3000));
    await waitFor(element(by.text(LAUNCH_PAYMENT_SHEET_BTN_TEXT)))
      .toBeVisible()
      .withTimeout(60000);
  });

  it('payment sheet should open', async () => {
    await element(by.text(LAUNCH_PAYMENT_SHEET_BTN_TEXT)).tap();
    await new Promise(resolve => setTimeout(resolve, 5000));
    await waitFor(element(by.text('Test Mode')))
      .toBeVisible()
      .withTimeout(60000);
  });

  it('should enter details in card form using alternative selectors', async () => {
    // Wait longer for payment sheet to fully render
    await new Promise(resolve => setTimeout(resolve, 8000));
    
    // Try multiple strategies to find card inputs
    let cardNumberInput;
    let expiryInput;
    let cvcInput;
    
    // Strategy 1: Use test IDs
    try {
      cardNumberInput = element(by.id(testIds.cardNumberInputTestId));
      await waitFor(cardNumberInput).toExist().withTimeout(30000);
      console.log('✅ Found card input by test ID');
    } catch (error) {
      console.log('❌ Card input not found by test ID, trying alternatives...');
      
      // Strategy 2: Find by type (Android)
      try {
        cardNumberInput = element(by.type('android.widget.EditText')).atIndex(0);
        await waitFor(cardNumberInput).toExist().withTimeout(10000);
        console.log('✅ Found card input by type (first EditText)');
      } catch (error2) {
        // Strategy 3: Find by accessibility label or hint
        try {
          cardNumberInput = element(by.label('Card number'));
          await waitFor(cardNumberInput).toExist().withTimeout(10000);
          console.log('✅ Found card input by label');
        } catch (error3) {
          // Strategy 4: Find by placeholder text
          try {
            cardNumberInput = element(by.text('1234 1234 1234 1234'));
            await waitFor(cardNumberInput).toExist().withTimeout(10000);
            console.log('✅ Found card input by placeholder');
          } catch (error4) {
            throw new Error('Could not find card number input with any strategy');
          }
        }
      }
    }
    
    // Similar approach for expiry
    try {
      expiryInput = element(by.id(testIds.expiryInputTestId));
      await waitFor(expiryInput).toExist().withTimeout(30000);
    } catch (error) {
      try {
        expiryInput = element(by.type('android.widget.EditText')).atIndex(1);
        await waitFor(expiryInput).toExist().withTimeout(10000);
      } catch (error2) {
        try {
          expiryInput = element(by.text('MM/YY'));
          await waitFor(expiryInput).toExist().withTimeout(10000);
        } catch (error3) {
          throw new Error('Could not find expiry input');
        }
      }
    }
    
    // Similar approach for CVC
    try {
      cvcInput = element(by.id(testIds.cvcInputTestId));
      await waitFor(cvcInput).toExist().withTimeout(30000);
    } catch (error) {
      try {
        cvcInput = element(by.type('android.widget.EditText')).atIndex(2);
        await waitFor(cvcInput).toExist().withTimeout(10000);
      } catch (error2) {
        try {
          cvcInput = element(by.text('CVC'));
          await waitFor(cvcInput).toExist().withTimeout(10000);
        } catch (error3) {
          throw new Error('Could not find CVC input');
        }
      }
    }
    
    // Now try to interact with the elements
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    // Fill card number
    await waitFor(cardNumberInput).toBeVisible().withTimeout(30000);
    await cardNumberInput.tap();
    await new Promise(resolve => setTimeout(resolve, 1000));
    await cardNumberInput.clearText();
    await cardNumberInput.typeText(visaSandboxCard.cardNumber);
    
    // Fill expiry
    await new Promise(resolve => setTimeout(resolve, 1000));
    await waitFor(expiryInput).toBeVisible().withTimeout(30000);
    await expiryInput.tap();
    await new Promise(resolve => setTimeout(resolve, 1000));
    await expiryInput.typeText(visaSandboxCard.expiryDate);
    
    // Fill CVC
    await new Promise(resolve => setTimeout(resolve, 1000));
    await waitFor(cvcInput).toBeVisible().withTimeout(30000);
    await cvcInput.tap();
    await new Promise(resolve => setTimeout(resolve, 1000));
    await cvcInput.typeText(visaSandboxCard.cvc);
    
    // Wait a bit after filling all fields
    await new Promise(resolve => setTimeout(resolve, 2000));
  });

  it('should be able to successfully complete card payment', async () => {
    // Wait for form to be processed
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    let payButton;
    
    // Try multiple strategies to find pay button
    try {
      payButton = element(by.id(testIds.payButtonTestId));
      await waitFor(payButton).toExist().withTimeout(30000);
    } catch (error) {
      try {
        payButton = element(by.text('Pay'));
        await waitFor(payButton).toExist().withTimeout(10000);
      } catch (error2) {
        try {
          payButton = element(by.text('Pay Now'));
          await waitFor(payButton).toExist().withTimeout(10000);
        } catch (error3) {
          try {
            payButton = element(by.type('android.widget.Button'));
            await waitFor(payButton).toExist().withTimeout(10000);
          } catch (error4) {
            throw new Error('Could not find pay button');
          }
        }
      }
    }
    
    await waitFor(payButton).toBeVisible().withTimeout(30000);
    await payButton.tap();
    
    // Wait longer for payment processing in CI
    await new Promise(resolve => setTimeout(resolve, 10000));
    
    // Check for success message
    try {
      if (device.getPlatform() === "ios") {
        await waitFor(element(by.text('Payment complete')))
          .toBeVisible()
          .withTimeout(120000);
      } else {
        await waitFor(element(by.text('succeeded')))
          .toBeVisible()
          .withTimeout(120000);
      }
    } catch (error) {
      // Try alternative success indicators
      try {
        await waitFor(element(by.text('Success')))
          .toBeVisible()
          .withTimeout(30000);
      } catch (error2) {
        try {
          await waitFor(element(by.text('Complete')))
            .toBeVisible()
            .withTimeout(30000);
        } catch (error3) {
          throw new Error('Payment completion not detected');
        }
      }
    }
  });
});
