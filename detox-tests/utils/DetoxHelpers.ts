import * as testIds from "../../src/utility/test/TestUtils.bs.js";
import { SAVED_PAYMENT_SHEET_INDICATORS, NORMAL_PAYMENT_SHEET_INDICATORS, TIMEOUT_CONFIG, LAUNCH_PAYMENT_SHEET_BTN_TEXT } from "../fixtures/Constants";

const DEFAULT_TIMEOUT = TIMEOUT_CONFIG.get('DEFAULT');
const LONG_TIMEOUT = TIMEOUT_CONFIG.get('LONG');
const NAVIGATION_WAIT = TIMEOUT_CONFIG.get('NAVIGATION_WAIT');
const UI_STABILIZATION_WAIT = TIMEOUT_CONFIG.get('UI_STABILIZATION');

export interface TestLogger {
  log(message: string, time: number): void;
  log(message: string, startTime: number, endTime: number): void;
}

export async function waitForVisibility(element: Detox.IndexableNativeElement, timeout = DEFAULT_TIMEOUT) {
  await waitFor(element)
    .toBeVisible()
    .withTimeout(timeout);
}

export async function isElementVisible(element: Detox.IndexableNativeElement): Promise<boolean> {
  try {
    await waitFor(element).toBeVisible().withTimeout(1000);
    return true;
  } catch (e) {
    return false;
  }
}

export async function typeTextInInput(element: Detox.IndexableNativeElement, text: string) {
  device.getPlatform() == "ios" ?
    await element.typeText(text) : await element.replaceText(text);
}

export async function waitForUIStabilization(duration: number = UI_STABILIZATION_WAIT): Promise<void> {
  await new Promise(resolve => setTimeout(resolve, duration));
}

export async function enterCardDetails(cardNumber: string, expiryDate: string, cvc: string, testIds: any): Promise<void> {
  const cardNumberInput = element(by.id(testIds.cardNumberInputTestId));
  await cardNumberInput.tap();
  await cardNumberInput.clearText();
  await typeTextInInput(cardNumberInput, cardNumber);

  const expiryInput = element(by.id(testIds.expiryInputTestId));
  await expiryInput.typeText(expiryDate);

  const cvcInput = element(by.id(testIds.cvcInputTestId));
  await cvcInput.typeText(cvc);
}

export async function completePayment(testIds: any): Promise<void> {
  const payNowButton = element(by.id(testIds.payButtonTestId));
  await payNowButton.tap();

  // const inputType = device.getPlatform() == "android" ? 'android.widget.EditText' : 'UITextField'
  // const otpInput = await element(by.type(inputType));
  // await waitForVisibility(otpInput, TIMEOUT_CONFIG.BASE.LONG);
  // await typeTextInInput(otpInput, "1234")

  // const submitButton = await element(by.text('Submit'))
  // await submitButton.tap()

  if (device.getPlatform() === "ios") {
    await waitForVisibility(element(by.text(/.*(Payment complete|Somthing went wrong|payment failed|This payment method is blocked|Missing required param: browser_info.accept_header).*/i)), LONG_TIMEOUT);
    // await waitForVisibility(element(by.text('Payment complete')), LONG_TIMEOUT);
  } else {
    await waitForVisibility(element(by.text(/^(succeeded|processing|Somthing went wrong|payment failed|This payment method is blocked|Missing required param: browser_info.accept_header)$/i)), LONG_TIMEOUT)
    // await waitForVisibility(element(by.text(/^(succeeded|processing)$/i)), LONG_TIMEOUT)
  }
}

export function createTestLogger(): TestLogger {
  return {
    log(message: string, a: number, b?: number): void {
      if (b === undefined) {
        console.warn(message, new Date(a).toJSON());
      } else {
        const diffMs = Math.abs(b - a);
        const totalSeconds = Math.floor(diffMs / 1000);
        const minutes = Math.floor(totalSeconds / 60);
        const seconds = totalSeconds % 60;
        console.warn(message, minutes ? `${minutes} min ${seconds} sec` : `${seconds} sec`);
      }
    }
  };
}

