import type {TurboModule} from 'react-native';
import {TurboModuleRegistry} from 'react-native';

/**
 * Codegen spec for the HyperHeadless TurboModule.
 *
 * Naming convention: Native<ModuleName>.ts — required by the RN codegen.
 * number → Double on Android; Object → ReadableMap; Array<Object> → ReadableArray.
 */
export interface Spec extends TurboModule {
  getPaymentSession(
    rootTag: number,
    defaultPaymentMethod: Object,
    lastUsedPaymentMethod: Object,
    allPaymentMethods: Array<Object>,
    callback: (result: Object) => void,
  ): void;

  exitHeadless(rootTag: number, status: string): void;
}

export default TurboModuleRegistry.get<Spec>('HyperHeadless');
