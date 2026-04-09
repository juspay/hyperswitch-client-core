import { renderHook } from '@testing-library/react-native';

const mockUseWindowDimensions = jest.fn();

jest.mock('react-native', () => ({
  useWindowDimensions: () => mockUseWindowDimensions(),
}));

const { useMediaView } = require('../hooks/WindowDimension.bs.js');

describe('WindowDimension', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('useMediaView', () => {
    it('returns "Mobile" for width less than 441', () => {
      mockUseWindowDimensions.mockReturnValue({ width: 320, height: 568 });

      const { result } = renderHook(() => useMediaView());

      expect(result.current).toBe('Mobile');
    });

    it('returns "Mobile" for width at the lower boundary (0)', () => {
      mockUseWindowDimensions.mockReturnValue({ width: 0, height: 0 });

      const { result } = renderHook(() => useMediaView());

      expect(result.current).toBe('Mobile');
    });

    it('returns "Mobile" for width just below Tablet threshold (440)', () => {
      mockUseWindowDimensions.mockReturnValue({ width: 440, height: 800 });

      const { result } = renderHook(() => useMediaView());

      expect(result.current).toBe('Mobile');
    });

    it('returns "Tablet" for width at exactly 441', () => {
      mockUseWindowDimensions.mockReturnValue({ width: 441, height: 800 });

      const { result } = renderHook(() => useMediaView());

      expect(result.current).toBe('Tablet');
    });

    it('returns "Tablet" for width in the middle of Tablet range (600)', () => {
      mockUseWindowDimensions.mockReturnValue({ width: 600, height: 800 });

      const { result } = renderHook(() => useMediaView());

      expect(result.current).toBe('Tablet');
    });

    it('returns "Tablet" for width just below Desktop threshold (829)', () => {
      mockUseWindowDimensions.mockReturnValue({ width: 829, height: 800 });

      const { result } = renderHook(() => useMediaView());

      expect(result.current).toBe('Tablet');
    });

    it('returns "Desktop" for width at exactly 830', () => {
      mockUseWindowDimensions.mockReturnValue({ width: 830, height: 600 });

      const { result } = renderHook(() => useMediaView());

      expect(result.current).toBe('Desktop');
    });

    it('returns "Desktop" for large width (1920)', () => {
      mockUseWindowDimensions.mockReturnValue({ width: 1920, height: 1080 });

      const { result } = renderHook(() => useMediaView());

      expect(result.current).toBe('Desktop');
    });

    it('returns "Desktop" for width exactly at boundary value (441.0 transition already tested)', () => {
      mockUseWindowDimensions.mockReturnValue({ width: 830.5, height: 600 });

      const { result } = renderHook(() => useMediaView());

      expect(result.current).toBe('Desktop');
    });

    it('returns "Mobile" for typical iPhone width (375)', () => {
      mockUseWindowDimensions.mockReturnValue({ width: 375, height: 667 });

      const { result } = renderHook(() => useMediaView());

      expect(result.current).toBe('Mobile');
    });

    it('returns "Mobile" for typical Android phone width (360)', () => {
      mockUseWindowDimensions.mockReturnValue({ width: 360, height: 640 });

      const { result } = renderHook(() => useMediaView());

      expect(result.current).toBe('Mobile');
    });

    it('returns "Tablet" for typical iPad width (768)', () => {
      mockUseWindowDimensions.mockReturnValue({ width: 768, height: 1024 });

      const { result } = renderHook(() => useMediaView());

      expect(result.current).toBe('Tablet');
    });

    it('returns "Desktop" for typical laptop width (1366)', () => {
      mockUseWindowDimensions.mockReturnValue({ width: 1366, height: 768 });

      const { result } = renderHook(() => useMediaView());

      expect(result.current).toBe('Desktop');
    });

    it('handles floating point width values correctly (440.9 should be Mobile)', () => {
      mockUseWindowDimensions.mockReturnValue({ width: 440.9, height: 800 });

      const { result } = renderHook(() => useMediaView());

      expect(result.current).toBe('Mobile');
    });

    it('handles floating point width values correctly (829.9 should be Tablet)', () => {
      mockUseWindowDimensions.mockReturnValue({ width: 829.9, height: 600 });

      const { result } = renderHook(() => useMediaView());

      expect(result.current).toBe('Tablet');
    });
  });
});
