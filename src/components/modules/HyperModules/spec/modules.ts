import { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  // Send message to native
  sendMessageToNative(message: string): void;
  
  // Apple Pay methods
  launchApplePay(requestObj: string, callback: (result: Object) => void): void;
  // Google Pay method
  launchGPay(requestObj: string, callback: (result: Object) => void): void;
  
  // Exit methods
  exitPaymentsheet(rootTag: number, result: string, reset: boolean): void;
  exitPaymentMethodManagement(rootTag: number, result: string, reset: boolean): void;
  exitWidget(result: string, widgetType: string): void;
  exitCardForm(result: string): void;
  exitWidgetPaymentsheet(rootTag: number, result: string, reset: boolean): void;
  
  // Widget methods
  launchWidgetPaymentSheet(requestObj: string, callback: (result: Object) => void): void;
  updateWidgetHeight(height: number): void;
  onAddPaymentMethod(data: string): void;
}
const NativeHyperswitchSdk = TurboModuleRegistry.getEnforcing<Spec>('HyperModules');

export const sendMessageToNative = NativeHyperswitchSdk.sendMessageToNative;
export const launchApplePay = NativeHyperswitchSdk.launchApplePay;
export const launchGPay = NativeHyperswitchSdk.launchGPay;
export const exitPaymentsheet = NativeHyperswitchSdk.exitPaymentsheet;
export const exitPaymentMethodManagement = NativeHyperswitchSdk.exitPaymentMethodManagement;
export const exitWidget = NativeHyperswitchSdk.exitWidget;
export const exitCardForm = NativeHyperswitchSdk.exitCardForm;
export const launchWidgetPaymentSheet = NativeHyperswitchSdk.launchWidgetPaymentSheet;
export const onAddPaymentMethod = NativeHyperswitchSdk.onAddPaymentMethod;
export const exitWidgetPaymentsheet = NativeHyperswitchSdk.exitWidgetPaymentsheet;
export const updateWidgetHeight = NativeHyperswitchSdk.updateWidgetHeight;

export default NativeHyperswitchSdk;
