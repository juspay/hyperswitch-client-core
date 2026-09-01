import type {TurboModule, CodegenTypes} from 'react-native';
import {TurboModuleRegistry} from 'react-native';

export interface Spec extends TurboModule {
  updateFieldState(rootTag: CodegenTypes.Int32, state: string): void;
  updateVaultFieldStates(statesJson: string): void;
  returnTokenizedValue(resultJson: string): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('HyperVaultModule');
