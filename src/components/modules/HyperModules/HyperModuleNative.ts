/**
 * JS access point to the HyperModule TurboModule.
 *
 * The Spec (with typed codegen EventEmitters) lives in spec/NativeHyperModule.ts.
 * Every export degrades to a no-op when the native module is absent (e.g. jest,
 * web) and falls back to RCTDeviceEventEmitter on old-arch hosts so the same
 * client-core works for both bridgeless and legacy React Native.
 */
import {NativeEventEmitter} from 'react-native';
import NativeHyperModule from './spec/NativeHyperModule';
import type {
  PaymentResultEvent,
  WidgetActionEvent,
  UpdateIntentEvent,
} from './spec/NativeHyperModule';

export type {PaymentResultEvent, WidgetActionEvent, UpdateIntentEvent};

const noop = (): void => {};
const noopUnsubscribe = (): void => {};

/**
 * Single legacy RCTDeviceEventEmitter-backed emitter used on old-arch hosts
 * where the codegen EventEmitter isn't plumbed in.
 */
const legacyEmitter: NativeEventEmitter | null = (() => {
  try {
    return new NativeEventEmitter(NativeHyperModule as any);
  } catch (_e) {
    return null;
  }
})();

const subscribeViaLegacy = <T>(
  eventName: string,
  handler: (payload: T) => void,
): (() => void) => {
  if (!legacyEmitter) {
    return noopUnsubscribe;
  }
  const sub = legacyEmitter.addListener(eventName, handler);
  return () => sub.remove();
};

/**
 * Attach a handler to a codegen typed EventEmitter when available, otherwise
 * fall back to the legacy RCTDeviceEventEmitter channel.
 *
 * The codegen emitter path is bridgeless-compatible; the legacy path is the
 * only available route on Paper.
 */
const subscribe = <T>(
  attach:
    | ((handler: (payload: T) => void) => {remove: () => void})
    | undefined,
  legacyEventName: string,
  handler: (payload: T) => void,
): (() => void) => {
  if (NativeHyperModule && attach) {
    try {
      const sub = attach.call(NativeHyperModule, handler);
      return () => sub.remove();
    } catch (_e) {
      // fall through to legacy
    }
  }
  return subscribeViaLegacy(legacyEventName, handler);
};

// --- Generic message passing ---

export const sendMessageToNative = (message: string): void => {
  NativeHyperModule?.sendMessageToNative(message);
};

// --- Google Pay / Apple Pay ---

export const launchGPay = (
  requestObj: string,
  callback: (result: Object) => void,
): void => {
  NativeHyperModule?.launchGPay(requestObj, callback);
};

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

// --- Payment sheet / widget lifecycle ---

export const exitPaymentsheet = (
  rootTag: number,
  result: string,
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
  result: string,
  reset: boolean,
): void => {
  NativeHyperModule?.exitWidgetPaymentsheet(rootTag, result, reset);
};

export const exitWidget = (result: string, widgetType: string): void => {
  NativeHyperModule?.exitWidget(result, widgetType);
};

export const exitCardForm = (result: string): void => {
  NativeHyperModule?.exitCardForm(result);
};

export const launchWidgetPaymentSheet = (
  requestObj: string,
  callback: (result: Object) => void,
): void => {
  NativeHyperModule?.launchWidgetPaymentSheet(requestObj, callback);
};

export const updateWidgetHeight = (height: number): void => {
  NativeHyperModule?.updateWidgetHeight(height);
};

export const onAddPaymentMethod = (data: string): void => {
  NativeHyperModule?.onAddPaymentMethod(data);
};

export const notifyWidgetPaymentResult = (
  rootTag: number,
  result: string,
): void => {
  NativeHyperModule?.notifyWidgetPaymentResult(rootTag, result);
};

// --- Payment events (JS -> Native) ---

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
  result: string,
): void => {
  NativeHyperModule?.onUpdateIntentEvent(rootTag, eventType, result);
};

export const onPaymentConfirmButtonClick = (
  rootTag: number,
  payload: string,
  callback: (shouldProceed: boolean) => void,
): void => {
  NativeHyperModule?.onPaymentConfirmButtonClick(rootTag, payload, callback);
};

// --- 3DS / DDC iframe bridge ---

export const openIframeBridge = (
  url: string,
  timeoutMs: number,
  callback: (result: string) => void,
): void => {
  NativeHyperModule?.openIframeBridge(url, timeoutMs, callback);
};

// --- Native -> JS event subscriptions ---
// Each prefers the codegen typed EventEmitter, falling back to the legacy
// RCTDeviceEventEmitter channel on old-arch hosts. Returns an unsubscribe
// thunk; never throws.

export const subscribeConfirm = (
  handler: (payload: PaymentResultEvent) => void,
): (() => void) => subscribe(NativeHyperModule?.confirm, 'confirm', handler);

export const subscribeWidget = (
  handler: (payload: PaymentResultEvent) => void,
): (() => void) => subscribe(NativeHyperModule?.widget, 'widget', handler);

export const subscribeConfirmEC = (
  handler: (payload: PaymentResultEvent) => void,
): (() => void) => subscribe(NativeHyperModule?.confirmEC, 'confirmEC', handler);

export const subscribeTriggerWidgetAction = (
  handler: (payload: WidgetActionEvent) => void,
): (() => void) =>
  subscribe(NativeHyperModule?.triggerWidgetAction, 'triggerWidgetAction', handler);

export const subscribeUpdateIntentInit = (
  handler: (payload: UpdateIntentEvent) => void,
): (() => void) =>
  subscribe(NativeHyperModule?.updateIntentInit, 'updateIntentInit', handler);

export const subscribeUpdateIntentComplete = (
  handler: (payload: UpdateIntentEvent) => void,
): (() => void) =>
  subscribe(NativeHyperModule?.updateIntentComplete, 'updateIntentComplete', handler);

export default {
  sendMessageToNative,
  launchGPay,
  launchApplePay,
  startApplePay,
  presentApplePay,
  exitPaymentsheet,
  exitPaymentMethodManagement,
  exitWidgetPaymentsheet,
  exitWidget,
  exitCardForm,
  launchWidgetPaymentSheet,
  updateWidgetHeight,
  onAddPaymentMethod,
  notifyWidgetPaymentResult,
  emitPaymentEvent,
  onUpdateIntentEvent,
  onPaymentConfirmButtonClick,
  openIframeBridge,
  subscribeConfirm,
  subscribeWidget,
  subscribeConfirmEC,
  subscribeTriggerWidgetAction,
  subscribeUpdateIntentInit,
  subscribeUpdateIntentComplete,
};
