import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent'; //TODO : update the path to react-native in the latest version when available directly
import type { HostComponent, ViewProps } from 'react-native';
import type { Double } from 'react-native/Libraries/Types/CodegenTypes';

export interface NativeProps extends ViewProps {
  buttonType?: string;
  buttonStyle?: string;
  cornerRadius?: Double;
}

export default codegenNativeComponent<NativeProps>('ApplePayView') as HostComponent<NativeProps>;
