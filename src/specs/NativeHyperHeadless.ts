import type {TurboModule, CodegenTypes} from 'react-native';
import {TurboModuleRegistry} from 'react-native';

// Same shape as PaymentExitResult in NativeHyperModule.ts, declared locally
// because codegen resolves types per spec file and cannot follow imports.
// do not remove this.
export type PaymentExitResult = {
  status: string;
  type?: string;
  code?: string;
  message?: string;
};

export interface Spec extends TurboModule {
  getPaymentSession(
    rootTag: CodegenTypes.Int32,
    paymentIntentData: CodegenTypes.UnsafeObject,
    defaultPaymentMethod: CodegenTypes.UnsafeObject,
    savedPaymentMethods: Array<CodegenTypes.UnsafeObject>,
    callback: (result: CodegenTypes.UnsafeObject) => void,
  ): void;
  exitHeadless(rootTag: CodegenTypes.Int32, result: PaymentExitResult): void;
}

export default TurboModuleRegistry.get<Spec>('HyperHeadless');
