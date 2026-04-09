import React from 'react';
import { render } from '@testing-library/react-native';
import { themeContext, defaultValue, defaultSetter, make } from '../contexts/ThemeContext.bs.js';

jest.mock('../types/SdkTypes.bs.js', () => ({
  defaultAppearance: {
    colors: {},
    typography: {},
  },
}));

jest.mock('../hooks/LightDarkTheme.bs.js', () => ({
  useIsDarkMode: jest.fn(() => false),
}));

describe('ThemeContext', () => {
  describe('defaultValue', () => {
    it('is defined', () => {
      expect(defaultValue).toBeDefined();
    });

    it('has Light tag by default', () => {
      expect(defaultValue.TAG).toBe('Light');
    });

    it('has _0 property with appearance', () => {
      expect(defaultValue._0).toBeDefined();
    });
  });

  describe('defaultSetter', () => {
    it('is a function', () => {
      expect(typeof defaultSetter).toBe('function');
    });

    it('does not throw when called', () => {
      expect(() => defaultSetter()).not.toThrow();
    });

    it('accepts any argument without throwing', () => {
      expect(() => defaultSetter({})).not.toThrow();
      expect(() => defaultSetter(null)).not.toThrow();
    });
  });

  describe('themeContext', () => {
    it('is a React context', () => {
      expect(themeContext).toBeDefined();
      expect(themeContext.Provider).toBeDefined();
    });

    it('has default value as array with two elements', () => {
      expect(Array.isArray(themeContext._currentValue)).toBe(true);
    });
  });

  describe('make (ThemeContext component)', () => {
    it('is a function', () => {
      expect(typeof make).toBe('function');
    });

    it('renders children', () => {
      const mockAppearance = {
        theme: 'Light',
        colors: { primary: '#000' },
      };

      const { getByText } = render(
        React.createElement(
          make,
          { appearance: mockAppearance } as any,
          React.createElement('Text', {}, 'Test Child')
        )
      );

      expect(getByText('Test Child')).toBeDefined();
    });

    it('handles Dark theme', () => {
      const mockAppearance = {
        theme: 'Dark',
        colors: { primary: '#fff' },
      };

      const { getByText } = render(
        React.createElement(
          make,
          { appearance: mockAppearance } as any,
          React.createElement('Text', {}, 'Test Child')
        )
      );

      expect(getByText('Test Child')).toBeDefined();
    });

    it('handles Default theme in light mode', () => {
      const mockAppearance = {
        theme: 'Default',
        colors: {},
      };

      const { getByText } = render(
        React.createElement(
          make,
          { appearance: mockAppearance } as any,
          React.createElement('Text', {}, 'Test Child')
        )
      );

      expect(getByText('Test Child')).toBeDefined();
    });

    it('handles Default theme in dark mode', () => {
      const LightDarkTheme = require('../hooks/LightDarkTheme.bs.js');
      LightDarkTheme.useIsDarkMode.mockReturnValueOnce(true);

      const mockAppearance = {
        theme: 'Default',
        colors: {},
      };

      const { getByText } = render(
        React.createElement(
          make,
          { appearance: mockAppearance } as any,
          React.createElement('Text', {}, 'Test Child')
        )
      );

      expect(getByText('Test Child')).toBeDefined();
    });
  });
});
