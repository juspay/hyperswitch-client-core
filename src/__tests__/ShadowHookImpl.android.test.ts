import { renderHook } from '@testing-library/react-native';

jest.mock('react-native', () => ({}));

const { useGetShadowStyle } = require('../hooks/ShadowHook/ShadowHookImpl.android.bs.js');

describe('ShadowHookImpl.android', () => {
  describe('useGetShadowStyle', () => {
    it('exists as a function', () => {
      expect(useGetShadowStyle).toBeDefined();
      expect(typeof useGetShadowStyle).toBe('function');
    });

    it('returns an object with elevation property', () => {
      const { result } = renderHook(() => useGetShadowStyle(4, undefined));

      expect(result.current).toHaveProperty('elevation');
    });

    it('returns elevation matching shadowIntensity', () => {
      const { result } = renderHook(() => useGetShadowStyle(8, undefined));

      expect(result.current.elevation).toBe(8);
    });

    it('handles shadowIntensity of 0', () => {
      const { result } = renderHook(() => useGetShadowStyle(0, undefined));

      expect(result.current.elevation).toBe(0);
    });

    it('handles negative shadowIntensity values', () => {
      const { result } = renderHook(() => useGetShadowStyle(-5, undefined));

      expect(result.current.elevation).toBe(-5);
    });

    it('handles large shadowIntensity values', () => {
      const { result } = renderHook(() => useGetShadowStyle(100, undefined));

      expect(result.current.elevation).toBe(100);
    });

    it('handles floating point shadowIntensity', () => {
      const { result } = renderHook(() => useGetShadowStyle(4.5, undefined));

      expect(result.current.elevation).toBe(4.5);
    });

    it('ignores second parameter (param)', () => {
      const { result: result1 } = renderHook(() => useGetShadowStyle(5, undefined));
      const { result: result2 } = renderHook(() => useGetShadowStyle(5, 'black'));
      const { result: result3 } = renderHook(() => useGetShadowStyle(5, { color: 'red' }));

      expect(result1.current.elevation).toBe(5);
      expect(result2.current.elevation).toBe(5);
      expect(result3.current.elevation).toBe(5);
    });

    it('returns consistent results for same shadowIntensity', () => {
      const { result: result1 } = renderHook(() => useGetShadowStyle(10, undefined));
      const { result: result2 } = renderHook(() => useGetShadowStyle(10, undefined));

      expect(result1.current.elevation).toBe(result2.current.elevation);
    });

    it('returns object with only elevation property', () => {
      const { result } = renderHook(() => useGetShadowStyle(4, undefined));

      const keys = Object.keys(result.current);
      expect(keys).toHaveLength(1);
      expect(keys[0]).toBe('elevation');
    });

    it('handles shadowIntensity of 1', () => {
      const { result } = renderHook(() => useGetShadowStyle(1, undefined));

      expect(result.current.elevation).toBe(1);
    });

    it('handles very small positive shadowIntensity', () => {
      const { result } = renderHook(() => useGetShadowStyle(0.001, undefined));

      expect(result.current.elevation).toBeCloseTo(0.001);
    });
  });
});
