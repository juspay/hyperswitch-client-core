import type {TurboModule, CodegenTypes} from 'react-native';
import {TurboModuleRegistry} from 'react-native';

export interface Spec extends TurboModule {
  getPaymentSession(
    rootTag: CodegenTypes.Int32,
    paymentIntentData: CodegenTypes.UnsafeObject,
    defaultPaymentMethod: CodegenTypes.UnsafeObject,
    savedPaymentMethods: Array<CodegenTypes.UnsafeObject>,
    callback: (result: CodegenTypes.UnsafeObject) => void,
  ): void;
  exitHeadless(rootTag: CodegenTypes.Int32, result: string): void;
}

export default TurboModuleRegistry.get<Spec>('HyperHeadless');
