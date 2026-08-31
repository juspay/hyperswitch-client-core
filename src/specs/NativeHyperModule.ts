import type {TurboModule, CodegenTypes} from 'react-native';
import {TurboModuleRegistry} from 'react-native';

export type PaymentResultEvent = {
  paymentMethodData?: string;
  clientSecret?: string;
  paymentMethodType?: string;
  publishableKey?: string;
  error?: string;
  confirm?: boolean;
};

export type WidgetActionEvent = {
  actionType?: string;
  rootTag?: CodegenTypes.Int32;
  sdkAuthorization?: string;
  paymentToken?: string;
  billing?: string;
};

export type UpdateIntentEvent = {
  rootTag?: CodegenTypes.Int32;
  sdkAuthorization?: string;
};

export interface Spec extends TurboModule {
  // --- EventEmitter plumbing required by the native RCTEventEmitter path ---
  // (must stay in sync with the native HyperModule spec; NativeEventEmitter
  //  subscriptions and the codegen EventEmitter wiring call these on iOS).
  addListener(eventName: string): void;
  removeListeners(count: number): void;

  sendMessageToNative(message: string): void;

  launchApplePay(
    requestObj: string,
    callback: (result: CodegenTypes.UnsafeObject) => void,
  ): void;
  startApplePay(
    requestObj: string,
    callback: (result: CodegenTypes.UnsafeObject) => void,
  ): void;
  presentApplePay(
    requestObj: string,
    callback: (result: CodegenTypes.UnsafeObject) => void,
  ): void;
  launchGPay(
    requestObj: string,
    callback: (result: CodegenTypes.UnsafeObject) => void,
  ): void;
  exitPaymentsheet(
    rootTag: CodegenTypes.Int32,
    result: string,
    reset: boolean,
  ): void;
  exitPaymentMethodManagement(
    rootTag: CodegenTypes.Int32,
    result: string,
    reset: boolean,
  ): void;
  exitWidgetPaymentsheet(
    rootTag: CodegenTypes.Int32,
    result: string,
    reset: boolean,
  ): void;
  exitWidget(result: string, widgetType: string): void;
  exitCardForm(result: string): void;
  launchWidgetPaymentSheet(
    requestObj: string,
    callback: (result: CodegenTypes.UnsafeObject) => void,
  ): void;
  onAddPaymentMethod(data: string): void;
  updateWidgetHeight(height: CodegenTypes.Int32): void;
  notifyWidgetPaymentResult(
    rootTag: CodegenTypes.Int32,
    result: string,
  ): void;
  emitPaymentEvent(
    rootTag: CodegenTypes.Int32,
    eventType: string,
    payload: CodegenTypes.UnsafeObject,
  ): void;
  onUpdateIntentEvent(
    rootTag: CodegenTypes.Int32,
    eventType: string,
    result: string,
  ): void;
  onPaymentConfirmButtonClick(
    rootTag: CodegenTypes.Int32,
    payload: string,
    callback: (shouldProceed: boolean) => void,
  ): void;
  openIframeBridge(
    url: string,
    timeoutMs: CodegenTypes.Int32,
    callback: (result: string) => void,
  ): void;

  readonly confirm: CodegenTypes.EventEmitter<PaymentResultEvent>;
  readonly widget: CodegenTypes.EventEmitter<PaymentResultEvent>;
  readonly confirmEC: CodegenTypes.EventEmitter<PaymentResultEvent>;
  readonly triggerWidgetAction: CodegenTypes.EventEmitter<WidgetActionEvent>;
  readonly updateIntentInit: CodegenTypes.EventEmitter<UpdateIntentEvent>;
  readonly updateIntentComplete: CodegenTypes.EventEmitter<UpdateIntentEvent>;
}

export default TurboModuleRegistry.get<Spec>('HyperModule');
