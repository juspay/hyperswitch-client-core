import { renderHook } from '@testing-library/react-native';

jest.mock('react-native', () => ({
  processColor: (color: string) => {
    if (color === 'black') return 0xFF000000;
    if (color === 'red') return 0xFFFF0000;
    if (color === 'blue') return 0xFF0000FF;
    if (color === 'white') return 0xFFFFFFFF;
    if (color === '#006DF9') return 0xFF006DF9;
    return 0xFF000000;
  },
}));

const { useGetShadowStyle } = require('../hooks/ShadowHook/ShadowHookImpl.web.bs.js');
const { useGetShadowStyle: useGetShadowStyleWrapper } = require('../hooks/ShadowHook/ShadowHook.bs.js');

describe('ShadowHookImpl.web', () => {
  describe('useGetShadowStyle', () => {
    it('exists as a function', () => {
      expect(useGetShadowStyle).toBeDefined();
      expect(typeof useGetShadowStyle).toBe('function');
    });

    it('returns an object with boxShadow property', () => {
      const { result } = renderHook(() => useGetShadowStyle(4, undefined, undefined));

      expect(result.current).toHaveProperty('boxShadow');
      expect(typeof result.current.boxShadow).toBe('string');
    });

    it('generates boxShadow with default black color', () => {
      const { result } = renderHook(() => useGetShadowStyle(4, undefined, undefined));

      expect(result.current.boxShadow).toContain('rgba');
      expect(result.current.boxShadow).toContain('0.2');
    });

    it('uses shadowIntensity in boxShadow', () => {
      const { result } = renderHook(() => useGetShadowStyle(8, undefined, undefined));

      expect(result.current.boxShadow).toContain('8px');
    });

    it('handles shadowIntensity of 0', () => {
      const { result } = renderHook(() => useGetShadowStyle(0, undefined, undefined));

      expect(result.current).toHaveProperty('boxShadow');
      expect(result.current.boxShadow).toContain('0px');
    });

    it('handles custom shadowColor', () => {
      const { result } = renderHook(() => useGetShadowStyle(4, 'red', undefined));

      expect(result.current).toHaveProperty('boxShadow');
      expect(result.current.boxShadow).toContain('rgba');
    });

    it('handles blue shadowColor', () => {
      const { result } = renderHook(() => useGetShadowStyle(6, 'blue', undefined));

      expect(result.current).toHaveProperty('boxShadow');
      expect(result.current.boxShadow).toMatch(/rgba\(\d+,\s*\d+,\s*\d+,\s*0\.2\)/);
    });

    it('handles white shadowColor', () => {
      const { result } = renderHook(() => useGetShadowStyle(4, 'white', undefined));

      expect(result.current).toHaveProperty('boxShadow');
    });

    it('handles hex color string', () => {
      const { result } = renderHook(() => useGetShadowStyle(4, '#006DF9', undefined));

      expect(result.current).toHaveProperty('boxShadow');
    });

    it('generates consistent results for same inputs', () => {
      const { result: result1 } = renderHook(() => useGetShadowStyle(5, 'black', undefined));
      const { result: result2 } = renderHook(() => useGetShadowStyle(5, 'black', undefined));

      expect(result1.current.boxShadow).toBe(result2.current.boxShadow);
    });

    it('handles large shadowIntensity values', () => {
      const { result } = renderHook(() => useGetShadowStyle(100, undefined, undefined));

      expect(result.current).toHaveProperty('boxShadow');
      expect(result.current.boxShadow).toContain('100px');
    });

    it('produces correct rgba format', () => {
      const { result } = renderHook(() => useGetShadowStyle(4, 'black', undefined));

      const rgbaPattern = /rgba\(\d+,\s*\d+,\s*\d+,\s*[\d.]+\)/;
      expect(result.current.boxShadow).toMatch(rgbaPattern);
    });

    it('contains correct shadow opacity (0.2)', () => {
      const { result } = renderHook(() => useGetShadowStyle(4, undefined, undefined));

      expect(result.current.boxShadow).toContain('0.2');
    });

    it('contains shadow offset width of 0', () => {
      const { result } = renderHook(() => useGetShadowStyle(4, undefined, undefined));

      const parts = result.current.boxShadow.split(' ');
      expect(parts[0]).toBe('0');
    });

    it('contains shadow offset height equal to shadowIntensity', () => {
      const { result } = renderHook(() => useGetShadowStyle(6, undefined, undefined));

      expect(result.current.boxShadow).toContain('6px');
    });

    it('formats boxShadow correctly with all parameters', () => {
      const { result } = renderHook(() => useGetShadowStyle(4, 'black', undefined));

      const boxShadow = result.current.boxShadow;
      expect(boxShadow).toMatch(/^0 0 \d+px rgba\(\d+,\s*\d+,\s*\d+,\s*0\.2\)$/);
    });
  });
});

