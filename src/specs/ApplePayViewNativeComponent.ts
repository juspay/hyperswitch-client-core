import type {CodegenTypes, HostComponent, ViewProps} from 'react-native';
import {codegenNativeComponent} from 'react-native';

export interface NativeProps extends ViewProps {
  buttonType?: string;
  buttonStyle?: string;
  cornerRadius?: CodegenTypes.Float;
  onPaymentResultCallback?: CodegenTypes.DirectEventHandler<{}>;
}

export default codegenNativeComponent<NativeProps>('ApplePayView', {
  excludedPlatforms: ['android'],
}) as HostComponent<NativeProps>;
