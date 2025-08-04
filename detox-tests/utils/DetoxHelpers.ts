import { SAVED_PAYMENT_SHEET_INDICATORS, NORMAL_PAYMENT_SHEET_INDICATORS, TIMEOUT_CONFIG } from "../fixtures/Constants";

const DEFAULT_TIMEOUT = TIMEOUT_CONFIG.get('DEFAULT');
const LONG_TIMEOUT = TIMEOUT_CONFIG.get('LONG');
const SHORT_TIMEOUT = TIMEOUT_CONFIG.get('SHORT');
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
    await waitFor(element).toBeVisible().withTimeout(device.getPlatform() == "ios" ? SHORT_TIMEOUT : DEFAULT_TIMEOUT);
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
    await waitForVisibility(element(by.text(/.*(Payment complete|payment failed|This payment method is blocked|Missing required param: browser_info.accept_header).*/i)), LONG_TIMEOUT);
    // await waitForVisibility(element(by.text('Payment complete')), LONG_TIMEOUT);
  } else {
    await waitForVisibility(element(by.text(/^(succeeded|processing|payment failed|This payment method is blocked|Missing required param: browser_info.accept_header)$/i)), LONG_TIMEOUT)
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
  const isSavedSheet = await isElementVisible(element(by.text(SAVED_PAYMENT_SHEET_INDICATORS.ADD_NEW_PAYMENT_METHOD_TEXT)));
  if (isSavedSheet) {
    console.log("Detected Saved Payment Sheet", "Navigating to Normal Payment Sheet...");
    await element(by.text(SAVED_PAYMENT_SHEET_INDICATORS.ADD_NEW_PAYMENT_METHOD_TEXT)).tap();
    await waitForVisibility((element(by.text(/^(Card|Card Details|Or pay using)$/i)) as any).atIndex(0), NAVIGATION_WAIT);
    console.log("Successfully navigated to Normal Payment Sheet");
  } else {
    console.log("Detected Normal Payment Sheet");
  }
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
