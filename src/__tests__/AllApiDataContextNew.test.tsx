import * as React from 'react';
import { renderHook } from '@testing-library/react-native';
import { allApiDataContext, make as AllApiDataContextNew } from '../contexts/AllApiDataContextNew.bs.js';

describe('AllApiDataContextNew', () => {
  describe('allApiDataContext', () => {
    it('has default value as array of three undefined values', () => {
      expect(allApiDataContext).toBeDefined();
      expect(allApiDataContext._currentValue).toEqual([undefined, undefined, undefined]);
    });

    it('is a React context object', () => {
      expect(allApiContext.Provider).toBeDefined();
      expect(allApiContext.Consumer).toBeDefined();
    });

    it('allows consuming context value via useContext', () => {
      const { result } = renderHook(() => React.useContext(allApiDataContext));
      expect(result.current).toEqual([undefined, undefined, undefined]);
    });
  });

  describe('AllApiDataContextNew component', () => {
    it('provides accountPaymentMethodData, customerPaymentMethodData, and sessionTokenData to children', () => {
      const mockAccountData = { methods: ['card', 'wallet'] };
      const mockCustomerData = { savedCards: [] };
      const mockSessionToken = 'test-session-token';

      const wrapper = ({ children }: { children: React.ReactNode }) => (
        <AllApiDataContextNew
          accountPaymentMethodData={mockAccountData}
          customerPaymentMethodData={mockCustomerData}
          sessionTokenData={mockSessionToken}
        >
          {children}
        </AllApiDataContextNew>
      );

      const { result } = renderHook(() => React.useContext(allApiDataContext), { wrapper });

      expect(result.current[0]).toEqual(mockAccountData);
      expect(result.current[1]).toEqual(mockCustomerData);
      expect(result.current[2]).toEqual(mockSessionToken);
    });

    it('allows children to be null or undefined', () => {
      const wrapper = ({ children }: { children: React.ReactNode }) => (
        <AllApiDataContextNew
          accountPaymentMethodData={{}}
          customerPaymentMethodData={{}}
          sessionTokenData=""
        >
          {children}
        </AllApiDataContextNew>
      );

      const { result } = renderHook(() => React.useContext(allApiDataContext), { wrapper });

      expect(result.current[0]).toEqual({});
      expect(result.current[1]).toEqual({});
      expect(result.current[2]).toBe('');
    });

    it('handles undefined prop values', () => {
      const wrapper = ({ children }: { children: React.ReactNode }) => (
        <AllApiDataContextNew
          accountPaymentMethodData={undefined}
          customerPaymentMethodData={undefined}
          sessionTokenData={undefined}
        >
          {children}
        </AllApiDataContextNew>
      );

      const { result } = renderHook(() => React.useContext(allApiDataContext), { wrapper });

      expect(result.current[0]).toBeUndefined();
      expect(result.current[1]).toBeUndefined();
      expect(result.current[2]).toBeUndefined();
    });
  });
});

const allApiContext = allApiDataContext;
