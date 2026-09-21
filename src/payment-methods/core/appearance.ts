import { StyleSheet } from 'react-native';
import type { StyleProp, TextStyle, ViewStyle } from 'react-native';
import type { Appearance, ElementType, FieldStyles } from './types';

export function resolveFieldStyles(
  appearances: readonly Appearance[] | undefined,
  elementType: ElementType,
  own: FieldStyles | undefined
): FieldStyles {
  const layers = appearances ?? [];
  const container: StyleProp<ViewStyle>[] = [];
  const input: StyleProp<TextStyle>[] = [];

  for (const layer of layers) {
    if (layer.container) container.push(layer.container);
    if (layer.input) input.push(layer.input);
  }
  for (const layer of layers) {
    const scoped = layer.fields?.[elementType];
    if (scoped?.container) container.push(scoped.container);
    if (scoped?.input) input.push(scoped.input);
  }
  if (own?.container) container.push(own.container);
  if (own?.input) input.push(own.input);

  const styles: FieldStyles = {};
  if (container.length) styles.container = StyleSheet.flatten(container);
  if (input.length) styles.input = StyleSheet.flatten(input);
  return styles;
}
