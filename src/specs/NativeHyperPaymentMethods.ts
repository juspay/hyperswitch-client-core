import type { TurboModule, CodegenTypes } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export type CommandEvent = {
  rootTag: CodegenTypes.Int32;
  formId: string;
  commandId: string;
  name: string;
  elementType?: string;
  providerData?: string;
};

export interface Spec extends TurboModule {
  emitFieldEvent(
    rootTag: CodegenTypes.Int32,
    eventName: string,
    payload: CodegenTypes.UnsafeObject
  ): void;
  emitFormEvent(
    rootTag: CodegenTypes.Int32,
    eventName: string,
    payload: CodegenTypes.UnsafeObject
  ): void;

  readonly onCommand: CodegenTypes.EventEmitter<CommandEvent>;
}

export default TurboModuleRegistry.get<Spec>('HyperPaymentMethodsModule');
