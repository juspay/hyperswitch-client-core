import { renderHook, act } from '@testing-library/react-native';

const mockSamsungPayValidityHook = jest.fn();

jest.mock('../hooks/SamsungPay.bs.js', () => ({
  useSamsungPayValidityHook: () => mockSamsungPayValidityHook(),
}));

const { useSDKLoadCheck } = require('../hooks/SDKLoadCheckHook.bs.js');

describe('SDKLoadCheckHook', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('useSDKLoadCheck', () => {
    it('returns true when enablePartialLoading is true (default)', () => {
      mockSamsungPayValidityHook.mockReturnValue('Checking');

      const { result } = renderHook(() => useSDKLoadCheck());

      expect(result.current).toBe(true);
    });

    it('returns true when enablePartialLoading is explicitly set to true', () => {
      mockSamsungPayValidityHook.mockReturnValue('Not_Started');

      const { result } = renderHook(() => useSDKLoadCheck(true));

      expect(result.current).toBe(true);
    });

    it('returns true when enablePartialLoading is false and samsungPayValidity is Valid', () => {
      mockSamsungPayValidityHook.mockReturnValue('Valid');

      const { result } = renderHook(() => useSDKLoadCheck(false));

      expect(result.current).toBe(true);
    });

    it('returns false when enablePartialLoading is false and samsungPayValidity is Checking', () => {
      mockSamsungPayValidityHook.mockReturnValue('Checking');

      const { result } = renderHook(() => useSDKLoadCheck(false));

      expect(result.current).toBe(false);
    });

    it('returns false when enablePartialLoading is false and samsungPayValidity is Not_Started', () => {
      mockSamsungPayValidityHook.mockReturnValue('Not_Started');

      const { result } = renderHook(() => useSDKLoadCheck(false));

      expect(result.current).toBe(false);
    });

    it('returns true when enablePartialLoading is false and samsungPayValidity is NotValid', () => {
      mockSamsungPayValidityHook.mockReturnValue('NotValid');

      const { result } = renderHook(() => useSDKLoadCheck(false));

      expect(result.current).toBe(true);
    });

    it('updates canLoad when samsungPayValidity changes from Checking to Valid', () => {
      mockSamsungPayValidityHook.mockReturnValue('Checking');

      const { result, rerender } = renderHook(() => useSDKLoadCheck(false));

      expect(result.current).toBe(false);

      mockSamsungPayValidityHook.mockReturnValue('Valid');
      rerender();

      expect(result.current).toBe(true);
    });

    it('updates canLoad when samsungPayValidity changes from Valid to Checking', () => {
      mockSamsungPayValidityHook.mockReturnValue('Valid');

      const { result, rerender } = renderHook(() => useSDKLoadCheck(false));

      expect(result.current).toBe(true);

      mockSamsungPayValidityHook.mockReturnValue('Checking');
      rerender();

      expect(result.current).toBe(false);
    });

    it('returns true regardless of samsungPayValidity when enablePartialLoading is true', () => {
      const validityStates = ['Checking', 'Not_Started', 'Valid', 'NotValid', 'Unknown'];

      validityStates.forEach((state) => {
        mockSamsungPayValidityHook.mockReturnValue(state);

        const { result } = renderHook(() => useSDKLoadCheck(true));

        expect(result.current).toBe(true);
      });
    });

    it('handles undefined samsungPayValidity gracefully when enablePartialLoading is false', () => {
      mockSamsungPayValidityHook.mockReturnValue(undefined);

      const { result } = renderHook(() => useSDKLoadCheck(false));

      expect(result.current).toBe(true);
    });

    it('handles empty string samsungPayValidity when enablePartialLoading is false', () => {
      mockSamsungPayValidityHook.mockReturnValue('');

      const { result } = renderHook(() => useSDKLoadCheck(false));

      expect(result.current).toBe(true);
    });

    it('handles null samsungPayValidity when enablePartialLoading is false', () => {
      mockSamsungPayValidityHook.mockReturnValue(null);

      const { result } = renderHook(() => useSDKLoadCheck(false));

      expect(result.current).toBe(true);
    });
  });
});
