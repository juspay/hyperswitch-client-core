import { View } from 'react-native';
import type { ElementType, FieldStyles } from '../core/types';

export function Placeholder({
  elementType,
  styles,
}: {
  elementType: ElementType;
  styles?: FieldStyles;
}) {
  return (
    <View
      accessibilityState={{ busy: true }}
      style={styles?.container}
      testID={`hs-placeholder-${elementType}`}
    />
  );
}
