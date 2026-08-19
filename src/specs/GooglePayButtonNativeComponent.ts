import type {CodegenTypes, HostComponent, ViewProps} from 'react-native';
import {codegenNativeComponent} from 'react-native';

export interface NativeProps extends ViewProps {
  allowedPaymentMethods?: string;
  buttonType?: string;
  buttonStyle?: string;
  borderRadius?: CodegenTypes.Float;
}

export default codegenNativeComponent<NativeProps>('GooglePayButton', {
  excludedPlatforms: ['iOS'],
}) as HostComponent<NativeProps>;
