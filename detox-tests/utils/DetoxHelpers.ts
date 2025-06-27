import { SAVED_PAYMENT_SHEET_INDICATORS, NORMAL_PAYMENT_SHEET_INDICATORS, TIMEOUT_CONFIG } from "../fixtures/Constants";

export async function takeScreenshot(name: string): Promise<void> {
    try {
        await device.takeScreenshot(name);
        console.log(`📸 Screenshot taken: ${name}`);
    } catch (error) {
        console.log(`❌ Failed to take screenshot ${name}:`, error.message);
    }
}

const DEFAULT_TIMEOUT = TIMEOUT_CONFIG.get('DEFAULT');
const LONG_TIMEOUT = TIMEOUT_CONFIG.get('LONG');
const NAVIGATION_WAIT = TIMEOUT_CONFIG.get('NAVIGATION_WAIT');
const UI_STABILIZATION_WAIT = TIMEOUT_CONFIG.get('UI_STABILIZATION');
const ELEMENT_SEARCH_TIMEOUT = TIMEOUT_CONFIG.get('ELEMENT_SEARCH');

export async function waitForVisibility(element: Detox.IndexableNativeElement, timeout = DEFAULT_TIMEOUT) {
    await waitFor(element)
        .toBeVisible()
        .withTimeout(timeout);
}

export async function typeTextInInput(element: Detox.IndexableNativeElement, text: string) {
    device.getPlatform() == "ios" ?
        await element.typeText(text) : await element.replaceText(text);
}

export async function waitForUIStabilization(duration: number = UI_STABILIZATION_WAIT): Promise<void> {
    const isCI = TIMEOUT_CONFIG.IS_CI;
    const waitTime = isCI ? Math.round(duration * TIMEOUT_CONFIG.CI_MULTIPLIER) : duration;
    console.log(`Waiting ${waitTime}ms for UI to stabilize${isCI ? ' (CI environment)' : ''}...`);
    await new Promise(resolve => setTimeout(resolve, waitTime));
}

async function findAddNewPaymentMethodElement(): Promise<Detox.IndexableNativeElement | null> {
    const variations = [
        "Add new payment method"
    ];

    await waitForUIStabilization(2000);

    for (const text of variations) {
        try {
            console.log(`Trying to find element with text: "${text}"`);
            const elementMatcher = by.text(text);
            await waitFor(element(elementMatcher)).toBeVisible().withTimeout(ELEMENT_SEARCH_TIMEOUT);
            console.log(`✓ Found element with text: "${text}"`);
            return element(elementMatcher);
        } catch (error) {
            console.log(`✗ Element with text "${text}" not found`);
        }
    }

    try {
        console.log("Trying partial text matching for 'Add new payment'");
        const elementMatcher = by.text("Add new payment");
        await waitFor(element(elementMatcher)).toBeVisible().withTimeout(ELEMENT_SEARCH_TIMEOUT);
        console.log("✓ Found element with partial text 'Add new payment'");
        return element(elementMatcher);
    } catch (error) {
        console.log("✗ Partial text matching failed");
    }

    try {
        console.log("Trying to find any element containing 'Add'");
        const elementMatcher = by.text("Add");
        await waitFor(element(elementMatcher)).toBeVisible().withTimeout(ELEMENT_SEARCH_TIMEOUT);
        console.log("✓ Found element containing 'Add'");
        return element(elementMatcher);
    } catch (error) {
        console.log("✗ No element containing 'Add' found");
    }

    return null;
}

export async function isSavedPaymentSheet(): Promise<boolean> {
    console.log(`Checking for saved payment sheet indicators${TIMEOUT_CONFIG.IS_CI ? ' (CI environment)' : ''}...`);

    await waitForUIStabilization();

    let foundIndicators = 0;
    const requiredIndicators = 1;

    try {
        const titleElement = element(by.text(SAVED_PAYMENT_SHEET_INDICATORS.TITLE_TEXT));
        await waitFor(titleElement).toBeVisible().withTimeout(ELEMENT_SEARCH_TIMEOUT);
        console.log("✓ Found saved payment sheet title: 'Payment methods'");
        foundIndicators++;
    } catch (error) {
        console.log("✗ Title 'Payment methods' not found");
    }

    try {
        const addNewElement = await findAddNewPaymentMethodElement();
        if (addNewElement) {
            console.log("✓ Found 'Add new payment method' link");
            foundIndicators++;
        } else {
            console.log("✗ 'Add new payment method' link not found with any variation");
        }
    } catch (error) {
        console.log("✗ Error checking for add new payment method:", error.message);
    }

    try {
        const savedCardElement = element(by.text(SAVED_PAYMENT_SHEET_INDICATORS.SAVED_CARD_PATTERN));
        await waitFor(savedCardElement).toBeVisible().withTimeout(ELEMENT_SEARCH_TIMEOUT);
        console.log("✓ Found saved card pattern (••••)");
        foundIndicators++;
    } catch (error) {
        console.log("✗ Saved card pattern not found");
    }

    try {
        const visaElement = element(by.text("VISA"));
        await waitFor(visaElement).toBeVisible().withTimeout(ELEMENT_SEARCH_TIMEOUT);
        console.log("✓ Found VISA text (indicates saved card)");
        foundIndicators++;
    } catch (error) {
        console.log("✗ VISA text not found");
    }

    const isSaved = foundIndicators >= requiredIndicators;
    console.log(`Saved payment sheet detection: ${foundIndicators}/${requiredIndicators} indicators found - ${isSaved ? 'CONFIRMED' : 'NOT CONFIRMED'}`);

    return isSaved;
}

