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
    await waitForVisibility(element(by.text(LAUNCH_PAYMENT_SHEET_BTN_TEXT)))
    await element(by.text(LAUNCH_PAYMENT_SHEET_BTN_TEXT)).tap();
    await waitForVisibility(element(by.text('Test Mode')))
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
    const payNowButton = await element(by.id(testIds.payButtonTestId))
    await waitFor(payNowButton).toExist();
    await waitForVisibility(payNowButton)
    await payNowButton.tap();

    if (device.getPlatform() === "ios")
      await waitForVisibility(element(by.text('Payment complete')))
    else
      await waitForVisibility(element(by.text('succeeded')))
  })
});
