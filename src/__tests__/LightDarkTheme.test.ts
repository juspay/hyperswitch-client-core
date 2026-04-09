import { renderHook } from '@testing-library/react-native';
import React from 'react';

jest.mock('react-native', () => ({
  useColorScheme: jest.fn(),
}));

const mockUseColorScheme = require('react-native').useColorScheme as jest.MockedFunction<() => 'light' | 'dark' | null>;

const { useIsDarkMode } = require('../hooks/LightDarkTheme.bs.js');

describe('LightDarkTheme', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('useIsDarkMode', () => {
    it('returns false when color scheme is light', () => {
      mockUseColorScheme.mockReturnValue('light');
      
      const { result } = renderHook(() => useIsDarkMode());
      
      expect(result.current).toBe(false);
    });

    it('returns true when color scheme is dark', () => {
      mockUseColorScheme.mockReturnValue('dark');
      
      const { result } = renderHook(() => useIsDarkMode());
      
      expect(result.current).toBe(true);
    });

    it('returns false when color scheme is null (defaults to light)', () => {
      mockUseColorScheme.mockReturnValue(null);
      
      const { result } = renderHook(() => useIsDarkMode());
      
      expect(result.current).toBe(false);
    });
  });
});
