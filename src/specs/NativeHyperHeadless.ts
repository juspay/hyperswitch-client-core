import type {TurboModule, CodegenTypes} from 'react-native';
import {TurboModuleRegistry} from 'react-native';

/* Same shape as PaymentExitResult in NativeHyperModule.ts, declared locally
   because codegen resolves types per spec file and cannot follow imports.
   Do not remove this. */
export type PaymentExitResult = {
  status: string;
  type?: string;
  code?: string;
  message?: string;
};

/* Wire contract: headless requests are keyed by sdkAuthorization (the native
   request/confirmation registries and the JS PrefetchCache are all auth-keyed).
   rootTag rides along on exitHeadless for iOS's CVC-widget view lookup; Android
   ignores it. The result is a typed PaymentExitResult object (as in Main's spec). */
export interface Spec extends TurboModule {
  getPaymentSession(
    sdkAuthorization: string,
    paymentIntentData: CodegenTypes.UnsafeObject,
    defaultPaymentMethod: CodegenTypes.UnsafeObject,
    savedPaymentMethods: Array<CodegenTypes.UnsafeObject>,
    callback: (result: CodegenTypes.UnsafeObject) => void,
  ): void;
  exitHeadless(
    sdkAuthorization: string,
    rootTag: CodegenTypes.Int32,
    result: PaymentExitResult,
  ): void;
  /* Completion signal for one payment's prefetch; the payload lives only in the
     shared JS PrefetchCache. Carries {sdkAuthorization}. */
  completePrefetch(data: CodegenTypes.UnsafeObject): void;
}

export default TurboModuleRegistry.get<Spec>('HyperHeadless');
