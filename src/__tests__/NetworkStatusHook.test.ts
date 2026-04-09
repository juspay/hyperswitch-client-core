import { renderHook, act, waitFor } from '@testing-library/react-native';

const mockShowBanner = jest.fn();
const mockHideBanner = jest.fn();

jest.mock('../contexts/BannerContext.bs.js', () => ({
  useBanner: () => [
    { isVisible: false, message: '', bannerType: 'none' },
    mockShowBanner,
    mockHideBanner,
  ],
}));

jest.mock('../utility/constants/GlobalHooks.bs.js', () => ({
  useGetBaseUrl: jest.fn(() => () => 'https://sandbox.hyperswitch.io'),
}));

const mockFetchApi = jest.fn();

jest.mock('../utility/logics/APIUtils.bs.js', () => ({
  fetchApi: (...args: any[]) => mockFetchApi(...args),
}));

const { useNetworkStatus } = require('../hooks/NetworkStatusHook.bs.js');

describe('NetworkStatusHook', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    jest.useRealTimers();
    mockFetchApi.mockReset();
  });

  describe('useNetworkStatus', () => {
    it('returns an array with isConnected state and checkConnectivity function', () => {
      mockFetchApi.mockResolvedValue({ status: 200 });

      const { result } = renderHook(() => useNetworkStatus());

      expect(Array.isArray(result.current)).toBe(true);
      expect(result.current.length).toBe(2);
      expect(typeof result.current[0]).toBe('boolean');
      expect(typeof result.current[1]).toBe('function');
    });

    it('initializes with isConnected set to true', () => {
      mockFetchApi.mockResolvedValue({ status: 200 });

      const { result } = renderHook(() => useNetworkStatus());

      expect(result.current[0]).toBe(true);
    });

    it('checkConnectivity function can be called manually', async () => {
      mockFetchApi.mockResolvedValue({ status: 200 });

      const { result } = renderHook(() => useNetworkStatus());

      await act(async () => {
        const checkConnectivity = result.current[1];
        await checkConnectivity();
      });

      expect(mockFetchApi).toHaveBeenCalled();
    });

    it('calls fetchApi with correct parameters', async () => {
      mockFetchApi.mockResolvedValue({ status: 200 });

      const { result } = renderHook(() => useNetworkStatus());

      await act(async () => {
        const checkConnectivity = result.current[1];
        await checkConnectivity();
      });

      expect(mockFetchApi).toHaveBeenCalledWith(
        'https://sandbox.hyperswitch.io/health',
        undefined,
        { 'Cache-Control': 'no-cache' },
        'GET',
        'cors',
        true
      );
    });

    it('sets isConnected to true when API returns 2xx status', async () => {
      mockFetchApi.mockResolvedValue({ status: 200 });

      const { result } = renderHook(() => useNetworkStatus());

      await act(async () => {
        const checkConnectivity = result.current[1];
        await checkConnectivity();
      });

      await waitFor(() => {
        expect(result.current[0]).toBe(true);
      });
    });

    it('sets isConnected to false when API returns non-2xx status', async () => {
      mockFetchApi.mockResolvedValue({ status: 500 });

      const { result } = renderHook(() => useNetworkStatus());

      await act(async () => {
        const checkConnectivity = result.current[1];
        await checkConnectivity();
      });

      await waitFor(() => {
        expect(result.current[0]).toBe(false);
      });
    });

    it('calls showBanner with error message when connection fails', async () => {
      mockFetchApi.mockResolvedValue({ status: 500 });

      const { result } = renderHook(() => useNetworkStatus());

      await act(async () => {
        const checkConnectivity = result.current[1];
        await checkConnectivity();
      });

      await waitFor(() => {
        expect(mockShowBanner).toHaveBeenCalledWith('No internet connection', 'error');
      });
    });

    it('calls hideBanner when connected without previous disconnection', async () => {
      mockFetchApi.mockResolvedValue({ status: 200 });

      const { result } = renderHook(() => useNetworkStatus());

      await act(async () => {
        const checkConnectivity = result.current[1];
        await checkConnectivity();
      });

      await waitFor(() => {
        expect(mockHideBanner).toHaveBeenCalled();
      });
    });

    it('sets isConnected to false when fetchApi throws an error', async () => {
      mockFetchApi.mockRejectedValue(new Error('Network error'));

      const { result } = renderHook(() => useNetworkStatus());

      await act(async () => {
        const checkConnectivity = result.current[1];
        await checkConnectivity();
      });

      await waitFor(() => {
        expect(result.current[0]).toBe(false);
      });
    });

    it('shows error banner when fetchApi throws an error', async () => {
      mockFetchApi.mockRejectedValue(new Error('Network error'));

      const { result } = renderHook(() => useNetworkStatus());

      await act(async () => {
        const checkConnectivity = result.current[1];
        await checkConnectivity();
      });

      await waitFor(() => {
        expect(mockShowBanner).toHaveBeenCalledWith('No internet connection', 'error');
      });
    });

    it('handles 201 status code as connected', async () => {
      mockFetchApi.mockResolvedValue({ status: 201 });

      const { result } = renderHook(() => useNetworkStatus());

      await act(async () => {
        const checkConnectivity = result.current[1];
        await checkConnectivity();
      });

      await waitFor(() => {
        expect(result.current[0]).toBe(true);
      });
    });

    it('handles 204 status code as connected', async () => {
      mockFetchApi.mockResolvedValue({ status: 204 });

      const { result } = renderHook(() => useNetworkStatus());

      await act(async () => {
        const checkConnectivity = result.current[1];
        await checkConnectivity();
      });

      await waitFor(() => {
        expect(result.current[0]).toBe(true);
      });
    });

    it('handles 400 status code as disconnected', async () => {
      mockFetchApi.mockResolvedValue({ status: 400 });

      const { result } = renderHook(() => useNetworkStatus());

      await act(async () => {
        const checkConnectivity = result.current[1];
        await checkConnectivity();
      });

      await waitFor(() => {
        expect(result.current[0]).toBe(false);
      });
    });

    it('handles 503 status code as disconnected', async () => {
      mockFetchApi.mockResolvedValue({ status: 503 });

      const { result } = renderHook(() => useNetworkStatus());

      await act(async () => {
        const checkConnectivity = result.current[1];
        await checkConnectivity();
      });

      await waitFor(() => {
        expect(result.current[0]).toBe(false);
      });
    });

    it('calls showBanner with success message when reconnecting after offline', async () => {
      mockFetchApi.mockResolvedValue({ status: 500 });

      const { result } = renderHook(() => useNetworkStatus());

      await waitFor(() => {
        expect(result.current[0]).toBe(false);
      });

      mockShowBanner.mockClear();
      mockFetchApi.mockResolvedValue({ status: 200 });

      await act(async () => {
        const checkConnectivity = result.current[1];
        await checkConnectivity();
      });

      await waitFor(() => {
        expect(mockShowBanner).toHaveBeenCalledWith('Back Online', 'success');
      });
    });
  });
});
