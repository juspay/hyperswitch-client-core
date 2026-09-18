import type {TurboModule, CodegenTypes} from 'react-native';
import {TurboModuleRegistry} from 'react-native';

/**
 * Codegen spec for the PMM-only TurboModule (`HyperPMMModule`).
 *
 * The standalone Payment Methods Management SDK ships without the payments
 * `HyperModule` class, so every native entry point its JS bundle can reach is
 * registered under its own module name. Payments JS never calls these
 * methods; `HyperModuleNative.ts` dual-dispatches the shared ones, so apps
 * carrying both flows keep working with either module present or absent.
 */

export type PaymentExitResult = {
  status: string;
  type?: string;
  code?: string;
  message?: string;
};

export type WidgetActionEvent = {
  actionType?: string;
  rootTag?: CodegenTypes.Int32;
  sdkAuthorization?: string;
  paymentToken?: string;
  billing?: string;
};

export interface Spec extends TurboModule {
  // --- Payment method management (sheet + embeddable widget) ---
  exitPaymentMethodManagement(
    rootTag: CodegenTypes.Int32,
    result: string,
    reset: boolean,
  ): void;
  notifyWidgetPaymentResult(
    rootTag: CodegenTypes.Int32,
    result: PaymentExitResult,
  ): void;

  // --- Payment events ---
  emitPaymentEvent(
    rootTag: CodegenTypes.Int32,
    eventType: string,
    payload: CodegenTypes.UnsafeObject,
  ): void;

  // --- Typed codegen EventEmitter (Native -> JS) ---
  // PMM's merchant-CTA confirm pipeline: the native widget emits
  // "triggerWidgetAction" and the PMM realm answers with
  // `notifyWidgetPaymentResult` / `exitPaymentMethodManagement`.
  readonly triggerWidgetAction: CodegenTypes.EventEmitter<WidgetActionEvent>;
}

export default TurboModuleRegistry.get<Spec>('HyperPMMModule');
