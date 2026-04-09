const mockTiming = jest.fn();
const mockAnimationStart = jest.fn();

jest.mock('react-native', () => ({
  Animated: {
    timing: mockTiming,
    Value: jest.fn((initialValue: number) => ({
      _value: initialValue,
      setValue: jest.fn(),
      stopTracking: jest.fn(),
      interpolate: jest.fn(),
    })),
  },
}));

mockTiming.mockImplementation(() => ({
  start: mockAnimationStart,
}));

const { animateFlex } = require('../utility/logics/AnimationUtils.bs.js');

describe('AnimationUtils', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockAnimationStart.mockImplementation((callback: (result: { finished: boolean }) => void) => {
      if (callback) callback({ finished: true });
    });
  });

  describe('animateFlex', () => {
    it('calls Animated.timing with correct parameters', () => {
      const flexval = { _value: 0, stopTracking: jest.fn() } as any;
      const targetValue = 1;
      const endCallback = jest.fn();

      animateFlex(flexval, targetValue, endCallback, undefined);

      expect(mockTiming).toHaveBeenCalledWith(flexval, {
        toValue: targetValue,
        useNativeDriver: false,
        delay: 0,
        isInteraction: true,
      });
    });

    it('calls start on the animation with the callback', () => {
      const flexval = { _value: 0, stopTracking: jest.fn() } as any;
      const targetValue = 0.5;
      const endCallback = jest.fn();

      animateFlex(flexval, targetValue, endCallback, undefined);

      expect(mockAnimationStart).toHaveBeenCalled();
    });

    it('executes the endCallback when animation completes', () => {
      const flexval = { _value: 0, stopTracking: jest.fn() } as any;
      const targetValue = 1;
      const endCallback = jest.fn();

      animateFlex(flexval, targetValue, endCallback, undefined);

      const startCallback = mockAnimationStart.mock.calls[0][0];
      startCallback({ finished: true });

      expect(endCallback).toHaveBeenCalledWith({ finished: true });
    });

    it('uses default empty callback when endCallback is undefined', () => {
      const flexval = { _value: 0, stopTracking: jest.fn() } as any;
      const targetValue = 1;

      expect(() => animateFlex(flexval, targetValue, undefined, undefined)).not.toThrow();
      expect(mockAnimationStart).toHaveBeenCalled();
    });

    it('handles zero as target value', () => {
      const flexval = { _value: 1, stopTracking: jest.fn() } as any;
      const targetValue = 0;
      const endCallback = jest.fn();

      animateFlex(flexval, targetValue, endCallback, undefined);

      expect(mockTiming).toHaveBeenCalledWith(
        flexval,
        expect.objectContaining({ toValue: 0 })
      );
    });

    it('handles negative target value', () => {
      const flexval = { _value: 0, stopTracking: jest.fn() } as any;
      const targetValue = -1;
      const endCallback = jest.fn();

      animateFlex(flexval, targetValue, endCallback, undefined);

      expect(mockTiming).toHaveBeenCalledWith(
        flexval,
        expect.objectContaining({ toValue: -1 })
      );
    });

    it('handles large target value', () => {
      const flexval = { _value: 0, stopTracking: jest.fn() } as any;
      const targetValue = 100;
      const endCallback = jest.fn();

      animateFlex(flexval, targetValue, endCallback, undefined);

      expect(mockTiming).toHaveBeenCalledWith(
        flexval,
        expect.objectContaining({ toValue: 100 })
      );
    });

    it('passes useNativeDriver: false in timing config', () => {
      const flexval = { _value: 0, stopTracking: jest.fn() } as any;
      const targetValue = 1;

      animateFlex(flexval, targetValue, jest.fn(), undefined);

      expect(mockTiming).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({ useNativeDriver: false })
      );
    });

    it('passes delay: 0 in timing config', () => {
      const flexval = { _value: 0, stopTracking: jest.fn() } as any;
      const targetValue = 1;

      animateFlex(flexval, targetValue, jest.fn(), undefined);

      expect(mockTiming).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({ delay: 0 })
      );
    });

    it('passes isInteraction: true in timing config', () => {
      const flexval = { _value: 0, stopTracking: jest.fn() } as any;
      const targetValue = 1;

      animateFlex(flexval, targetValue, jest.fn(), undefined);

      expect(mockTiming).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({ isInteraction: true })
      );
    });
  });
});
