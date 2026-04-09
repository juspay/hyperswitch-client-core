import * as React from 'react';
import { renderHook, act } from '@testing-library/react-native';
import {
  initialState,
  defaultSetter,
  bannerContext,
  make as BannerContext,
  useBanner,
} from '../contexts/BannerContext.bs.js';

describe('BannerContext', () => {
  describe('initialState', () => {
    it('has isVisible set to false', () => {
      expect(initialState.isVisible).toBe(false);
    });

    it('has empty message string', () => {
      expect(initialState.message).toBe('');
    });

    it('has bannerType set to "none"', () => {
      expect(initialState.bannerType).toBe('none');
    });
  });

  describe('defaultSetter', () => {
    it('is a function', () => {
      expect(typeof defaultSetter).toBe('function');
    });

    it('returns undefined when called', () => {
      expect(defaultSetter({})).toBeUndefined();
    });

    it('does not throw when called with any argument', () => {
      expect(() => defaultSetter(null)).not.toThrow();
      expect(() => defaultSetter(undefined)).not.toThrow();
      expect(() => defaultSetter({ isVisible: true })).not.toThrow();
    });
  });

  describe('bannerContext', () => {
    it('provides default context value with initialState and defaultSetter', () => {
      expect(bannerContext._currentValue[0]).toEqual(initialState);
      expect(bannerContext._currentValue[1]).toBe(defaultSetter);
    });

    it('is a valid React context', () => {
      expect(bannerContext.Provider).toBeDefined();
      expect(bannerContext.Consumer).toBeDefined();
    });
  });

  describe('useBanner hook', () => {
    const wrapper = ({ children }: { children: React.ReactNode }) => (
      <BannerContext>{children}</BannerContext>
    );

    it('returns initial state on first render', () => {
      const { result } = renderHook(() => useBanner(), { wrapper });

      const [state] = result.current;
      expect(state.isVisible).toBe(false);
      expect(state.message).toBe('');
      expect(state.bannerType).toBe('none');
    });

    it('showBanner sets isVisible to true with message', () => {
      const { result } = renderHook(() => useBanner(), { wrapper });

      act(() => {
        const [, showBanner] = result.current;
        showBanner('Test message', 'success');
      });

      const [state] = result.current;
      expect(state.isVisible).toBe(true);
      expect(state.message).toBe('Test message');
      expect(state.bannerType).toBe('success');
    });

    it('showBanner defaults bannerType to "info" when not provided', () => {
      const { result } = renderHook(() => useBanner(), { wrapper });

      act(() => {
        const [, showBanner] = result.current;
        showBanner('Info message');
      });

      const [state] = result.current;
      expect(state.bannerType).toBe('info');
    });

    it('hideBanner sets isVisible to false while preserving message and bannerType', () => {
      const { result } = renderHook(() => useBanner(), { wrapper });

      act(() => {
        const [, showBanner] = result.current;
        showBanner('Error message', 'error');
      });

      act(() => {
        const [, , hideBanner] = result.current;
        hideBanner();
      });

      const [state] = result.current;
      expect(state.isVisible).toBe(false);
      expect(state.message).toBe('Error message');
      expect(state.bannerType).toBe('error');
    });

    it('can show and hide banner multiple times', () => {
      const { result } = renderHook(() => useBanner(), { wrapper });

      act(() => {
        const [, showBanner] = result.current;
        showBanner('First message', 'warning');
      });

      expect(result.current[0].isVisible).toBe(true);

      act(() => {
        const [, , hideBanner] = result.current;
        hideBanner();
      });

      expect(result.current[0].isVisible).toBe(false);

      act(() => {
        const [, showBanner] = result.current;
        showBanner('Second message', 'info');
      });

      expect(result.current[0].isVisible).toBe(true);
      expect(result.current[0].message).toBe('Second message');
    });

    it('showBanner overwrites previous message and bannerType', () => {
      const { result } = renderHook(() => useBanner(), { wrapper });

      act(() => {
        const [, showBanner] = result.current;
        showBanner('First message', 'success');
      });

      act(() => {
        const [, showBanner] = result.current;
        showBanner('Second message', 'error');
      });

      const [state] = result.current;
      expect(state.message).toBe('Second message');
      expect(state.bannerType).toBe('error');
    });
  });

  describe('BannerContext component', () => {
    it('provides state and setter to children via context', () => {
      const wrapper = ({ children }: { children: React.ReactNode }) => (
        <BannerContext>{children}</BannerContext>
      );

      const { result } = renderHook(() => React.useContext(bannerContext), { wrapper });

      expect(result.current[0]).toEqual(initialState);
      expect(typeof result.current[1]).toBe('function');
    });
  });
});
