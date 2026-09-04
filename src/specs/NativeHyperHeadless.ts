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

/* Wire contract: headless methods are keyed by rootTag only, the same key the payment
   and CVC widgets use. Android routes replies through single-slot waiters (one payment
   session at a time, so no keying is needed); iOS resolves the tag to the headless host
   that owns the call. sdkAuthorization never appears as a routing key; completePrefetch's
   data payload carries it as plain data. */
export interface Spec extends TurboModule {
  getPaymentSession(
    rootTag: CodegenTypes.Int32,
    paymentIntentData: CodegenTypes.UnsafeObject,
    defaultPaymentMethod: CodegenTypes.UnsafeObject,
    savedPaymentMethods: Array<CodegenTypes.UnsafeObject>,
    callback: (result: CodegenTypes.UnsafeObject) => void,
  ): void;
  exitHeadless(rootTag: CodegenTypes.Int32, result: PaymentExitResult): void;
  /* Completion signal for one payment's prefetch; the payload lives only in the
     shared JS PrefetchCache. Carries {sdkAuthorization} as data, not as a key. */
  completePrefetch(
    rootTag: CodegenTypes.Int32,
    data: CodegenTypes.UnsafeObject,
  ): void;
}

export default TurboModuleRegistry.get<Spec>('HyperHeadless');
