import { describe, it, expect } from '@jest/globals';

import type { Appearance } from '../../../core/types';
import { toVaultAppearance } from '../appearance';

const fromNative = {
  colors: {
    light: {
      primary: '#1A73E8',
      background: '#FFFFFF',
      componentBackground: '#F7F7F7',
      componentBorder: '#DDDDDD',
      componentText: '#101010',
      placeholderText: '#8A8A8A',
      error: '#D32F2F',
    },
    dark: {
      primary: '#8AB4F8',
      background: '#000000',
      componentBackground: '#1C1C1E',
      componentBorder: '#3A3A3C',
      componentText: '#F5F5F5',
      placeholderText: '#9E9E9E',
      error: '#EF5350',
    },
  },
  shapes: { borderRadius: 12, borderWidth: 1, inputHeight: 48, gap: 8 },
  font: {
    family: 'Inter',
    scale: 1.1,
    placeholderTextSizeAdjust: -1,
    errorTextSizeAdjust: -2,
  },
  labels: 'floating',
} as unknown as Appearance;

describe('the appearance a native SDK sends', () => {
  it('draws the form in the colours, shapes and type it asked for', () => {
    expect(toVaultAppearance([fromNative], 'light')).toEqual({
      variables: {
        colorPrimary: '#1A73E8',
        colorText: '#101010',
        colorTextPlaceholder: '#8A8A8A',
        colorBackground: '#F7F7F7',
        borderColor: '#DDDDDD',
        colorDanger: '#D32F2F',
        borderRadius: 12,
        borderWidth: 1,
        inputFieldHeight: 48,
        gap: 8,
        fontFamily: 'Inter',
        fontScale: 1.1,
        placeholderTextSizeAdjust: -1,
        errorTextSizeAdjust: -2,
      },
      labels: 'floating',
    });
  });

  it('uses the dark colours in the dark, and nothing else changes', () => {
    const dark = toVaultAppearance([fromNative], 'dark');
    const light = toVaultAppearance([fromNative], 'light');
    expect(dark?.variables?.colorText).toBe('#F5F5F5');
    expect(dark?.variables?.colorBackground).toBe('#1C1C1E');
    expect(dark?.variables?.borderRadius).toBe(light?.variables?.borderRadius);
    expect(dark?.labels).toBe(light?.labels);
  });

  it('falls back to the light colours when a form has only those', () => {
    const lightOnly = { colors: { light: fromNative.colors?.light } } as Appearance;
    expect(toVaultAppearance([lightOnly], 'dark')?.variables?.colorText).toBe('#101010');
  });

  it("takes the form's colours over the session's, key by key", () => {
    const session = {
      colors: { light: { componentText: '#111111', primary: '#222222' } },
    } as Appearance;
    const form = { colors: { light: { componentText: '#333333' } } } as Appearance;
    expect(toVaultAppearance([session, form], 'light')?.variables).toEqual({
      colorPrimary: '#222222',
      colorText: '#333333',
    });
  });

  it('draws with its own values rather than something a host made up', () => {
    const wrong = {
      colors: { light: { primary: 42, componentText: '#101010' } },
      shapes: { borderRadius: 'round', gap: 8 },
      labels: 'sideways',
    } as unknown as Appearance;
    expect(toVaultAppearance([wrong], 'light')).toEqual({
      variables: { colorText: '#101010', gap: 8 },
    });
  });

  it('is nothing at all when a form says nothing', () => {
    expect(toVaultAppearance([], 'light')).toBeUndefined();
    expect(toVaultAppearance([{} as Appearance], 'light')).toBeUndefined();
  });
});
