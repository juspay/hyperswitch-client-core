import type {TurboModule} from 'react-native';
import {TurboModuleRegistry} from 'react-native';

/**
 * All result objects returned from native must be plain JSON objects.
 * Avoid using `Object` — use Record<string, unknown> for proper typing.
 */
export interface Spec extends TurboModule {
  sendMessageToNative(message: string): void;

  launchApplePay(
    requestObj: string,
    callback: (result: Record<string, unknown>) => void,
  ): void;

  startApplePay(
    requestObj: string,
    callback: (result: Record<string, unknown>) => void,
  ): void;

  presentApplePay(
    requestObj: string,
    callback: (result: Record<string, unknown>) => void,
  ): void;

  launchGPay(
    requestObj: string,
    callback: (result: Record<string, unknown>) => void,
  ): void;

  exitPaymentsheet(rootTag: number, result: string, reset: boolean): void;

  exitPaymentMethodManagement(
    rootTag: number,
    result: string,
    reset: boolean,
  ): void;

  exitWidget(result: string, widgetType: string): void;

  exitCardForm(result: string): void;

  exitWidgetPaymentsheet(rootTag: number, result: string, reset: boolean): void;

  launchWidgetPaymentSheet(
    requestObj: string,
    callback: (result: Record<string, unknown>) => void,
  ): void;

  updateWidgetHeight(height: number): void;

  onAddPaymentMethod(data: string): void;
}

/**
 * DO NOT use getEnforcing() because you want silent fallback.
 * This allows Turbo → Legacy fallback safely.
 * This allows the TurboModule to be optional, and the app can still run without it without crashing.
 */
const TurboModule = TurboModuleRegistry.get<Spec>('HyperModules');

export default TurboModule;
