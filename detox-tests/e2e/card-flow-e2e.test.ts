import * as testIds from "../../src/utility/test/TestUtils.bs.js";
import { device } from "detox"
describe('Example', () => {
  jest.retryTimes(6);
  beforeAll(async () => {
    await device.launchApp({
      launchArgs: { detoxEnableSynchronization: 1 },
      newInstance: true,
    });
    await device.enableSynchronization();
  });

  it('demo app should load successfully', async () => {
    await waitFor(element(by.text('Launch Payment Sheet')))
      .toBeVisible()
      .withTimeout(10000);
    await element(by.text('Launch Payment Sheet')).tap();

    await waitFor(element(by.text('Test Mode')))
      .toBeVisible()
      .withTimeout(10000);
  });

  it('should enter card no', async () => {
    await device.enableSynchronization();
    await waitFor(element(by.text('1234 1234 1234 1234')))
      .toBeVisible()
      .withTimeout(10000);

    await element(by.id(testIds.cardNumberInputTestId)).tap();

    await waitFor(element(by.id(testIds.cardNumberInputTestId))).toExist();
    await waitFor(element(by.id(testIds.cardNumberInputTestId))).toBeVisible();

    await element(by.id(testIds.cardNumberInputTestId)).clearText();

    const cardNumberInput = await element(by.id(testIds.cardNumberInputTestId))

    device.getPlatform() == "ios" ?
      await cardNumberInput.typeText('4242424242424242') : await cardNumberInput.replaceText('4242424242424242');

    await waitFor(element(by.id(testIds.expiryInputTestId))).toExist();
    await waitFor(element(by.id(testIds.expiryInputTestId))).toBeVisible();
    await element(by.id(testIds.expiryInputTestId)).typeText('04/44');

    await waitFor(element(by.id(testIds.cvcInputTestId))).toExist();
    await waitFor(element(by.id(testIds.cvcInputTestId))).toBeVisible();
    await element(by.id(testIds.cvcInputTestId)).typeText('123');


    await waitFor(element(by.id(testIds.payButtonTestId)))
      .toBeVisible()
      .withTimeout(10000);


    await element(by.id(testIds.payButtonTestId)).tap();

    if (device.getPlatform() === "ios") {
      await waitFor(element(by.text('Payment complete')))
        .toBeVisible()
        .withTimeout(10000);
    }
    else {
      await waitFor(element(by.text('succeeded')))
        .toBeVisible()
        .withTimeout(10000);
    }

  });
});