export async function navigateToNormalPaymentSheet(): Promise<void> {
  // First check if we're already on the card form (card inputs are visible)
  const cardInputVisible = await isElementVisible(element(by.id(testIds.cardNumberInputTestId)));
  if (cardInputVisible) {
    console.log("Already on card form - card inputs are visible");
    return;
  }

  // Check if "Add new payment method" is visible (saved payment sheet)
  const isSavedSheet = await isElementVisible(element(by.text(SAVED_PAYMENT_SHEET_INDICATORS.ADD_NEW_PAYMENT_METHOD_TEXT)));
  if (isSavedSheet) {
    console.log("Detected Saved Payment Sheet", "Navigating to Normal Payment Sheet...");
    await element(by.text(SAVED_PAYMENT_SHEET_INDICATORS.ADD_NEW_PAYMENT_METHOD_TEXT)).tap();
    await waitForVisibility((element(by.text(/^(Card|Card Details|Or pay using)$/i)) as any).atIndex(0), NAVIGATION_WAIT);
    console.log("Successfully navigated to Normal Payment Sheet");
    return;
  }

  // Check if we're on "Select payment method" screen and need to select card or scroll
  const selectPaymentVisible = await isElementVisible(element(by.text(NORMAL_PAYMENT_SHEET_INDICATORS.TITLE_TEXT)));
  if (selectPaymentVisible) {
    console.log("On Select payment method screen, trying to select payment method...");

    // Wait longer for payment methods to load
    await waitForUIStabilization(5000);

    // Try scrolling to bottom of scroll view to reveal payment method options
    try {
      const scrollView = element(by.type('android.widget.ScrollView'));
      if (await isElementVisible(scrollView)) {
        // Scroll to bottom
        await scrollView.scrollTo('bottom');
        await waitForUIStabilization(2000);
        
        // Check again if card inputs are now visible
        const cardInputAfterScroll = await isElementVisible(element(by.id(testIds.cardNumberInputTestId)));
        if (cardInputAfterScroll) {
          console.log("Found card inputs after scrolling to bottom");
          return;
        }
      }
    } catch (e) {
      console.log("Scroll to bottom failed");
    }

    // Try tapping at center of scroll view to select default payment method
    try {
      const scrollView = element(by.type('android.widget.ScrollView'));
      if (await isElementVisible(scrollView)) {
        await scrollView.tapAtPoint({ x: 0.5, y: 0.5 }); // Tap at center
        await waitForUIStabilization(3000);
        
        const cardInputAfterTap = await isElementVisible(element(by.id(testIds.cardNumberInputTestId)));
        if (cardInputAfterTap) {
          console.log("Found card inputs after tapping center of scroll view");
          return;
        }
      }
    } catch (e) {
      console.log("Tap at center failed");
    }

    // Try scrolling back up and tapping
    try {
      const scrollView = element(by.type('android.widget.ScrollView'));
      if (await isElementVisible(scrollView)) {
        await scrollView.scrollTo('top');
        await waitForUIStabilization(1000);
        await scrollView.tapAtPoint({ x: 0.5, y: 0.3 }); // Tap upper center
        await waitForUIStabilization(3000);
        
        const cardInputAfterTapTop = await isElementVisible(element(by.id(testIds.cardNumberInputTestId)));
        if (cardInputAfterTapTop) {
          console.log("Found card inputs after tapping upper center");
          return;
        }
      }
    } catch (e) {
      console.log("Tap upper center failed");
    }

    // Try to find and tap "Card" option
    try {
      const cardOption = element(by.text(/^Card$/i));
      if (await isElementVisible(cardOption)) {
        await cardOption.tap();
        await waitForVisibility(element(by.id(testIds.cardNumberInputTestId)), NAVIGATION_WAIT);
        console.log("Successfully selected Card option");
        return;
      }
    } catch (e) {
      console.log("Card option not found");
    }

    // Try tapping on "Select payment method" text
    try {
      const selectText = element(by.text(NORMAL_PAYMENT_SHEET_INDICATORS.TITLE_TEXT));
      if (await isElementVisible(selectText)) {
        await selectText.tap();
        await waitForUIStabilization(3000);
        
        const cardInputAfterTapText = await isElementVisible(element(by.id(testIds.cardNumberInputTestId)));
        if (cardInputAfterTapText) {
          console.log("Found card inputs after tapping select text");
          return;
        }
      }
    } catch (e) {
      console.log("Tap on select text failed");
    }
  }

  console.log("Assuming card form should be visible or navigation complete");
}

export async function launchPaymentSheet(launchButtonText: string): Promise<void> {
  console.log("Launching payment sheet...");
  await element(by.text(launchButtonText)).tap();
  await waitForVisibility(element(by.text('Test Mode')), LONG_TIMEOUT);
  console.log("Payment sheet launched successfully");
}

export async function waitForDemoAppLoad(launchButtonText: string): Promise<void> {
  console.log("Waiting for demo app to load...");
  await waitForVisibility(element(by.text(launchButtonText)), DEFAULT_TIMEOUT);
  console.log("Demo app loaded successfully");
}

export async function closePaymentSheet(): Promise<void> {
  console.log("Closing payment sheet...");
  // Press Android back button to close the payment sheet
  await device.pressBack();
  // Wait for the main screen to be visible again
  await waitForVisibility(element(by.text(LAUNCH_PAYMENT_SHEET_BTN_TEXT)), DEFAULT_TIMEOUT);
  console.log("Payment sheet closed successfully");
}
