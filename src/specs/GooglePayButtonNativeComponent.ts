import type { HostComponent, ViewProps} from 'react-native';
import { Float } from 'react-native/Libraries/Types/CodegenTypes';
import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';

export interface NativeProps extends ViewProps {
  allowedPaymentMethods?: string;
  buttonType?: string;
  buttonStyle?: string;
  borderRadius?: Float;
}

export default codegenNativeComponent<NativeProps>('GooglePayButton', {
  excludedPlatforms: ['iOS'],
}) as HostComponent<NativeProps>;
