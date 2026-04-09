import { renderHook } from '@testing-library/react-native';
import ReactNative from 'react-native';

jest.mock('react-native', () => ({
  Animated: {
    Value: jest.fn().mockImplementation((initialValue: number) => ({
      _value: initialValue,
      setValue: jest.fn(),
      interpolate: jest.fn(),
    })),
  },
}));

import { useAnimatedValue } from '../hooks/AnimatedValue.bs.js';

describe('AnimatedValue', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('useAnimatedValue', () => {
    it('creates an Animated.Value with the provided initial value', () => {
      const { result } = renderHook(() => useAnimatedValue(0));
      expect(ReactNative.Animated.Value).toHaveBeenCalledWith(0);
      expect(result.current).toBeDefined();
      expect(result.current._value).toBe(0);
    });

    it('creates an Animated.Value with a positive initial value', () => {
      const { result } = renderHook(() => useAnimatedValue(100));
      expect(ReactNative.Animated.Value).toHaveBeenCalledWith(100);
      expect(result.current._value).toBe(100);
    });

    it('creates an Animated.Value with a negative initial value', () => {
      const { result } = renderHook(() => useAnimatedValue(-50));
      expect(ReactNative.Animated.Value).toHaveBeenCalledWith(-50);
      expect(result.current._value).toBe(-50);
    });

    it('creates an Animated.Value with a decimal initial value', () => {
      const { result } = renderHook(() => useAnimatedValue(0.5));
      expect(ReactNative.Animated.Value).toHaveBeenCalledWith(0.5);
      expect(result.current._value).toBe(0.5);
    });

    it('returns the same Animated.Value instance on re-renders', () => {
      const { result, rerender } = renderHook(() => useAnimatedValue(10));
      const firstResult = result.current;
      rerender({});
      const secondResult = result.current;
      expect(firstResult).toBe(secondResult);
    });

    it('creates an Animated.Value with zero as initial value', () => {
      const { result } = renderHook(() => useAnimatedValue(0));
      expect(result.current._value).toBe(0);
    });

    it('returns an object with _value property matching the initial value', () => {
      const initialValue = 42;
      const { result } = renderHook(() => useAnimatedValue(initialValue));
      expect(result.current).toHaveProperty('_value', initialValue);
    });

    it('handles very large initial values', () => {
      const largeValue = 999999.99;
      const { result } = renderHook(() => useAnimatedValue(largeValue));
      expect(ReactNative.Animated.Value).toHaveBeenCalledWith(largeValue);
      expect(result.current._value).toBe(largeValue);
    });

    it('handles very small decimal initial values', () => {
      const smallValue = 0.0001;
      const { result } = renderHook(() => useAnimatedValue(smallValue));
      expect(ReactNative.Animated.Value).toHaveBeenCalledWith(smallValue);
      expect(result.current._value).toBe(smallValue);
    });
  });
});
