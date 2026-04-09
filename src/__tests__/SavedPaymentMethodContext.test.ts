import { renderHook, act } from '@testing-library/react-native';
import {
  savedPaymentMethodDataContext,
  defaultVal,
  make as SavedPaymentMethodContextProvider,
} from '../contexts/SavedPaymentMethodContext.bs.js';
import React from 'react';

describe('SavedPaymentMethodContext', () => {
  describe('defaultVal', () => {
    it('is undefined by default', () => {
      expect(defaultVal).toBeUndefined();
    });
  });

  describe('savedPaymentMethodDataContext', () => {
    it('is defined as a React context', () => {
      expect(savedPaymentMethodDataContext).toBeDefined();
      expect(savedPaymentMethodDataContext.Provider).toBeDefined();
    });

    it('has default value with undefined state', () => {
      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(savedPaymentMethodDataContext.Provider, { value: [undefined, jest.fn()] }, children);

      const { result } = renderHook(() => React.useContext(savedPaymentMethodDataContext), { wrapper });

      expect(result.current[0]).toBeUndefined();
      expect(typeof result.current[1]).toBe('function');
    });
  });

  describe('SavedPaymentMethodContext Provider', () => {
    it('provides initial state as undefined', () => {
      const TestComponent = () => {
        const [state, setState] = React.useContext(savedPaymentMethodDataContext);
        return { state, setState };
      };

      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(SavedPaymentMethodContextProvider, { children }, children);

      const { result } = renderHook(() => TestComponent(), { wrapper });

      expect(result.current.state).toBeUndefined();
    });

    it('allows state to be updated via setter', () => {
      const TestComponent = () => {
        const [state, setState] = React.useContext(savedPaymentMethodDataContext);
        return { state, setState };
      };

      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(SavedPaymentMethodContextProvider, { children }, children);

      const { result } = renderHook(() => TestComponent(), { wrapper });

      const paymentMethod = { id: 'pm_123', card: { last4: '4242' } };

      act(() => {
        result.current.setState(paymentMethod);
      });

      expect(result.current.state).toEqual(paymentMethod);
    });

    it('can update state multiple times', () => {
      const TestComponent = () => {
        const [state, setState] = React.useContext(savedPaymentMethodDataContext);
        return { state, setState };
      };

      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(SavedPaymentMethodContextProvider, { children }, children);

      const { result } = renderHook(() => TestComponent(), { wrapper });

      const firstPaymentMethod = { id: 'pm_123', card: { last4: '4242' } };
      const secondPaymentMethod = { id: 'pm_456', card: { last4: '1234' } };

      act(() => {
        result.current.setState(firstPaymentMethod);
      });
      expect(result.current.state).toEqual(firstPaymentMethod);

      act(() => {
        result.current.setState(secondPaymentMethod);
      });
      expect(result.current.state).toEqual(secondPaymentMethod);
    });

    it('can set state to null', () => {
      const TestComponent = () => {
        const [state, setState] = React.useContext(savedPaymentMethodDataContext);
        return { state, setState };
      };

      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(SavedPaymentMethodContextProvider, { children }, children);

      const { result } = renderHook(() => TestComponent(), { wrapper });

      act(() => {
        result.current.setState({ id: 'pm_123' });
      });
      expect(result.current.state).toEqual({ id: 'pm_123' });

      act(() => {
        result.current.setState(null);
      });
      expect(result.current.state).toBeNull();
    });

    it('setter function returns the value passed to it', () => {
      const TestComponent = () => {
        const [state, setState] = React.useContext(savedPaymentMethodDataContext);
        return { state, setState };
      };

      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(SavedPaymentMethodContextProvider, { children }, children);

      const { result } = renderHook(() => TestComponent(), { wrapper });

      const paymentMethod = { id: 'pm_789' };

      act(() => {
        result.current.setState(paymentMethod);
      });

      expect(result.current.state).toBe(paymentMethod);
    });
  });
});
