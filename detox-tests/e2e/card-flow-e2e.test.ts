import * as testIds from "../../src/utility/test/TestUtils.bs.js";
import { device, element, by, waitFor } from "detox"
import { visaSandboxCard, LAUNCH_PAYMENT_SHEET_BTN_TEXT } from "../fixtures/Constants"
import { waitForVisibility, typeTextInInput } from "../utils/DetoxHelpers"
describe('card-flow-e2e-test', () => {
  jest.retryTimes(6);
  beforeAll(async () => {
    await device.launchApp({
      launchArgs: { detoxEnableSynchronization: 1 },
      newInstance: true,
    });
    await device.enableSynchronization();
  });

  it('demo app should load successfully', async () => {
    await waitForVisibility(element(by.text(LAUNCH_PAYMENT_SHEET_BTN_TEXT)))
  });

  it('payment sheet should open', async () => {
    await element(by.text(LAUNCH_PAYMENT_SHEET_BTN_TEXT)).tap();
    try {
      await waitForVisibility(element(by.text('Test Mode')), 60000)
    } catch (error) {
      await waitForVisibility(element(by.id(testIds.cardNumberInputTestId)), 30000);
    }
  })

  it('should enter details in card form', async () => {
    const cardNumberInput = await element(by.id(testIds.cardNumberInputTestId))
    const expiryInput = await element(by.id(testIds.expiryInputTestId))
    const cvcInput = await element(by.id(testIds.cvcInputTestId))

    await waitFor(cardNumberInput).toExist();
    await waitForVisibility(cardNumberInput);
    await cardNumberInput.tap();

    await cardNumberInput.clearText();
    await typeTextInInput(cardNumberInput, visaSandboxCard.cardNumber)

    await waitFor(expiryInput).toExist();
    await waitForVisibility(expiryInput);
    await expiryInput.typeText(visaSandboxCard.expiryDate);

    await waitFor(cvcInput).toExist();
    await waitForVisibility(cvcInput);
    await cvcInput.typeText(visaSandboxCard.cvc);
  });

  it('should be able to succesfully complete card payment', async () => {
    try {
      await element(by.id('card-form-scroll-view')).scrollTo('bottom');
    } catch (error) {
    }
      let buttonFound = false;
    
    try {
      const exactPayButton = element(by.text('Purchase ($2.00)'));
      await waitFor(exactPayButton).toBeVisible().withTimeout(10000);
      await exactPayButton.tap();
      buttonFound = true;
    } catch (error) {
    }
    
    if (!buttonFound) {
      try {
        const payNowButton = element(by.id(testIds.payButtonTestId));
        await waitFor(payNowButton).toExist().withTimeout(10000);
        await waitForVisibility(payNowButton);
        await payNowButton.tap();
        buttonFound = true;
      } catch (error) {
      }
    }
    
    if (!buttonFound) {
      const payButtonTextMatcher = element(by.text(/Purchase|Pay|Continue/i));
      await waitFor(payButtonTextMatcher).toBeVisible().withTimeout(20000);
      await payButtonTextMatcher.tap();
    }

    if (device.getPlatform() === "ios") {
      await waitForVisibility(element(by.text('Payment complete')), 60000);
    } else {
      try {
        await waitForVisibility(element(by.text('succeeded')), 30000);
      } catch (error) {
        await waitForVisibility(element(by.text(/success|completed|approved/i)), 30000);
      }
    }
  })
});