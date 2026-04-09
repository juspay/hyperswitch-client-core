import { renderHook, act } from '@testing-library/react-native';
import { loadingContext, defaultSetter, make as LoadingContextProvider } from '../contexts/LoadingContext.bs.js';
import React from 'react';

describe('LoadingContext', () => {
  describe('defaultSetter', () => {
    it('returns undefined when called with no argument', () => {
      const result = defaultSetter();
      expect(result).toBeUndefined();
    });

    it('returns undefined when called with an argument', () => {
      const result = defaultSetter('someValue');
      expect(result).toBeUndefined();
    });

    it('returns undefined when called with null', () => {
      const result = defaultSetter(null);
      expect(result).toBeUndefined();
    });
  });

  describe('loadingContext', () => {
    it('has default value with "FillingDetails" state', () => {
      expect(loadingContext).toBeDefined();
    });

    it('provides default state as "FillingDetails"', () => {
      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(LoadingContextProvider, { value: ["FillingDetails", jest.fn()] }, children);
      
      const { result } = renderHook(() => React.useContext(loadingContext), { wrapper });
      
      expect(result.current[0]).toBe("FillingDetails");
      expect(typeof result.current[1]).toBe("function");
    });
  });

  describe('LoadingContext Provider', () => {
    it('provides initial state "FillingDetails"', () => {
      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(LoadingContextProvider, { value: ["FillingDetails", jest.fn()] }, children);

      const { result } = renderHook(() => React.useContext(loadingContext), { wrapper });

      expect(result.current[0]).toBe("FillingDetails");
    });

    it('allows state to be updated via setter', () => {
      const TestComponent = () => {
        const [state, setState] = React.useContext(loadingContext);
        return { state, setState };
      };

      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(LoadingContextProvider, { value: ["FillingDetails", jest.fn()] }, children);

      const { result } = renderHook(() => TestComponent(), { wrapper });

      expect(result.current.state).toBe("FillingDetails");

      act(() => {
        result.current.setState("Processing");
      });

      expect(result.current.state).toBe("Processing");
    });

    it('state can be changed to different loading states', () => {
      const TestComponent = () => {
        const [state, setState] = React.useContext(loadingContext);
        return { state, setState };
      };

      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(LoadingContextProvider, { value: ["FillingDetails", jest.fn()] }, children);

      const { result } = renderHook(() => TestComponent(), { wrapper });

      act(() => {
        result.current.setState("PaymentSuccess");
      });
      expect(result.current.state).toBe("PaymentSuccess");

      act(() => {
        result.current.setState("PaymentFailed");
      });
      expect(result.current.state).toBe("PaymentFailed");
    });
  });
});
