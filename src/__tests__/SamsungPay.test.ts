import React from 'react';
import { render, renderHook } from '@testing-library/react-native';

const mockNativePropContext = React.createContext([{}, jest.fn()]);

jest.mock('../contexts/NativePropContext.bs.js', () => ({
  nativePropContext: mockNativePropContext,
  defaultValue: {},
  defaultSetter: jest.fn(),
  Provider: mockNativePropContext.Provider,
  make: mockNativePropContext.Provider,
}));

jest.mock('../components/common/CustomLoader/CustomLoader.bs.js', () => ({
  make: jest.fn(() => null),
}));

const { isSamsungPayValid, useSamsungPayValidityHook, make, val } = require('../hooks/SamsungPay.bs.js');

describe('SamsungPay', () => {
  describe('isSamsungPayValid', () => {
    it('returns true for valid state "Available"', () => {
      expect(isSamsungPayValid('Available')).toBe(true);
    });

    it('returns true for valid state "Success"', () => {
      expect(isSamsungPayValid('Success')).toBe(true);
    });

    it('returns true for valid state "Ready"', () => {
      expect(isSamsungPayValid('Ready')).toBe(true);
    });

    it('returns false for "Checking" state', () => {
      expect(isSamsungPayValid('Checking')).toBe(false);
    });

    it('returns false for "Not_Started" state', () => {
      expect(isSamsungPayValid('Not_Started')).toBe(false);
    });

    it('returns true for any other string state', () => {
      expect(isSamsungPayValid('SomeOtherState')).toBe(true);
    });

    it('returns true for empty string', () => {
      expect(isSamsungPayValid('')).toBe(true);
    });

    it('handles case-sensitive "checking" as valid', () => {
      expect(isSamsungPayValid('checking')).toBe(true);
    });

    it('handles case-sensitive "not_started" as valid', () => {
      expect(isSamsungPayValid('not_started')).toBe(true);
    });
  });

  describe('val', () => {
    it('exports val object with initial contents', () => {
      expect(val).toBeDefined();
      expect(val.contents).toBe('Not_Started');
    });
  });

  describe('useSamsungPayValidityHook', () => {
    const createWrapper = (nativeProp: any) => {
      return ({ children }: { children: React.ReactNode }) => {
        return React.createElement(
          mockNativePropContext.Provider,
          { value: [nativeProp, jest.fn()] as any },
          children,
        );
      };
    };

    it('returns the current state value from useState', () => {
      const nativeProp = {
        hyperParams: { deviceBrand: 'samsung' },
      };
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => useSamsungPayValidityHook(), { wrapper });

      expect(result.current).toBe('Not_Started');
    });

    it('works when deviceBrand is samsung', () => {
      const nativeProp = {
        hyperParams: { deviceBrand: 'samsung' },
      };
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => useSamsungPayValidityHook(), { wrapper });

      expect(typeof result.current).toBe('string');
    });

    it('works when deviceBrand is not samsung', () => {
      const nativeProp = {
        hyperParams: { deviceBrand: 'apple' },
      };
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => useSamsungPayValidityHook(), { wrapper });

      expect(result.current).toBe('Not_Started');
    });

    it('handles empty deviceBrand string', () => {
      const nativeProp = {
        hyperParams: { deviceBrand: '' },
      };
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => useSamsungPayValidityHook(), { wrapper });

      expect(result.current).toBe('Not_Started');
    });

    it('handles undefined deviceBrand value', () => {
      const nativeProp = {
        hyperParams: { deviceBrand: undefined },
      };
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => useSamsungPayValidityHook(), { wrapper });

      expect(result.current).toBe('Not_Started');
    });
  });

  describe('make (SamsungPay component)', () => {
    const createWrapper = (nativeProp: any) => {
      return ({ children }: { children: React.ReactNode }) => {
        return React.createElement(
          mockNativePropContext.Provider,
          { value: [nativeProp, jest.fn()] as any },
          children,
        );
      };
    };

    it('renders null when samsungPayStatus is not "Checking"', () => {
      const nativeProp = {
        hyperParams: { deviceBrand: 'samsung' },
      };
      const wrapper = createWrapper(nativeProp);

      const { toJSON } = render(React.createElement(make), { wrapper });

      expect(toJSON()).toBeNull();
    });

    it('renders CustomLoader when samsungPayStatus is "Checking"', () => {
      const CustomLoader = require('../components/common/CustomLoader/CustomLoader.bs.js');
      CustomLoader.make.mockReturnValue(React.createElement('View', { testID: 'custom-loader' }));

      const nativeProp = {
        hyperParams: { deviceBrand: 'samsung' },
      };
      const wrapper = createWrapper(nativeProp);

      val.contents = 'Checking';

      const { queryByTestId } = render(React.createElement(make), { wrapper });

      expect(queryByTestId('custom-loader')).not.toBeNull();

      val.contents = 'Not_Started';
    });

    it('does not render CustomLoader when status is "Available"', () => {
      const nativeProp = {
        hyperParams: { deviceBrand: 'samsung' },
      };
      const wrapper = createWrapper(nativeProp);

      val.contents = 'Available';

      const { toJSON } = render(React.createElement(make), { wrapper });

      expect(toJSON()).toBeNull();

      val.contents = 'Not_Started';
    });

    it('does not render CustomLoader when status is "Success"', () => {
      const nativeProp = {
        hyperParams: { deviceBrand: 'samsung' },
      };
      const wrapper = createWrapper(nativeProp);

      val.contents = 'Success';

      const { toJSON } = render(React.createElement(make), { wrapper });

      expect(toJSON()).toBeNull();

      val.contents = 'Not_Started';
    });

    it('renders null when status is "Not_Started"', () => {
      const nativeProp = {
        hyperParams: { deviceBrand: 'samsung' },
      };
      const wrapper = createWrapper(nativeProp);

      val.contents = 'Not_Started';

      const { toJSON } = render(React.createElement(make), { wrapper });

      expect(toJSON()).toBeNull();
    });
  });
});
