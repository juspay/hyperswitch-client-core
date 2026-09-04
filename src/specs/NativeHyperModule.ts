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

export type ClearPrefetchCacheEvent = {
  sdkAuthorization: string;
};

export type UpdateIntentEvent = {
  rootTag?: CodegenTypes.Int32;
  sdkAuthorization?: string;
};

export type PaymentExitResult = {
  status: string;
  type?: string;
  code?: string;
  message?: string;
};

export interface Spec extends TurboModule {
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
    result: PaymentExitResult,
    reset: boolean,
  ): void;
  exitPaymentMethodManagement(
    rootTag: CodegenTypes.Int32,
    result: string,
    reset: boolean,
  ): void;
  exitWidgetPaymentsheet(
    rootTag: CodegenTypes.Int32,
    result: PaymentExitResult,
    reset: boolean,
  ): void;
  exitWidget(result: PaymentExitResult, widgetType: string): void;
  exitCardForm(result: string): void;
  onAddPaymentMethod(data: string): void;
  updateWidgetHeight(height: CodegenTypes.Int32): void;
  notifyWidgetPaymentResult(
    rootTag: CodegenTypes.Int32,
    result: PaymentExitResult,
  ): void;
  emitPaymentEvent(
    rootTag: CodegenTypes.Int32,
    eventType: string,
    payload: CodegenTypes.UnsafeObject,
  ): void;
  onUpdateIntentEvent(
    rootTag: CodegenTypes.Int32,
    eventType: string,
    result: PaymentExitResult,
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
  readonly clearPrefetchCache: CodegenTypes.EventEmitter<ClearPrefetchCacheEvent>;
  /* Drives the long-running headless task after its first startTask: the payload is the same
     props map the task launched with (native rebuilds it per request from LaunchOptions). */
  readonly headlessRequest: CodegenTypes.EventEmitter<CodegenTypes.UnsafeObject>;
}

export default TurboModuleRegistry.get<Spec>('HyperModule');