export async function isNormalPaymentSheet(): Promise<boolean> {
    console.log(`Checking for normal payment sheet indicators${TIMEOUT_CONFIG.IS_CI ? ' (CI environment)' : ''}...`);

    await waitForUIStabilization();

    let foundIndicators = 0;
    const requiredIndicators = 1;

    try {
        const titleElement = element(by.text(NORMAL_PAYMENT_SHEET_INDICATORS.TITLE_TEXT));
        await waitFor(titleElement).toBeVisible().withTimeout(ELEMENT_SEARCH_TIMEOUT);
        console.log("✓ Found normal payment sheet title: 'Select payment method'");
        foundIndicators++;
    } catch (error) {
        console.log("✗ Title 'Select payment method' not found");
    }

    // Check for "Card Details" text with environment-aware timeout
    try {
        const cardDetailsElement = element(by.text(NORMAL_PAYMENT_SHEET_INDICATORS.CARD_DETAILS_TEXT));
        await waitFor(cardDetailsElement).toBeVisible().withTimeout(ELEMENT_SEARCH_TIMEOUT);
        console.log("✓ Found 'Card Details' section");
        foundIndicators++;
    } catch (error) {
        console.log("✗ 'Card Details' section not found");
    }

    // Check for card number input with placeholder "1234 1234 1234 1234" with environment-aware timeout
    try {
        const cardNumberPlaceholder = element(by.text(NORMAL_PAYMENT_SHEET_INDICATORS.CARD_NUMBER_PLACEHOLDER));
        await waitFor(cardNumberPlaceholder).toBeVisible().withTimeout(ELEMENT_SEARCH_TIMEOUT);
        console.log("✓ Found card number placeholder");
        foundIndicators++;
    } catch (error) {
        console.log("✗ Card number placeholder not found");
    }

    // Check for "Or pay using" text with environment-aware timeout
    try {
        const orPayUsingElement = element(by.text(NORMAL_PAYMENT_SHEET_INDICATORS.OR_PAY_USING_TEXT));
        await waitFor(orPayUsingElement).toBeVisible().withTimeout(ELEMENT_SEARCH_TIMEOUT);
        console.log("✓ Found 'Or pay using' text");
        foundIndicators++;
    } catch (error) {
        console.log("✗ 'Or pay using' text not found");
    }

    const isNormal = foundIndicators >= requiredIndicators;
    console.log(`Normal payment sheet detection: ${foundIndicators}/${requiredIndicators} indicators found - ${isNormal ? 'CONFIRMED' : 'NOT CONFIRMED'}`);

    return isNormal;
}


export async function navigateToNormalPaymentSheet(): Promise<void> {
    try {
        console.log(`Navigating from saved payment sheet to normal payment sheet${TIMEOUT_CONFIG.IS_CI ? ' (CI environment)' : ''}...`);

        console.log("Searching for 'Add new payment method' element...");
        const addNewElement = await findAddNewPaymentMethodElement();

        if (!addNewElement) {
            throw new Error("Could not find 'Add new payment method' element with any variation");
        }

        console.log("Found 'Add new payment method' element, attempting to tap...");
        await addNewElement.tap();

        console.log("Waiting for navigation to complete...");
        await waitForUIStabilization(NAVIGATION_WAIT);

        console.log("✓ Successfully tapped on 'Add new payment method'");
    } catch (error) {
        console.error("✗ Failed to navigate to normal payment sheet:", error.message);
        throw new Error(`Navigation failed: ${error.message}`);
    }
}


