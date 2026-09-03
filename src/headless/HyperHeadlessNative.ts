import NativeHyperHeadless from '../specs/NativeHyperHeadless';
import type {PaymentExitResult} from '../specs/NativeHyperHeadless';

export type {PaymentExitResult};

/* Thin typed access layer over the HyperHeadless TurboModule, mirroring
   HyperModuleNative.ts for the sibling HyperModule. Optional chaining keeps
   platform bundles without the module (web) from throwing at import time;
   any spec drift between here and the native module is a type error. */
export const getPaymentSession = (
  sdkAuthorization: string,
  paymentIntentData: Object,
  defaultPaymentMethod: Object,
  savedPaymentMethods: Array<Object>,
  callback: (result: Object) => void,
): void => {
  NativeHyperHeadless?.getPaymentSession(
    sdkAuthorization,
    paymentIntentData,
    defaultPaymentMethod,
    savedPaymentMethods,
    callback,
  );
};

export const exitHeadless = (
  sdkAuthorization: string,
  result: PaymentExitResult,
): void => {
  NativeHyperHeadless?.exitHeadless(sdkAuthorization, result);
};

export const completePrefetch = (data: Object): void => {
  NativeHyperHeadless?.completePrefetch(data);
};
