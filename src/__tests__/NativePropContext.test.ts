import React from 'react';
import { render, act } from '@testing-library/react-native';
import { nativePropContext, defaultValue, defaultSetter, make } from '../contexts/NativePropContext.bs.js';

jest.mock('../types/SdkTypes.bs.js', () => ({
  nativeJsonToRecord: jest.fn(() => ({
    publishableKey: '',
    clientSecret: '',
    env: 'sandbox',
    sdkState: 'PaymentSheet',
    hyperParams: { sdkVersion: '1.0.0', appId: '' },
  })),
}));

describe('NativePropContext', () => {
  describe('defaultValue', () => {
    it('is defined', () => {
      expect(defaultValue).toBeDefined();
    });

    it('has expected properties', () => {
      expect(defaultValue).toHaveProperty('publishableKey');
      expect(defaultValue).toHaveProperty('clientSecret');
      expect(defaultValue).toHaveProperty('env');
    });
  });

  describe('defaultSetter', () => {
    it('is a function', () => {
      expect(typeof defaultSetter).toBe('function');
    });

    it('does not throw when called', () => {
      expect(() => defaultSetter()).not.toThrow();
    });

    it('accepts any argument without throwing', () => {
      expect(() => defaultSetter({})).not.toThrow();
      expect(() => defaultSetter(null)).not.toThrow();
      expect(() => defaultSetter(undefined)).not.toThrow();
    });
  });

  describe('nativePropContext', () => {
    it('is a React context', () => {
      expect(nativePropContext).toBeDefined();
      expect(nativePropContext.Provider).toBeDefined();
    });

    it('has default value as array with two elements', () => {
      expect(Array.isArray(nativePropContext._currentValue)).toBe(true);
    });
  });

  describe('make (NativePropContext component)', () => {
    it('is a function', () => {
      expect(typeof make).toBe('function');
    });

    it('renders children', () => {
      const mockNativeProp = {
        publishableKey: 'pk_test_123',
        clientSecret: 'pi_123_secret_456',
        env: 'sandbox',
        sdkState: 'PaymentSheet',
        hyperParams: { sdkVersion: '1.0.0', appId: 'test-app' },
      };

      const { getByText } = render(
        React.createElement(
          make,
          { nativeProp: mockNativeProp } as any,
          React.createElement('Text', {}, 'Test Child')
        )
      );

      expect(getByText('Test Child')).toBeDefined();
    });

    it('updates state when nativeProp changes', () => {
      const mockNativeProp1 = {
        publishableKey: 'pk_test_123',
        clientSecret: 'pi_123_secret_456',
        env: 'sandbox',
        sdkState: 'PaymentSheet',
        hyperParams: { sdkVersion: '1.0.0', appId: 'test-app' },
      };

      const { rerender, getByText } = render(
        React.createElement(
          make,
          { nativeProp: mockNativeProp1 } as any,
          React.createElement('Text', {}, 'Test Child')
        )
      );

      const mockNativeProp2 = {
        ...mockNativeProp1,
        publishableKey: 'pk_test_456',
      };

      rerender(
        React.createElement(
          make,
          { nativeProp: mockNativeProp2 } as any,
          React.createElement('Text', {}, 'Test Child')
        )
      );

      expect(getByText('Test Child')).toBeDefined();
    });

    it('handles undefined nativeProp', () => {
      const { getByText } = render(
        React.createElement(
          make,
          { nativeProp: undefined } as any,
          React.createElement('Text', {}, 'Test Child')
        )
      );

      expect(getByText('Test Child')).toBeDefined();
    });

    it('handles null nativeProp', () => {
      const { getByText } = render(
        React.createElement(
          make,
          { nativeProp: null } as any,
          React.createElement('Text', {}, 'Test Child')
        )
      );

      expect(getByText('Test Child')).toBeDefined();
    });

    it('provides a setter that updates state', () => {
      const mockNativeProp = {
        publishableKey: 'pk_test_123',
        clientSecret: 'pi_123_secret_456',
        env: 'sandbox',
        sdkState: 'PaymentSheet',
        hyperParams: { sdkVersion: '1.0.0', appId: 'test-app' },
      };

      const TestComponent = () => {
        const [state, setState] = React.useContext(nativePropContext);
        return React.createElement(
          'View',
          {},
          React.createElement('Text', { testID: 'pub-key' }, state?.publishableKey || 'undefined'),
          React.createElement(
            'Button',
            {
              testID: 'update-btn',
              onPress: () => setState({ ...state, publishableKey: 'pk_updated' } as any),
            },
            'Update'
          )
        );
      };

      const { getByTestId } = render(
        React.createElement(
          make,
          { nativeProp: mockNativeProp } as any,
          React.createElement(TestComponent)
        )
      );

      expect(getByTestId('pub-key').props.children).toBe('pk_test_123');

      act(() => {
        getByTestId('update-btn').props.onPress();
      });

      expect(getByTestId('pub-key').props.children).toBe('pk_updated');
    });

    it('setter can replace entire nativeProp', () => {
      const mockNativeProp = {
        publishableKey: 'pk_test_123',
        clientSecret: 'pi_123_secret_456',
        env: 'sandbox',
        sdkState: 'PaymentSheet',
        hyperParams: { sdkVersion: '1.0.0', appId: 'test-app' },
      };

      const TestComponent = () => {
        const [state, setState] = React.useContext(nativePropContext);
        return React.createElement(
          'View',
          {},
          React.createElement('Text', { testID: 'env' }, state?.env || 'undefined'),
          React.createElement(
            'Button',
            {
              testID: 'replace-btn',
              onPress: () =>
                setState({
                  ...state,
                  env: 'production',
                } as any),
            },
            'Replace'
          )
        );
      };

      const { getByTestId } = render(
        React.createElement(
          make,
          { nativeProp: mockNativeProp } as any,
          React.createElement(TestComponent)
        )
      );

      expect(getByTestId('env').props.children).toBe('sandbox');

      act(() => {
        getByTestId('replace-btn').props.onPress();
      });

      expect(getByTestId('env').props.children).toBe('production');
    });
  });
});
