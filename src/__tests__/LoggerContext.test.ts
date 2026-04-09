import React from 'react';
import { render, act } from '@testing-library/react-native';
import { loggingContext, defaultSetter, Provider, make } from '../contexts/LoggerContext.bs.js';

describe('LoggerContext', () => {
  describe('defaultSetter', () => {
    it('returns undefined when called with no argument', () => {
      const result = defaultSetter();
      expect(result).toBeUndefined();
    });

    it('returns undefined when called with an argument', () => {
      const result = defaultSetter({ key: 'value' });
      expect(result).toBeUndefined();
    });

    it('returns undefined when called with null', () => {
      const result = defaultSetter(null);
      expect(result).toBeUndefined();
    });

    it('returns undefined when called with undefined', () => {
      const result = defaultSetter(undefined);
      expect(result).toBeUndefined();
    });
  });

  describe('loggingContext', () => {
    it('is a React context', () => {
      expect(loggingContext).toBeDefined();
      expect(loggingContext.Provider).toBeDefined();
    });

    it('has default value as array with empty object and setter', () => {
      const defaultValue = loggingContext._currentValue;
      expect(Array.isArray(defaultValue)).toBe(true);
      expect(defaultValue[0]).toEqual({});
      expect(typeof defaultValue[1]).toBe('function');
    });
  });

  describe('Provider', () => {
    it('has make property that is the context Provider', () => {
      expect(Provider).toBeDefined();
      expect(Provider.make).toBeDefined();
      expect(Provider.make).toBe(loggingContext.Provider);
    });
  });

  describe('make (LoggerContext component)', () => {
    it('is a function', () => {
      expect(typeof make).toBe('function');
    });

    it('renders children', () => {
      const { getByText } = render(
        React.createElement(
          make,
          {},
          React.createElement('Text', {}, 'Test Child')
        )
      );

      expect(getByText('Test Child')).toBeDefined();
    });

    it('provides initial state as empty object', () => {
      const TestComponent = () => {
        const context = React.useContext(loggingContext);
        return React.createElement('Text', {}, JSON.stringify(context[0]));
      };

      const { getByText } = render(
        React.createElement(
          make,
          {},
          React.createElement(TestComponent)
        )
      );

      expect(getByText('{}')).toBeDefined();
    });

    it('provides a setter function that updates state', () => {
      const TestComponent = () => {
        const [state, setState] = React.useContext(loggingContext);
        return React.createElement(
          'View',
          {},
          React.createElement('Text', { testID: 'state' }, JSON.stringify(state)),
          React.createElement(
            'Button',
            { testID: 'button', onPress: () => setState({ logLevel: 'error' }) },
            'Update'
          )
        );
      };

      const { getByTestId } = render(
        React.createElement(
          make,
          {},
          React.createElement(TestComponent)
        )
      );

      expect(getByTestId('state').props.children).toBe('{}');

      act(() => {
        getByTestId('button').props.onPress();
      });

      expect(getByTestId('state').props.children).toBe('{"logLevel":"error"}');
    });

    it('state can be updated multiple times', () => {
      const TestComponent = () => {
        const [state, setState] = React.useContext(loggingContext);
        return React.createElement(
          'View',
          {},
          React.createElement('Text', { testID: 'state' }, JSON.stringify(state)),
          React.createElement(
            'Button',
            { testID: 'button1', onPress: () => setState({ first: 'value' }) },
            'First'
          ),
          React.createElement(
            'Button',
            { testID: 'button2', onPress: () => setState({ second: 'value' }) },
            'Second'
          )
        );
      };

      const { getByTestId } = render(
        React.createElement(
          make,
          {},
          React.createElement(TestComponent)
        )
      );

      expect(getByTestId('state').props.children).toBe('{}');

      act(() => {
        getByTestId('button1').props.onPress();
      });
      expect(getByTestId('state').props.children).toBe('{"first":"value"}');

      act(() => {
        getByTestId('button2').props.onPress();
      });
      expect(getByTestId('state').props.children).toBe('{"second":"value"}');
    });

    it('handles nested children', () => {
      const NestedComponent = () => {
        const [state] = React.useContext(loggingContext);
        return React.createElement('Text', { testID: 'nested' }, JSON.stringify(state));
      };

      const { getByTestId } = render(
        React.createElement(
          make,
          {},
          React.createElement(
            'View',
            {},
            React.createElement(NestedComponent)
          )
        )
      );

      expect(getByTestId('nested').props.children).toBe('{}');
    });

    it('setter replaces state completely (not merges)', () => {
      const TestComponent = () => {
        const [state, setState] = React.useContext(loggingContext);
        return React.createElement(
          'View',
          {},
          React.createElement('Text', { testID: 'state' }, JSON.stringify(state)),
          React.createElement(
            'Button',
            { testID: 'button', onPress: () => setState({ newKey: 'newValue' }) },
            'Update'
          )
        );
      };

      const { getByTestId } = render(
        React.createElement(
          make,
          {},
          React.createElement(TestComponent)
        )
      );

      act(() => {
        getByTestId('button').props.onPress();
      });

      expect(getByTestId('state').props.children).toBe('{"newKey":"newValue"}');
    });

    it('handles multiple consumers receiving same state', () => {
      const ConsumerA = () => {
        const [state] = React.useContext(loggingContext);
        return React.createElement('Text', { testID: 'consumer-a' }, JSON.stringify(state));
      };

      const ConsumerB = () => {
        const [state] = React.useContext(loggingContext);
        return React.createElement('Text', { testID: 'consumer-b' }, JSON.stringify(state));
      };

      const { getByTestId } = render(
        React.createElement(
          make,
          {},
          React.createElement(ConsumerA),
          React.createElement(ConsumerB)
        )
      );

      expect(getByTestId('consumer-a').props.children).toBe('{}');
      expect(getByTestId('consumer-b').props.children).toBe('{}');
    });
  });
});
