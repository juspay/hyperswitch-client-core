import { renderHook, act } from '@testing-library/react-native';
import {
  viewPortContext,
  defaultVal,
  minTopInset,
  minBottomInset,
  make as ViewportContextProvider,
} from '../contexts/ViewportContext.bs.js';
import React from 'react';

jest.mock('react-native', () => ({
  Dimensions: {
    get: jest.fn(() => ({
      window: { height: 812, width: 375 },
      screen: { height: 896, width: 414 },
    })),
  },
  StatusBar: {
    currentHeight: 44,
  },
}));

jest.mock('../hooks/WebKit.bs.js', () => ({
  platform: 'ios',
}));

describe('ViewportContext', () => {
  describe('constants', () => {
    it('minTopInset is 50', () => {
      expect(minTopInset).toBe(50);
    });

    it('minBottomInset is 0 for iOS platform', () => {
      expect(minBottomInset).toBe(0);
    });

    it('defaultVal contains viewport dimensions', () => {
      expect(defaultVal).toHaveProperty('windowHeight');
      expect(defaultVal).toHaveProperty('windowWidth');
      expect(defaultVal).toHaveProperty('screenHeight');
      expect(defaultVal).toHaveProperty('screenWidth');
      expect(defaultVal).toHaveProperty('bottomInset');
      expect(defaultVal).toHaveProperty('topInset');
    });

    it('defaultVal has correct topInset value', () => {
      expect(defaultVal.topInset).toBe(50);
    });
  });

  describe('viewPortContext', () => {
    it('is defined as a React context', () => {
      expect(viewPortContext).toBeDefined();
      expect(viewPortContext.Provider).toBeDefined();
    });

    it('has default value with viewport dimensions', () => {
      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(viewPortContext.Provider, { value: [defaultVal, jest.fn()] }, children);

      const { result } = renderHook(() => React.useContext(viewPortContext), { wrapper });

      expect(result.current[0]).toEqual(defaultVal);
      expect(typeof result.current[1]).toBe('function');
    });
  });

  describe('ViewportContext Provider', () => {
    it('provides viewport dimensions with default props', () => {
      const TestComponent = () => {
        const [state, setState] = React.useContext(viewPortContext);
        return { state, setState };
      };

      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(ViewportContextProvider, { children }, children);

      const { result } = renderHook(() => TestComponent(), { wrapper });

      expect(result.current.state).toHaveProperty('windowHeight');
      expect(result.current.state).toHaveProperty('windowWidth');
      expect(result.current.state).toHaveProperty('screenHeight');
      expect(result.current.state).toHaveProperty('screenWidth');
      expect(result.current.state).toHaveProperty('bottomInset');
      expect(result.current.state).toHaveProperty('topInset');
    });

    it('applies bottomInset prop when provided', () => {
      const TestComponent = () => {
        const [state, setState] = React.useContext(viewPortContext);
        return { state, setState };
      };

      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(ViewportContextProvider, { bottomInset: 20, children }, children);

      const { result } = renderHook(() => TestComponent(), { wrapper });

      expect(result.current.state.bottomInset).toBe(20);
    });

    it('applies topInset prop when provided', () => {
      const TestComponent = () => {
        const [state, setState] = React.useContext(viewPortContext);
        return { state, setState };
      };

      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(ViewportContextProvider, { topInset: 30, children }, children);

      const { result } = renderHook(() => TestComponent(), { wrapper });

      expect(result.current.state.topInset).toBe(80);
    });

    it('allows state to be updated via setter', () => {
      const TestComponent = () => {
        const [state, setState] = React.useContext(viewPortContext);
        return { state, setState };
      };

      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(ViewportContextProvider, { children }, children);

      const { result } = renderHook(() => TestComponent(), { wrapper });

      const newViewport = {
        windowHeight: 1000,
        windowWidth: 500,
        screenHeight: 1100,
        screenWidth: 550,
        bottomInset: 30,
        topInset: 60,
      };

      act(() => {
        result.current.setState(newViewport);
      });

      expect(result.current.state).toEqual(newViewport);
    });

    it('handles undefined bottomInset prop gracefully', () => {
      const TestComponent = () => {
        const [state, setState] = React.useContext(viewPortContext);
        return { state, setState };
      };

      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(ViewportContextProvider, { bottomInset: undefined, children }, children);

      const { result } = renderHook(() => TestComponent(), { wrapper });

      expect(result.current.state.bottomInset).toBe(0);
    });

    it('handles undefined topInset prop gracefully', () => {
      const TestComponent = () => {
        const [state, setState] = React.useContext(viewPortContext);
        return { state, setState };
      };

      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(ViewportContextProvider, { topInset: undefined, children }, children);

      const { result } = renderHook(() => TestComponent(), { wrapper });

      expect(result.current.state.topInset).toBe(50);
    });
  });
});
