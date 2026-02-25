import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';
import type { HostComponent, ViewProps } from 'react-native';
import type { Double } from 'react-native/Libraries/Types/CodegenTypes';

export interface NativeProps extends ViewProps {
  buttonType?: string;
  buttonStyle?: string;
  borderRadius?: Double;
  allowedPaymentMethods?: string;
}

export default codegenNativeComponent<NativeProps>('GooglePayView') as HostComponent<NativeProps>;