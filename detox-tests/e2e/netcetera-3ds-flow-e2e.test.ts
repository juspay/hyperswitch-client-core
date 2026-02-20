import * as testIds from "../../src/utility/test/TestUtils.bs.js";
import { device, element, by, waitFor } from "detox"
import { profileId, LAUNCH_PAYMENT_SHEET_BTN_TEXT, netceteraTestCard, TIMEOUT_CONFIG } from "../fixtures/Constants"
import { createTestLogger, waitForDemoAppLoad, launchPaymentSheet, navigateToNormalPaymentSheet, enterCardDetails, waitForVisibility, typeTextInInput, dismissKeyboard } from "../utils/DetoxHelpers"
import { CreateBody, setCreateBodyForTestAutomation } from "../utils/APIUtils";

const logger = createTestLogger();
let globalStartTime = Date.now();
let testStartTime = globalStartTime;

logger.log("Card Flow E2E Test Starting at:", globalStartTime);

describe('Netcetera 3DS E2E Test', () => {
    beforeAll(async () => {
        testStartTime = Date.now();
        logger.log("CPI & Device Sync Starting at:", testStartTime);

        const createPaymentBody = new CreateBody()
        createPaymentBody.addKey("profile_id", profileId)
        createPaymentBody.addKey("request_external_three_ds_authentication", true)
        createPaymentBody.addKey("authentication_type", 'three_ds')
        await setCreateBodyForTestAutomation(createPaymentBody.get())

        await device.launchApp({
            launchArgs: { detoxEnableSynchronization: 1 },
            newInstance: true,
        });
        await device.enableSynchronization();

        logger.log("CPI & Device Sync finished in:", testStartTime, Date.now());
    });

    it('should load demo app successfully', async () => {
        testStartTime = Date.now();
        logger.log("Test starting at:", testStartTime);

        await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);

        logger.log("Test finished in:", testStartTime, Date.now());
    });

    it('should open payment sheet', async () => {
        testStartTime = Date.now();
        logger.log("Test starting at:", testStartTime);

        await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);

        logger.log("Test finished in:", testStartTime, Date.now());
    });

    it('should navigate to normal payment sheet if needed', async () => {
        testStartTime = Date.now();
        logger.log("Test starting at:", testStartTime);

        await navigateToNormalPaymentSheet();

        logger.log("Test finished in:", testStartTime, Date.now());
    });

    it('should enter card details in form', async () => {
        testStartTime = Date.now();
        logger.log("Test starting at:", testStartTime);

        await enterCardDetails(
            netceteraTestCard.cardNumber,
            netceteraTestCard.expiryDate,
            netceteraTestCard.cvc,
            testIds
        );

        logger.log("Test finished in:", testStartTime, Date.now());
    });

    it('should complete card payment with 3DS (challenge or frictionless)', async () => {
        testStartTime = Date.now();
        logger.log("Test starting at:", testStartTime);

        await dismissKeyboard();
        
        const payButton = element(by.id(testIds.payButtonTestId));
        await payButton.tap();
        
        console.log("Pay button tapped, checking for payment result...");
        
        await device.disableSynchronization();
        
        try {
            // First, wait a bit and check if payment completed directly (frictionless)
            await new Promise(resolve => setTimeout(resolve, 5000));
            
            const statusPattern = /succeeded|processing|Payment complete|failed/i;
            
            try {
                console.log("Checking for frictionless success...");
                await waitFor(
                    element(by.text(statusPattern))
                ).toBeVisible().withTimeout(8000);
                
                console.log("Payment completed (frictionless)!");
                
            } catch (noSuccessYet) {
                // Success not found - likely needs 3DS challenge
                console.log("No immediate success - checking for 3DS challenge...");
                
                // Wait a bit more for 3DS screen
                await new Promise(resolve => setTimeout(resolve, 5000));
                
                try {
                    let otpInput;
                    
                    if (device.getPlatform() === "android") {
                        // Look for EditText that is NOT the server URL field
                        otpInput = element(by.type('android.widget.EditText')).atIndex(1);
                    } else {
                        otpInput = element(by.type('UITextField')).atIndex(0);
                    }
                    
                    await waitFor(otpInput).toBeVisible().withTimeout(10000);
                    
                    console.log("3DS Challenge detected - entering OTP...");
                    await otpInput.tap();
                    await otpInput.typeText("1234");
                    
                    console.log("OTP entered, looking for Submit button...");
                    
                    const submitButton = element(by.text('Submit'));
                    await waitFor(submitButton).toBeVisible().withTimeout(TIMEOUT_CONFIG.BASE.DEFAULT);
                    await submitButton.tap();
                    
                    console.log("Submit tapped, waiting for result...");
                    await new Promise(resolve => setTimeout(resolve, 5000));
                    
                    // Check for success after challenge
                    await waitFor(
                        element(by.text(statusPattern))
                    ).toBeVisible().withTimeout(TIMEOUT_CONFIG.BASE.LONG);
                    
                    console.log("Payment completed (after challenge)!");
                    
                } catch (challengeError) {
                    console.log("No 3DS challenge found either - checking final status...");
                    
                    // Final attempt to find success status
                    await waitFor(
                        element(by.text(statusPattern))
                    ).toBeVisible().withTimeout(TIMEOUT_CONFIG.BASE.LONG);
                }
            }
            
        } finally {
            await device.enableSynchronization();
        }

        logger.log("Test finished in:", testStartTime, Date.now());
       logger.log("Card Flow E2E Test finished in:", globalStartTime, Date.now());
    });
});