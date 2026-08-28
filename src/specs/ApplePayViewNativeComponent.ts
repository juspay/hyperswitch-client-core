import type { HostComponent, ViewProps} from 'react-native';
import type { DirectEventHandler, Float } from 'react-native/Libraries/Types/CodegenTypes';
import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';

export interface NativeProps extends ViewProps {
  buttonType?: string;
  buttonStyle?: string;
  cornerRadius?: Float;
  onPaymentResultCallback?: DirectEventHandler<{}>;
}

export default codegenNativeComponent<NativeProps>('ApplePayView', {
  excludedPlatforms: ['android'],
}) as HostComponent<NativeProps>;
