import { renderHook, act } from '@testing-library/react-native';
import React from 'react';

jest.mock('use-latest-callback', () => ({
  __esModule: true,
  default: jest.fn((callback) => callback),
}));

const mockMeasure = jest.fn();
const mockRef = {
  current: {
    measure: mockMeasure,
  },
};

const { useMeasureLayout } = require('../hooks/MeasureLayoutHook.bs.js');

describe('MeasureLayoutHook', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('useMeasureLayout', () => {
    it('returns initial layout with width and height of 0', () => {
      const ref = { current: null };
      const { result } = renderHook(() => useMeasureLayout(ref, undefined));
      
      const [layout, onLayout] = result.current;
      
      expect(layout).toEqual({ width: 0, height: 0 });
      expect(typeof onLayout).toBe('function');
    });

    it('calls onMeasure callback when measure succeeds', () => {
      const onMeasure = jest.fn();
      mockMeasure.mockImplementation((callback) => {
        callback(0, 0, 100, 200);
      });
      
      renderHook(() => useMeasureLayout(mockRef, onMeasure));
      
      expect(mockMeasure).toHaveBeenCalled();
      expect(onMeasure).toHaveBeenCalledWith({ width: 100, height: 200 });
    });

    it('updates layout state when measure returns new dimensions', () => {
      mockMeasure.mockImplementation((callback) => {
        callback(0, 0, 150, 300);
      });
      
      const { result } = renderHook(() => useMeasureLayout(mockRef, undefined));
      
      expect(result.current[0]).toEqual({ width: 150, height: 300 });
    });

    it('does not update layout when dimensions are the same', () => {
      mockMeasure.mockImplementation((callback) => {
        callback(0, 0, 100, 200);
      });
      
      const { result, rerender } = renderHook(() => useMeasureLayout(mockRef, undefined));
      
      const firstLayout = result.current[0];
      
      rerender();
      
      expect(result.current[0]).toBe(firstLayout);
    });

    it('handles onLayout event and updates layout', () => {
      const ref = { current: null };
      
      const { result } = renderHook(() => useMeasureLayout(ref, undefined));
      
      const onLayout = result.current[1];
      
      act(() => {
        onLayout({
          nativeEvent: {
            layout: { width: 250, height: 400 },
          },
        });
      });
      
      expect(result.current[0]).toEqual({ width: 250, height: 400 });
    });

    it('calls onMeasure from onLayout event', () => {
      const ref = { current: null };
      const onMeasure = jest.fn();
      
      const { result } = renderHook(() => useMeasureLayout(ref, onMeasure));
      
      const onLayout = result.current[1];
      
      act(() => {
        onLayout({
          nativeEvent: {
            layout: { width: 300, height: 500 },
          },
        });
      });
      
      expect(onMeasure).toHaveBeenCalledWith({ width: 300, height: 500 });
    });

    it('handles null ref without crashing', () => {
      const ref = { current: null };
      
      expect(() => {
        renderHook(() => useMeasureLayout(ref, undefined));
      }).not.toThrow();
    });

    it('handles undefined onMeasure callback without crashing', () => {
      mockMeasure.mockImplementation((callback) => {
        callback(0, 0, 100, 200);
      });
      
      expect(() => {
        renderHook(() => useMeasureLayout(mockRef, undefined));
      }).not.toThrow();
    });
  });
});
