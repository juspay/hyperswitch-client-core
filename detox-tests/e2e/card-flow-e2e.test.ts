import * as testIds from "../../src/utility/test/TestUtils.bs.js";
import { device } from "detox"
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
    await waitForVisibility(element(by.text('Test Mode')), 30000)
  })

  it('should enter details in card form', async () => {
    await device.disableSynchronization();
    await new Promise(resolve => setTimeout(resolve, 5000));
    await device.enableSynchronization();

    const cardNumberInput = await element(by.id(testIds.cardNumberInputTestId))
    const expiryInput = await element(by.id(testIds.expiryInputTestId))
    const cvcInput = await element(by.id(testIds.cvcInputTestId))

    await waitFor(cardNumberInput).toExist().withTimeout(60000);
    await waitFor(cardNumberInput).toBeVisible().withTimeout(60000);
    await cardNumberInput.tap();

    await cardNumberInput.clearText();
    await typeTextInInput(cardNumberInput, visaSandboxCard.cardNumber)

    await waitFor(expiryInput).toExist().withTimeout(60000);
    await waitFor(expiryInput).toBeVisible().withTimeout(60000);
    await expiryInput.typeText(visaSandboxCard.expiryDate);

    await waitFor(cvcInput).toExist().withTimeout(60000);
    await waitFor(cvcInput).toBeVisible().withTimeout(60000);
    await cvcInput.typeText(visaSandboxCard.cvc);
  });

  it('should be able to succesfully complete card payment', async () => {
    await device.disableSynchronization();
    await new Promise(resolve => setTimeout(resolve, 3000));
    await device.enableSynchronization();

    const payNowButton = await element(by.id(testIds.payButtonTestId))
    await waitFor(payNowButton).toExist().withTimeout(60000);
    await waitFor(payNowButton).toBeVisible().withTimeout(60000);
    await payNowButton.tap();

    await device.disableSynchronization();
    await new Promise(resolve => setTimeout(resolve, 5000));
    await device.enableSynchronization();

    if (device.getPlatform() === "ios")
      await waitFor(element(by.text('Payment complete'))).toBeVisible().withTimeout(90000);
    else
      await waitFor(element(by.text('succeeded'))).toBeVisible().withTimeout(90000);
  })
});
