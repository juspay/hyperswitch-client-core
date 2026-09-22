import type {TurboModule, CodegenTypes} from 'react-native';
import {TurboModuleRegistry} from 'react-native';

/* Codegen does not follow imports between spec files; these mirror the shapes in
 * NativeHyperModule.ts. */
export type WidgetActionEvent = {
  actionType?: string;
  rootTag?: CodegenTypes.Int32;
  sdkAuthorization?: string;
  paymentToken?: string;
  billing?: string;
};

export type PaymentExitResult = {
  status: string;
  type?: string;
  code?: string;
  message?: string;
};

/**
 * The Payment Methods Management realm's module. PMM surfaces run in their own
 * React host (entry `index.payment-method-management.js`, root component
 * `hyperPMM`, bundle `hyperswitch-payment-method-management.bundle`) — the
 * host only ever needs this module, never the
 * payments `HyperModule`. Same contract shape, PMM-scoped.
 */
export interface Spec extends TurboModule {
  exitPaymentMethodManagement(
    rootTag: CodegenTypes.Int32,
    result: string,
    reset: boolean,
  ): void;
  notifyWidgetPaymentResult(
    rootTag: CodegenTypes.Int32,
    result: PaymentExitResult,
  ): void;
  emitPaymentEvent(
    rootTag: CodegenTypes.Int32,
    eventType: string,
    payload: CodegenTypes.UnsafeObject,
  ): void;

  readonly triggerWidgetAction: CodegenTypes.EventEmitter<WidgetActionEvent>;
}

export default TurboModuleRegistry.get<Spec>('HyperPMMModule');
