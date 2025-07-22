import * as testIds from "../../src/utility/test/TestUtils.bs.js";
import { device } from "detox"
import { visaSandboxCard, LAUNCH_PAYMENT_SHEET_BTN_TEXT, netceteraTestCard, TIMEOUT_CONFIG } from "../fixtures/Constants"
import { waitForVisibility, typeTextInInput, ensureNormalPaymentSheet, waitForUIStabilization } from "../utils/DetoxHelpers"
import { CreateBody, setCreateBodyForTestAutomation } from "../utils/APIUtils";
describe('card-flow-e2e-test', () => {
    jest.retryTimes(6);
    beforeAll(async () => {
        const createPaymentBody = new CreateBody()
        createPaymentBody.addKey("request_external_three_ds_authentication", true)
        createPaymentBody.addKey("authentication_type", 'three_ds')
        await setCreateBodyForTestAutomation(createPaymentBody.get())

        await device.launchApp({
            launchArgs: { detoxEnableSynchronization: 1 },
            newInstance: true,
        });
        // await device.enableSynchronization();
    });

    it('demo app should load successfully', async () => {
        await waitForVisibility(element(by.text(LAUNCH_PAYMENT_SHEET_BTN_TEXT)))
    });

    it('payment sheet should open', async () => {
        await element(by.text(LAUNCH_PAYMENT_SHEET_BTN_TEXT)).tap();
        await waitForVisibility(element(by.text('Test Mode')))
        const initialSheetType = await ensureNormalPaymentSheet();
        console.log(`Initial payment sheet type detected: ${initialSheetType}`);
    })

    it('should enter details in card form', async () => {
        const cardNumberInput = await element(by.id(testIds.cardNumberInputTestId))
        const expiryInput = await element(by.id(testIds.expiryInputTestId))
        const cvcInput = await element(by.id(testIds.cvcInputTestId))

        await waitFor(cardNumberInput).toExist();
        await waitForVisibility(cardNumberInput);
        await cardNumberInput.tap();

        await cardNumberInput.clearText();
        await typeTextInInput(cardNumberInput, netceteraTestCard.cardNumber)

        await waitFor(expiryInput).toExist();
        await waitForVisibility(expiryInput);
        await expiryInput.typeText(netceteraTestCard.expiryDate);

        await waitFor(cvcInput).toExist();
        await waitForVisibility(cvcInput);
        await cvcInput.typeText(netceteraTestCard.cvc);
    });

    it('Netcetera SDK Challenge should open', async () => {

        const payNowButton = await element(by.id(testIds.payButtonTestId))
        await waitFor(payNowButton).toExist();
        await waitForVisibility(payNowButton)
        await payNowButton.tap();

        await waitForUIStabilization(30000);

        const inputType = device.getPlatform() == "android" ? 'android.widget.EditText' : 'UITextField'
        const otpInput = await element(by.type(inputType));
        await waitForVisibility(otpInput, TIMEOUT_CONFIG.BASE.LONG);
        await typeTextInInput(otpInput, "1234")

        const submitButton = await element(by.text('Submit'))
        await submitButton.tap()
    })

    it('should be able to succesfully external 3DS card payment using Netcetera', async () => {
        if (device.getPlatform() === "ios")
            await waitForVisibility(element(by.text('Payment complete')))
        else
            await waitForVisibility(element(by.text('succeeded')))
    })
});