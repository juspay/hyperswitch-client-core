import NativeHyperHeadless from '../../specs/NativeHyperHeadless';
import type {PaymentExitResult} from '../../specs/NativeHyperHeadless';

export type {PaymentExitResult};

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
