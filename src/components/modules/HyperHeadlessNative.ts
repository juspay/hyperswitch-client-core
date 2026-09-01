import NativeHyperHeadless from '../../specs/NativeHyperHeadless';
import type {PaymentExitResult} from '../../specs/NativeHyperHeadless';

export type {PaymentExitResult};

/* Headless requests are keyed by sdkAuthorization; rootTag rides along on exit
   for iOS's CVC-widget lookup. The result is a typed PaymentExitResult object. */
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
  rootTag: number,
  result: PaymentExitResult,
): void => {
  NativeHyperHeadless?.exitHeadless(sdkAuthorization, rootTag, result);
};

export const completePrefetch = (data: Object): void => {
  NativeHyperHeadless?.completePrefetch(data);
};
