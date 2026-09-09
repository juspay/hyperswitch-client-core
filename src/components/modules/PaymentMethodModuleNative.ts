import NativePaymentMethodModule from '../../specs/NativePaymentMethodModule';
import type {TokeniseEvent} from '../../specs/NativePaymentMethodModule';

export type {TokeniseEvent};

const noop = () => {};

export const subscribeTokenise = (
  handler: (payload: TokeniseEvent) => void,
): (() => void) => {
  if (!NativePaymentMethodModule?.tokenise) {
    return noop;
  }
  const subscription = NativePaymentMethodModule.tokenise(handler);
  return () => subscription.remove();
};

export const returnTokenResult = (rootTag: number, result: Object): void => {
  NativePaymentMethodModule?.returnTokenResult(rootTag, result);
};
