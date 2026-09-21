import type {TurboModule, CodegenTypes} from 'react-native';
import {TurboModuleRegistry} from 'react-native';

export type TokeniseEvent = {
  rootTag?: CodegenTypes.Int32;
};

export interface Spec extends TurboModule {
  readonly tokenise: CodegenTypes.EventEmitter<TokeniseEvent>;
  returnTokenResult(
    rootTag: CodegenTypes.Int32,
    result: CodegenTypes.UnsafeObject,
  ): void;
}

export default TurboModuleRegistry.get<Spec>('PaymentMethodModule');
