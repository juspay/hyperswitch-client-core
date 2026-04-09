import { renderHook } from '@testing-library/react-native';
import React from 'react';
import { convertFontToGoogleFontURL, useCustomFontFamily } from '../hooks/FontFamily.bs.js';
import { nativePropContext } from '../contexts/NativePropContext.bs.js';
import { lightRecord } from '../hooks/ThemebasedStyle.bs.js';

jest.mock('../utility/logics/Window.bs.js', () => ({
  useLink: jest.fn(() => 'idle'),
}));

jest.mock('react-native', () => ({
  Platform: {
    OS: 'web',
  },
  StyleSheet: {
    create: jest.fn((styles) => styles),
    hairlineWidth: 1,
  },
}));

const createMockNativeProp = (fontFamily: unknown = 'DefaultWeb') => ({
  configuration: {
    appearance: {
      theme: 'Light',
      colors: undefined,
      shapes: undefined,
      font: {
        family: fontFamily,
        scale: undefined,
        headingTextSizeAdjust: undefined,
        subHeadingTextSizeAdjust: undefined,
        placeholderTextSizeAdjust: undefined,
        buttonTextSizeAdjust: undefined,
        errorTextSizeAdjust: undefined,
        linkTextSizeAdjust: undefined,
        modalTextSizeAdjust: undefined,
        cardTextSizeAdjust: undefined,
      },
      primaryButton: undefined,
      googlePay: { buttonType: 'PLAIN', buttonStyle: undefined },
      applePay: { buttonType: 'plain', buttonStyle: undefined },
      locale: undefined,
      layout: 'Tab',
    },
  },
});

describe('FontFamily', () => {
  describe('convertFontToGoogleFontURL', () => {
    it('converts simple font name to title case with spaces', () => {
      const result = convertFontToGoogleFontURL('roboto');
      expect(result).toBe('Roboto');
    });

    it('converts underscore-separated font name to title case with spaces', () => {
      const result = convertFontToGoogleFontURL('open_sans');
      expect(result).toBe('Open Sans');
    });

    it('converts space-separated font name to title case', () => {
      const result = convertFontToGoogleFontURL('open sans');
      expect(result).toBe('Open Sans');
    });

    it('handles mixed separators (underscore and space)', () => {
      const result = convertFontToGoogleFontURL('my_custom_font');
      expect(result).toBe('My Custom Font');
    });

    it('handles already title-cased font name', () => {
      const result = convertFontToGoogleFontURL('Roboto');
      expect(result).toBe('Roboto');
    });

    it('handles multi-word font name with mixed case', () => {
      const result = convertFontToGoogleFontURL('OPEN SANS CONDENSED');
      expect(result).toBe('Open Sans Condensed');
    });

    it('handles font name with all lowercase', () => {
      const result = convertFontToGoogleFontURL('lato regular');
      expect(result).toBe('Lato Regular');
    });
  });

  describe('useCustomFontFamily', () => {
    const wrapperWithNativeProp = (nativeProp: unknown) => {
      return ({ children }: { children: React.ReactNode }) =>
        React.createElement(
          nativePropContext.Provider,
          { value: [nativeProp, jest.fn()] },
          children
        );
    };

    it('returns System for DefaultIOS font', () => {
      const mockNativeProp = createMockNativeProp('DefaultIOS');

      const { result } = renderHook(() => useCustomFontFamily(), {
        wrapper: wrapperWithNativeProp(mockNativeProp),
      });

      expect(result.current).toBe('System');
    });

    it('returns Roboto for DefaultAndroid font', () => {
      const mockNativeProp = createMockNativeProp('DefaultAndroid');

      const { result } = renderHook(() => useCustomFontFamily(), {
        wrapper: wrapperWithNativeProp(mockNativeProp),
      });

      expect(result.current).toBe('Roboto');
    });

    it('returns system font stack for DefaultWeb font', () => {
      const mockNativeProp = createMockNativeProp('DefaultWeb');

      const { result } = renderHook(() => useCustomFontFamily(), {
        wrapper: wrapperWithNativeProp(mockNativeProp),
      });

      expect(result.current).toBe(
        '-apple-system,BlinkMacSystemFont,"Segoe UI","Roboto","Helvetica Neue","Ubuntu",sans-serif'
      );
    });

    it('returns converted Google Font URL for custom font on web platform', () => {
      const mockNativeProp = createMockNativeProp({ TAG: 'CustomFont', _0: 'Open_Sans' });

      const { result } = renderHook(() => useCustomFontFamily(), {
        wrapper: wrapperWithNativeProp(mockNativeProp),
      });

      expect(result.current).toBe('Open Sans');
    });

    it('returns converted font name with proper title case', () => {
      const mockNativeProp = createMockNativeProp({ TAG: 'CustomFont', _0: 'lato_regular' });

      const { result } = renderHook(() => useCustomFontFamily(), {
        wrapper: wrapperWithNativeProp(mockNativeProp),
      });

      expect(result.current).toBe('Lato Regular');
    });
  });
});
