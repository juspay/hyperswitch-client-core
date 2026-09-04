import NativeHyperHeadless from '../specs/NativeHyperHeadless';
import type {PaymentExitResult} from '../specs/NativeHyperHeadless';

export type {PaymentExitResult};

/* Thin typed access layer over the HyperHeadless TurboModule, mirroring
   HyperModuleNative.ts for the sibling HyperModule. Optional chaining keeps
   platform bundles without the module (web) from throwing at import time;
   any spec drift between here and the native module is a type error. */
export const getPaymentSession = (
  rootTag: number,
  paymentIntentData: Object,
  defaultPaymentMethod: Object,
  savedPaymentMethods: Array<Object>,
  callback: (result: Object) => void,
): void => {
  NativeHyperHeadless?.getPaymentSession(
    rootTag,
    paymentIntentData,
    defaultPaymentMethod,
    savedPaymentMethods,
    callback,
  );
};

export const exitHeadless = (
  rootTag: number,
  result: PaymentExitResult,
): void => {
  NativeHyperHeadless?.exitHeadless(rootTag, result);
};

export const completePrefetch = (rootTag: number, data: Object): void => {
  NativeHyperHeadless?.completePrefetch(rootTag, data);
};
