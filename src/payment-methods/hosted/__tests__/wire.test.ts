import { describe, it, expect } from '@jest/globals';

import { FieldEvent, FormEvent } from '../protocol';
import { WIRE_SHAPES, toWire } from '../wire';

const PAN = '4242424242424242';
const CVC = '737';

const fieldChange = {
  elementType: 'cardNumber',
  empty: false,
  complete: true,
  valid: true,
  brand: 'visa',
  touched: true,
};

describe('what may leave the engine', () => {
  it('has a rule for every event the protocol names', () => {
    const named = [...Object.values(FieldEvent), ...Object.values(FormEvent)];
    expect(Object.keys(WIRE_SHAPES).sort()).toEqual([...named].sort());
  });

  it('drops any key a field change is not allowed to carry', () => {
    const sent = toWire(FieldEvent.Change, {
      ...fieldChange,
      value: PAN,
      cardNumber: PAN,
      cvc: CVC,
      raw: { number: PAN },
    });

    expect(sent).toEqual(fieldChange);
    expect(JSON.stringify(sent)).not.toContain(PAN);
    expect(JSON.stringify(sent)).not.toContain(CVC);
  });

  it('applies the same rule inside a form change, at every level', () => {
    const sent = toWire(FormEvent.Change, {
      elementType: 'cardForm',
      eventName: 'cardDetailsChange',
      payload: { bin: '424242', last4: '4242', brand: 'visa', number: PAN },
      complete: true,
      valid: true,
      fields: {
        cardNumber: { ...fieldChange, value: PAN },
        cardCvc: { ...fieldChange, elementType: 'cardCvc', value: CVC },
      },
      state: { cardNumber: PAN, cvc: CVC },
    });

    expect(sent).toEqual({
      elementType: 'cardForm',
      eventName: 'cardDetailsChange',
      payload: { bin: '424242', last4: '4242', brand: 'visa' },
      complete: true,
      valid: true,
      fields: {
        cardNumber: fieldChange,
        cardCvc: { ...fieldChange, elementType: 'cardCvc' },
      },
    });
    expect(JSON.stringify(sent)).not.toContain(PAN);
  });

  it('keeps only the message of an error, never the thing that failed', () => {
    expect(
      toWire(FormEvent.Error, {
        message: 'The vault refused the card.',
        request: { body: { card_number: PAN } },
      })
    ).toEqual({ message: 'The vault refused the card.' });
  });

  it('passes a tokenize result whole, as in-process callers receive it', () => {
    const result = {
      status: 'success',
      vaultType: 'vgs',
      data: { tokens: { card_number: 'tok_1' } },
      card: { last4: '4242', brand: 'visa' },
    };
    expect(
      toWire(FormEvent.CommandResult, {
        commandId: 'c1',
        name: 'tokenize',
        ok: true,
        result,
        debug: { number: PAN },
      })
    ).toEqual({ commandId: 'c1', name: 'tokenize', ok: true, result });
  });

  it('sends only what a native map can hold', () => {
    expect(
      toWire(FieldEvent.Change, {
        ...fieldChange,
        brand: undefined,
        error: undefined,
      })
    ).toEqual({
      elementType: 'cardNumber',
      empty: false,
      complete: true,
      valid: true,
      touched: true,
    });

    const circular: Record<string, unknown> = { commandId: 'c1' };
    circular.result = circular;
    expect(toWire(FormEvent.CommandResult, circular)).toEqual({});
  });
});
