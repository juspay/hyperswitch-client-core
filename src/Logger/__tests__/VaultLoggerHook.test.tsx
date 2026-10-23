import React from 'react';
import TestRenderer, {act} from 'react-test-renderer';
import * as Logger from '../sdk/SdkLogger.bs.js';
import {useFieldLogger, useFormLogger} from '../sdk/VaultLoggerHook.bs.js';

jest.mock('../sdk/SdkFunnelLogger.bs.js', () => ({log: jest.fn()}));

jest.mock('../sdk/SdkLogger.bs.js', () => ({logState: jest.fn()}));

const logState = Logger.logState as jest.Mock;
const events = (tag: string) =>
  logState.mock.calls.filter(([event]) => event.TAG === tag);

describe('vault logging lifecycle', () => {
  beforeEach(() => logState.mockClear());

  it('logs mount, provider readiness with latency, and unmount once', () => {
    let ready: () => void;
    function Field() {
      ready = useFieldLogger('cardNumber');
      return null;
    }
    let tree: TestRenderer.ReactTestRenderer;
    act(() => {
      tree = TestRenderer.create(<Field />);
    });
    expect(events('CardFieldMounted')).toHaveLength(1);
    expect(events('CardFieldRendered')).toHaveLength(0);
    act(() => {
      ready();
      ready();
    });
    expect(events('CardFieldRendered')).toHaveLength(1);
    const [event, , , duration] = events('CardFieldRendered')[0];
    expect(event._0).toEqual({scope: 'VaultForm', field: 'cardNumber'});
    expect(duration).toBeGreaterThanOrEqual(0);
    act(() => tree.unmount());
    expect(events('CardFieldUnmounted')).toHaveLength(1);
  });

  it('logs each form completion once and retains only field names', () => {
    let change: (event: any) => void;
    function Form({id}: {id: string}) {
      change = useFormLogger(id);
      return null;
    }
    let tree: TestRenderer.ReactTestRenderer;
    act(() => {
      tree = TestRenderer.create(<Form id="first" />);
    });
    const event = {
      complete: true,
      valid: true,
      fields: {
        cardNumber: {complete: true, valid: true},
        cardExpiry: {complete: true, valid: true},
        cardCvc: {complete: true, valid: true},
      },
      payload: {cardNumber: '4111111111111111', cvc: '123'},
    };
    act(() => {
      change({...event, complete: false});
      change({...event, valid: false});
    });
    expect(events('CardFormCompleted')).toHaveLength(0);
    act(() => {
      change(event);
      change(event);
    });
    expect(events('CardFormCompleted')).toHaveLength(1);
    expect(events('CardFormCompleted')[0][0]._0).toEqual({
      scope: 'VaultForm',
      fields: ['cardNumber', 'cardExpiry', 'cardCvc'],
    });
    expect(JSON.stringify(logState.mock.calls)).not.toContain(
      '4111111111111111',
    );
    expect(JSON.stringify(logState.mock.calls)).not.toContain('123');
    act(() => {
      tree.update(<Form id="second" />);
    });
    act(() =>
      change({...event, fields: {cardCvc: {complete: true, valid: true}}}),
    );
    expect(events('CardFormCompleted')[1][0]._0.fields).toEqual(['cardCvc']);
    act(() => tree.unmount());
    expect(events('CardFormCreated')).toHaveLength(2);
    expect(events('CardFormDestroyed')).toHaveLength(2);
  });
});
