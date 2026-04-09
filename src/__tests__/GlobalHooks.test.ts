import { renderHook } from '@testing-library/react-native';
import React from 'react';

const mockNativePropContext = React.createContext([{}, jest.fn()]);

jest.mock('../contexts/NativePropContext.bs.js', () => ({
  nativePropContext: mockNativePropContext,
  defaultValue: {},
  defaultSetter: jest.fn(),
  Provider: mockNativePropContext.Provider,
  make: mockNativePropContext.Provider,
}));

const {
  useGetBaseUrl,
  useGetS3AssetsVersion,
  useGetAssetUrlWithVersion,
  useGetLoggingUrl,
} = require('../utility/constants/GlobalHooks.bs.js');

const originalEnv = process.env;

describe('GlobalHooks', () => {
  beforeEach(() => {
    process.env = {
      ...originalEnv,
      HYPERSWITCH_INTEG_URL: 'https://integ.hyperswitch.io',
      HYPERSWITCH_SANDBOX_URL: 'https://sandbox.hyperswitch.io',
      HYPERSWITCH_PRODUCTION_URL: 'https://api.hyperswitch.io',
      INTEG_ASSETS_END_POINT: 'https://dev.hyperswitch.io',
      SANDBOX_ASSETS_END_POINT: 'https://beta.hyperswitch.io',
      PROD_ASSETS_END_POINT: 'https://checkout.hyperswitch.io',
      HYPERSWITCH_LOGS_PATH: '/logs/sdk',
    };
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  const createWrapper = (nativeProp: any) => {
    return ({ children }: { children: React.ReactNode }) => {
      return React.createElement(
        mockNativePropContext.Provider,
        { value: [nativeProp, jest.fn()] as any },
        children,
      );
    };
  };

  describe('useGetBaseUrl', () => {
    it('returns customBackendUrl when defined', () => {
      const nativeProp = {
        customBackendUrl: 'https://custom.backend.com',
        env: 'SANDBOX',
      };
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => useGetBaseUrl(), { wrapper });

      const getUrl = result.current;
      expect(getUrl()).toBe('https://custom.backend.com');
    });

    it('returns INTEG URL when env is INTEG and no customBackendUrl', () => {
      const nativeProp = {
        customBackendUrl: undefined,
        env: 'INTEG',
      };
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => useGetBaseUrl(), { wrapper });

      const getUrl = result.current;
      expect(getUrl()).toBe('https://integ.hyperswitch.io');
    });

    it('returns SANDBOX URL when env is SANDBOX and no customBackendUrl', () => {
      const nativeProp = {
        customBackendUrl: undefined,
        env: 'SANDBOX',
      };
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => useGetBaseUrl(), { wrapper });

      const getUrl = result.current;
      expect(getUrl()).toBe('https://sandbox.hyperswitch.io');
    });

    it('returns PROD URL when env is PROD and no customBackendUrl', () => {
      const nativeProp = {
        customBackendUrl: undefined,
        env: 'PROD',
      };
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => useGetBaseUrl(), { wrapper });

      const getUrl = result.current;
      expect(getUrl()).toBe('https://api.hyperswitch.io');
    });

    it('prioritizes customBackendUrl over env-based URL', () => {
      const nativeProp = {
        customBackendUrl: 'https://override.com',
        env: 'PROD',
      };
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => useGetBaseUrl(), { wrapper });

      const getUrl = result.current;
      expect(getUrl()).toBe('https://override.com');
    });
  });

  describe('useGetS3AssetsVersion', () => {
    it('returns a function that returns the assets version path', () => {
      const nativeProp = { env: 'SANDBOX' };
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => useGetS3AssetsVersion(), { wrapper });

      const getVersion = result.current;
      expect(getVersion()).toBe('/assets/v2');
    });

    it('returns consistent version path regardless of env', () => {
      const nativeProp = { env: 'PROD' };
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => useGetS3AssetsVersion(), { wrapper });

      const getVersion = result.current;
      expect(getVersion()).toBe('/assets/v2');
    });

    it('returns a function that can be called multiple times', () => {
      const nativeProp = { env: 'INTEG' };
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => useGetS3AssetsVersion(), { wrapper });

      const getVersion = result.current;
      expect(getVersion()).toBe('/assets/v2');
      expect(getVersion()).toBe('/assets/v2');
      expect(getVersion()).toBe('/assets/v2');
    });
  });

  describe('useGetAssetUrlWithVersion', () => {
    it('returns INTEG assets URL with version when env is INTEG', () => {
      const nativeProp = { env: 'INTEG' };
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => useGetAssetUrlWithVersion(), { wrapper });

      const getAssetUrl = result.current;
      expect(getAssetUrl()).toBe('https://dev.hyperswitch.io/assets/v2');
    });

    it('returns SANDBOX assets URL with version when env is SANDBOX', () => {
      const nativeProp = { env: 'SANDBOX' };
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => useGetAssetUrlWithVersion(), { wrapper });

      const getAssetUrl = result.current;
      expect(getAssetUrl()).toBe('https://beta.hyperswitch.io/assets/v2');
    });

    it('returns PROD assets URL with version when env is PROD', () => {
      const nativeProp = { env: 'PROD' };
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => useGetAssetUrlWithVersion(), { wrapper });

      const getAssetUrl = result.current;
      expect(getAssetUrl()).toBe('https://checkout.hyperswitch.io/assets/v2');
    });

    it('appends version path to the assets endpoint', () => {
      const nativeProp = { env: 'SANDBOX' };
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => useGetAssetUrlWithVersion(), { wrapper });

      const getAssetUrl = result.current;
      const url = getAssetUrl();
      expect(url).toContain('/assets/v2');
    });
  });

  describe('useGetLoggingUrl', () => {
    it('returns customLogUrl when both customBackendUrl and customLogUrl are defined', () => {
      const nativeProp = {
        customBackendUrl: 'https://custom.backend.com',
        customLogUrl: 'https://custom.logs.com',
        env: 'SANDBOX',
      };
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => useGetLoggingUrl(), { wrapper });

      const getLoggingUrl = result.current;
      expect(getLoggingUrl()).toBe('https://custom.logs.com');
    });

    it('returns undefined when customBackendUrl is defined but customLogUrl is undefined', () => {
      const nativeProp = {
        customBackendUrl: 'https://custom.backend.com',
        customLogUrl: undefined,
        env: 'SANDBOX',
      };
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => useGetLoggingUrl(), { wrapper });

      const getLoggingUrl = result.current;
      expect(getLoggingUrl()).toBeUndefined();
    });

    it('returns customLogUrl when customBackendUrl is undefined but customLogUrl is defined', () => {
      const nativeProp = {
        customBackendUrl: undefined,
        customLogUrl: 'https://custom.logs.com',
        env: 'SANDBOX',
      };
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => useGetLoggingUrl(), { wrapper });

      const getLoggingUrl = result.current;
      expect(getLoggingUrl()).toBe('https://custom.logs.com');
    });

    it('returns SANDBOX URL with logs path for INTEG env when no custom URLs', () => {
      const nativeProp = {
        customBackendUrl: undefined,
        customLogUrl: undefined,
        env: 'INTEG',
      };
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => useGetLoggingUrl(), { wrapper });

      const getLoggingUrl = result.current;
      expect(getLoggingUrl()).toBe('https://sandbox.hyperswitch.io/logs/sdk');
    });

    it('returns SANDBOX URL with logs path for SANDBOX env when no custom URLs', () => {
      const nativeProp = {
        customBackendUrl: undefined,
        customLogUrl: undefined,
        env: 'SANDBOX',
      };
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => useGetLoggingUrl(), { wrapper });

      const getLoggingUrl = result.current;
      expect(getLoggingUrl()).toBe('https://sandbox.hyperswitch.io/logs/sdk');
    });

    it('returns PROD URL with logs path for PROD env when no custom URLs', () => {
      const nativeProp = {
        customBackendUrl: undefined,
        customLogUrl: undefined,
        env: 'PROD',
      };
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => useGetLoggingUrl(), { wrapper });

      const getLoggingUrl = result.current;
      expect(getLoggingUrl()).toBe('https://api.hyperswitch.io/logs/sdk');
    });

    it('prioritizes customLogUrl over env-based URL when customBackendUrl is undefined', () => {
      const nativeProp = {
        customBackendUrl: undefined,
        customLogUrl: 'https://my.logs.com',
        env: 'PROD',
      };
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => useGetLoggingUrl(), { wrapper });

      const getLoggingUrl = result.current;
      expect(getLoggingUrl()).toBe('https://my.logs.com');
    });
  });
});