describe('ShadowHook (wrapper)', () => {
  describe('useGetShadowStyle', () => {
    it('exists as a function', () => {
      expect(useGetShadowStyleWrapper).toBeDefined();
      expect(typeof useGetShadowStyleWrapper).toBe('function');
    });

    it('returns an object with shadow properties', () => {
      const { result } = renderHook(() => useGetShadowStyleWrapper(4, undefined, undefined));

      expect(result.current).toHaveProperty('shadowColor');
      expect(result.current).toHaveProperty('shadowOffset');
      expect(result.current).toHaveProperty('shadowOpacity');
      expect(result.current).toHaveProperty('shadowRadius');
    });

    it('sets shadowRadius to shadowIntensity', () => {
      const { result } = renderHook(() => useGetShadowStyleWrapper(8, undefined, undefined));

      expect(result.current.shadowRadius).toBe(8);
    });

    it('sets shadowOffset height to half of shadowIntensity', () => {
      const { result } = renderHook(() => useGetShadowStyleWrapper(8, undefined, undefined));

      expect(result.current.shadowOffset.height).toBe(4);
      expect(result.current.shadowOffset.width).toBe(0);
    });

    it('handles shadowIntensity of 0', () => {
      const { result } = renderHook(() => useGetShadowStyleWrapper(0, undefined, undefined));

      expect(result.current.shadowRadius).toBe(0);
      expect(result.current.shadowOffset.height).toBe(0);
    });

    it('uses default black shadowColor when undefined', () => {
      const { result } = renderHook(() => useGetShadowStyleWrapper(4, undefined, undefined));

      expect(result.current.shadowColor).toBe('black');
    });

    it('uses provided shadowColor', () => {
      const { result } = renderHook(() => useGetShadowStyleWrapper(4, 'red', undefined));

      expect(result.current.shadowColor).toBe('red');
    });

    it('handles null shadowColor', () => {
      const { result } = renderHook(() => useGetShadowStyleWrapper(4, null, undefined));

      expect(result.current.shadowColor).toBeNull();
    });

    it('handles hex color string', () => {
      const { result } = renderHook(() => useGetShadowStyleWrapper(4, '#006DF9', undefined));

      expect(result.current.shadowColor).toBe('#006DF9');
    });

    it('sets shadowOpacity to 0.2', () => {
      const { result } = renderHook(() => useGetShadowStyleWrapper(4, undefined, undefined));

      expect(result.current.shadowOpacity).toBe(0.2);
    });

    it('generates consistent results for same inputs', () => {
      const { result: result1 } = renderHook(() => useGetShadowStyleWrapper(5, 'black', undefined));
      const { result: result2 } = renderHook(() => useGetShadowStyleWrapper(5, 'black', undefined));

      expect(result1.current).toEqual(result2.current);
    });

    it('handles large shadowIntensity values', () => {
      const { result } = renderHook(() => useGetShadowStyleWrapper(100, undefined, undefined));

      expect(result.current.shadowRadius).toBe(100);
      expect(result.current.shadowOffset.height).toBe(50);
    });

    it('handles blue shadowColor', () => {
      const { result } = renderHook(() => useGetShadowStyleWrapper(6, 'blue', undefined));

      expect(result.current.shadowColor).toBe('blue');
      expect(result.current.shadowRadius).toBe(6);
    });

    it('handles white shadowColor', () => {
      const { result } = renderHook(() => useGetShadowStyleWrapper(4, 'white', undefined));

      expect(result.current.shadowColor).toBe('white');
    });

    it('handles odd shadowIntensity values', () => {
      const { result } = renderHook(() => useGetShadowStyleWrapper(7, undefined, undefined));

      expect(result.current.shadowRadius).toBe(7);
      expect(result.current.shadowOffset.height).toBe(3.5);
    });
  });
});
