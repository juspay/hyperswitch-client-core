import type {TurboModule} from 'react-native';
import {TurboModuleRegistry} from 'react-native';

/**
 * Codegen spec for the HyperModule TurboModule.
 *
 * Naming convention: Native<ModuleName>.ts  — required by the RN codegen.
 * All number params map to Double on Android (Kotlin) and NSNumber on iOS.
 * All Object params map to ReadableMap; Array<Object> maps to ReadableArray.
 */
export interface Spec extends TurboModule {
  // --- EventEmitter (required for NativeEventEmitter support) ---
  addListener(eventName: string): void;
  removeListeners(count: number): void;

  // --- Generic message passing ---
  sendMessageToNative(message: string): void;

  // --- Google Pay (Android) ---
  launchGPay(requestObj: string, callback: (result: Object) => void): void;

  // --- Apple Pay (iOS; stubs on Android) ---
  launchApplePay(requestObj: string, callback: (result: Object) => void): void;
  startApplePay(requestObj: string, callback: (result: Object) => void): void;
  presentApplePay(requestObj: string, callback: (result: Object) => void): void;

  // --- Payment sheet ---
  exitPaymentsheet(rootTag: number, result: string, reset: boolean): void;
  exitPaymentMethodManagement(rootTag: number, result: string, reset: boolean): void;

  // --- Widget ---
  exitWidget(result: string, widgetType: string): void;
  exitCardForm(result: string): void;
  launchWidgetPaymentSheet(
    requestObj: string,
    callback: (result: Object) => void,
  ): void;
  exitWidgetPaymentsheet(rootTag: number, result: string, reset: boolean): void;
  updateWidgetHeight(height: number): void;
  notifyWidgetPaymentResult(rootTag: number, result: string): void;

  // --- Payment method management ---
  onAddPaymentMethod(data: string): void;

  // --- Payment events ---
  emitPaymentEvent(rootTag: number, eventType: string, payload: Object): void;
  onUpdateIntentEvent(rootTag: number, type: string, result: string): void;
  onPaymentConfirmButtonClick(
    rootTag: number,
    payload: string,
    callback: (shouldProceed: boolean) => void,
  ): void;

  // --- 3DS / DDC iframe bridge ---
  openIframeBridge(
    url: string,
    timeoutMs: number,
    callback: (result: string) => void,
  ): void;
}

export default TurboModuleRegistry.get<Spec>('HyperModule');
