import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';
import type { ViewProps } from 'react-native';
import type { Double } from 'react-native/Libraries/Types/CodegenTypes';

interface NativeProps extends ViewProps {
  buttonType?: string;
  buttonStyle?: string;
  cornerRadius?: Double;
}

export default codegenNativeComponent<NativeProps>('ApplePayView');
