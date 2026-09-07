import NativeHyperModule from '../../specs/NativeHyperModule';
import type {
  PaymentResultEvent,
  WidgetActionEvent,
  UpdateIntentEvent,
  PaymentExitResult,
} from '../../specs/NativeHyperModule';

export type {
  PaymentResultEvent,
  WidgetActionEvent,
  UpdateIntentEvent,
  PaymentExitResult,
};

const noop = () => {};

export const launchApplePay = (
  requestObj: string,
  callback: (result: Object) => void,
): void => {
  NativeHyperModule?.launchApplePay(requestObj, callback);
};

export const startApplePay = (
  requestObj: string,
  callback: (result: Object) => void,
): void => {
  NativeHyperModule?.startApplePay(requestObj, callback);
};

export const presentApplePay = (
  requestObj: string,
  callback: (result: Object) => void,
): void => {
  NativeHyperModule?.presentApplePay(requestObj, callback);
};

export const launchGPay = (
  requestObj: string,
  callback: (result: Object) => void,
): void => {
  NativeHyperModule?.launchGPay(requestObj, callback);
};

export const exitPaymentsheet = (
  rootTag: number,
  result: PaymentExitResult,
  reset: boolean,
): void => {
  NativeHyperModule?.exitPaymentsheet(rootTag, result, reset);
};

export const exitPaymentMethodManagement = (
  rootTag: number,
  result: string,
  reset: boolean,
): void => {
  NativeHyperModule?.exitPaymentMethodManagement(rootTag, result, reset);
};

export const exitWidgetPaymentsheet = (
  rootTag: number,
  result: PaymentExitResult,
  reset: boolean,
): void => {
  NativeHyperModule?.exitWidgetPaymentsheet(rootTag, result, reset);
};

export const exitWidget = (
  result: PaymentExitResult,
  widgetType: string,
): void => {
  NativeHyperModule?.exitWidget(result, widgetType);
};

export const exitCardForm = (result: string): void => {
  NativeHyperModule?.exitCardForm(result);
};

export const onAddPaymentMethod = (data: string): void => {
  NativeHyperModule?.onAddPaymentMethod(data);
};

export const updateWidgetHeight = (height: number): void => {
  NativeHyperModule?.updateWidgetHeight(height);
};

export const notifyWidgetPaymentResult = (
  rootTag: number,
  result: PaymentExitResult,
): void => {
  NativeHyperModule?.notifyWidgetPaymentResult(rootTag, result);
};

export const emitPaymentEvent = (
  rootTag: number,
  eventType: string,
  payload: Object,
): void => {
  NativeHyperModule?.emitPaymentEvent(rootTag, eventType, payload);
};

export const onUpdateIntentEvent = (
  rootTag: number,
  eventType: string,
  result: PaymentExitResult,
): void => {
  NativeHyperModule?.onUpdateIntentEvent(rootTag, eventType, result);
};

export const openIframeBridge = (
  url: string,
  timeoutMs: number,
  callback: (result: string) => void,
): void => {
  NativeHyperModule?.openIframeBridge(url, timeoutMs, callback);
};

const subscribe = <T>(
  attach: ((handler: (payload: T) => void) => {remove: () => void}) | undefined,
  handler: (payload: T) => void,
): (() => void) => {
  if (!NativeHyperModule || !attach) {
    return noop;
  }
  const subscription = attach.call(NativeHyperModule, handler);
  return () => subscription.remove();
};

export const subscribeConfirm = (
  handler: (payload: PaymentResultEvent) => void,
): (() => void) => subscribe(NativeHyperModule?.confirm, handler);

export const subscribeWidget = (
  handler: (payload: PaymentResultEvent) => void,
): (() => void) => subscribe(NativeHyperModule?.widget, handler);

export const subscribeConfirmEC = (
  handler: (payload: PaymentResultEvent) => void,
): (() => void) => subscribe(NativeHyperModule?.confirmEC, handler);

export const subscribeTriggerWidgetAction = (
  handler: (payload: WidgetActionEvent) => void,
): (() => void) => subscribe(NativeHyperModule?.triggerWidgetAction, handler);

export const subscribeUpdateIntentInit = (
  handler: (payload: UpdateIntentEvent) => void,
): (() => void) => subscribe(NativeHyperModule?.updateIntentInit, handler);

export const subscribeUpdateIntentComplete = (
  handler: (payload: UpdateIntentEvent) => void,
): (() => void) => subscribe(NativeHyperModule?.updateIntentComplete, handler);
