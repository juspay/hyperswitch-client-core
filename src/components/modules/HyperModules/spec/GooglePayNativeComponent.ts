import { codegenNativeComponent } from 'react-native';
import type {
  CodegenTypes,
  HostComponent,
  ViewProps,
} from 'react-native';

export interface NativeProps extends ViewProps {
  buttonType?: string;
  buttonStyle?: string;
  borderRadius?: CodegenTypes.Double;
  allowedPaymentMethods?: string;
}

export default codegenNativeComponent<NativeProps>('GooglePayView') as HostComponent<NativeProps>;