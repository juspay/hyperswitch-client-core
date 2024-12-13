const cardNumberInputTestId = 'CardNumberInputTestId';
const cvcInputTestId = 'CVCInputTestId';
const expiryInputTestId = 'ExpiryInputTestId';
const payButtonTestId = 'Pay';
describe('Example', () => {
  jest.retryTimes(6);
  beforeAll(async () => {
    await device.launchApp({
      launchArgs: {detoxEnableSynchronization: 1},
      newInstance: true,
    });
    await device.enableSynchronization();
  });

  // testing 5
  // testing 2
  // testing 3
  //
  //
  //
  //
  // beforeEach(async () => {
  //   await device.reloadReactNative();
  // });

  it('should have welcome screen', async () => {
    // await expect(element(by.id('welcome'))).toBeVisible();
    // await expect(element(by.text('Launch Payment Sheet'))).toBeVisible();

    await waitFor(element(by.text('Launch Payment Sheet')))
      .toBeVisible()
      .withTimeout(10000);
    await element(by.text('Launch Payment Sheet')).tap();

    await waitFor(element(by.text('Test Mode')))
      .toBeVisible()
      .withTimeout(10000);

    // await element(by.text('MM / YY')).typeText('04/24');
    // await element(by.text('CVC')).typeText('424');
  });

  it('should enter card no', async () => {
    await device.enableSynchronization();
    await waitFor(element(by.text('1234 1234 1234 1234')))
      .toBeVisible()
      .withTimeout(10000);

    await element(by.id(cardNumberInputTestId)).tap();

    await waitFor(element(by.id(cardNumberInputTestId))).toExist();
    await waitFor(element(by.id(cardNumberInputTestId))).toBeVisible();

    await element(by.id(cardNumberInputTestId)).clearText();
    await element(by.id(cardNumberInputTestId)).replaceText('4242424242424242');
    // await expect(element(by.id(cardNumberInputTestId))).toHaveText(
    //   '4242424242424242',
    // );

    await waitFor(element(by.id(expiryInputTestId))).toExist();
    await waitFor(element(by.id(expiryInputTestId))).toBeVisible();
    await element(by.id(expiryInputTestId)).typeText('04/44');

    await waitFor(element(by.id(cvcInputTestId))).toExist();
    await waitFor(element(by.id(cvcInputTestId))).toBeVisible();
    await element(by.id(cvcInputTestId)).typeText('123');

    // await waitFor(element(by.id(payButtonTestId))).toExist();
    await waitFor(element(by.id(payButtonTestId)))
      .toBeVisible()
      .withTimeout(10000);

    // await device.pressBack();
    await element(by.id(payButtonTestId)).tap();
    // await element(by.id(payButtonTestId)).tap();

    // await element(by.id('CardNumberInput')).typeText('1234');
    await waitFor(element(by.text('succeeded')))
      .toBeVisible()
      .withTimeout(10000);
  });
});