export async function enterCardDetails(cardNumber: string, expiryDate: string, cvc: string, testIds: any): Promise<void> {
    console.log(`Starting card details entry with enhanced error handling${TIMEOUT_CONFIG.IS_CI ? ' (CI environment)' : ''}...`);
    await waitForUIStabilization();
    console.log("Entering card number...");
    const cardNumberInput = element(by.id(testIds.cardNumberInputTestId));
    await waitFor(cardNumberInput).toExist().withTimeout(DEFAULT_TIMEOUT);
    await waitForVisibility(cardNumberInput, DEFAULT_TIMEOUT);
    await cardNumberInput.tap();
    await waitForUIStabilization(1000); // Wait after tap
    await cardNumberInput.clearText();
    await typeTextInInput(cardNumberInput, cardNumber);
    await waitForUIStabilization(1000); // Wait after typing

    // Expiry Date Input
    console.log("Entering expiry date...");
    const expiryInput = element(by.id(testIds.expiryInputTestId));
    await waitFor(expiryInput).toExist().withTimeout(DEFAULT_TIMEOUT);
    await waitForVisibility(expiryInput, DEFAULT_TIMEOUT);
    await expiryInput.typeText(expiryDate);
    await waitForUIStabilization(1000); // Wait after typing

    // CVC Input
    console.log("Entering CVC...");
    const cvcInput = element(by.id(testIds.cvcInputTestId));
    await waitFor(cvcInput).toExist().withTimeout(DEFAULT_TIMEOUT);
    await waitForVisibility(cvcInput, DEFAULT_TIMEOUT);
    await cvcInput.typeText(cvc);
    await waitForUIStabilization(1000); // Wait after typing

    console.log("✓ Card details entered successfully");
}

export async function completePayment(testIds: any): Promise<void> {
    console.log(`Starting payment completion${TIMEOUT_CONFIG.IS_CI ? ' (CI environment)' : ''}...`);

    await waitForUIStabilization();
    await takeScreenshot('pay-button-search-start');

    try {
        console.log(`Looking for pay button with testID: ${testIds.payButtonTestId}`);
        const payNowButton = element(by.id(testIds.payButtonTestId));
        
        console.log("Waiting for pay button to exist...");
        await waitFor(payNowButton).toExist().withTimeout(DEFAULT_TIMEOUT);
        
        console.log("Waiting for pay button to be visible...");
        await waitForVisibility(payNowButton, DEFAULT_TIMEOUT);
        
        await takeScreenshot('pay-button-found');
        console.log("✓ Pay button found, attempting to tap...");
        await payNowButton.tap();
        await takeScreenshot('pay-button-tapped');

        console.log("Waiting for payment processing...");
        const processingWait = TIMEOUT_CONFIG.get('PAYMENT_PROCESSING');
        await waitForUIStabilization(processingWait);
        await takeScreenshot('payment-processing');

        if (device.getPlatform() === "ios") {
            await waitForVisibility(element(by.text('Payment complete')), LONG_TIMEOUT);
        } else {
            await waitForVisibility(element(by.text('succeeded')), LONG_TIMEOUT);
        }

        await takeScreenshot('payment-success');
        console.log("✓ Payment completed successfully");
    } catch (error) {
        await takeScreenshot('pay-button-error');
        console.error(`❌ Payment completion failed: ${error.message}`);
        console.error(`Platform: ${device.getPlatform()}`);
        console.error(`TestID being searched: ${testIds.payButtonTestId}`);
        throw error;
    }
}

export async function ensureNormalPaymentSheet(): Promise<'saved' | 'normal'> {
    console.log(`=== Payment Sheet Detection Started${TIMEOUT_CONFIG.IS_CI ? ' (CI Environment)' : ''} ===`);

    try {
        console.log("Waiting for payment sheet to fully load...");
        const initialWait = TIMEOUT_CONFIG.IS_CI ? 8000 : 5000;
        await waitForUIStabilization(initialWait);

        if (await isSavedPaymentSheet()) {
            console.log("📋 Detected: Saved Payment Sheet");
            await navigateToNormalPaymentSheet();

            console.log("Waiting after navigation for screen to stabilize...");
            const postNavWait = TIMEOUT_CONFIG.IS_CI ? 12000 : 8000;
            await waitForUIStabilization(postNavWait);

            const isNormal = await isNormalPaymentSheet();
            if (!isNormal) {
                console.log("⚠️ Warning: Could not verify normal payment sheet after navigation, but proceeding...");
            } else {
                console.log("✅ Successfully switched to normal payment sheet");
            }

            return 'saved';
        }

        if (await isNormalPaymentSheet()) {
            console.log("📋 Detected: Normal Payment Sheet (already ready)");
            return 'normal';
        }

        throw new Error("Unable to detect payment sheet type - neither saved nor normal indicators found");

    } catch (error) {
        console.error("❌ Payment sheet detection failed:", error.message);
        throw error;
    } finally {
        console.log("=== Payment Sheet Detection Completed ===");
    }
}
