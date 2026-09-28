import NativeHyperPMMModule from '../../specs/NativeHyperPMMModule';
import type {
  PaymentExitResult,
  WidgetActionEvent,
} from '../../specs/NativeHyperPMMModule';


export const exitPaymentMethodManagement = (
  rootTag: number,
  result: string,
  reset: boolean,
): void => {
  NativeHyperPMMModule?.exitPaymentMethodManagement(rootTag, result, reset);
};

export const notifyWidgetPaymentResult = (
  rootTag: number,
  result: PaymentExitResult,
): void => {
  NativeHyperPMMModule?.notifyWidgetPaymentResult(rootTag, result);
};

export const subscribeTriggerWidgetAction = (
  handler: (payload: WidgetActionEvent) => void,
): (() => void) => {
  const attach = NativeHyperPMMModule?.triggerWidgetAction;
  if (!NativeHyperPMMModule || !attach) {
    return () => {};
  }
  const subscription = attach.call(NativeHyperPMMModule, handler);
  return () => subscription.remove();
};
