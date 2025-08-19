import {TurboModule} from 'react-native';
import {TurboModuleRegistry} from 'react-native';

export interface Spec extends TurboModule {
  getModules(): Array<string>;
}
export default TurboModuleRegistry.getEnforcing<Spec>('HyperModules');
