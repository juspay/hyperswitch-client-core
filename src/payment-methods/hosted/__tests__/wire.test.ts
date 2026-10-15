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
      payload: {
        bin: '424242',
        last4: '4242',
        brand: 'visa',
        isCardNumberComplete: true,
        isCardNumberValid: true,
        number: PAN,
      },
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
      payload: {
        bin: '424242',
        brand: 'visa',
        isCardNumberComplete: true,
        isCardNumberValid: true,
      },
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

  it('passes the tokens and card summary of a tokenize result', () => {
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

  it('strikes a card number out of any message', () => {
    const spaced = '4242 4242 4242 4242';
    for (const [event, payload] of [
      [FormEvent.Error, { message: `Vault said: ${PAN} was refused` }],
      [FieldEvent.Error, { message: `bad ${spaced}` }],
      [FieldEvent.Change, { elementType: 'cardNumber', error: `no ${PAN}` }],
      [
        FormEvent.CommandResult,
        {
          commandId: 'c',
          message: PAN,
          result: { status: 'error', error: { code: 'x', message: `e ${PAN}`, type: 't' } },
        },
      ],
    ] as const) {
      const sent = JSON.stringify(toWire(event, payload));
      expect(sent).not.toContain(PAN);
      expect(sent).not.toContain(spaced);
      expect(sent).toContain('[redacted]');
    }
    /* Shorter numbers are left alone. */
    const harmless = 'HTTP 404 at 12:30:45 on 2026-09-21, code 4012888888, 3 of 12';
    expect(toWire(FormEvent.Error, { message: harmless })).toEqual({
      message: harmless,
    });
  });

  it('is not fooled by how a card number is written or what stands next to it', () => {
    const disguised = [
      `${PAN} 12/29`,
      `card ${PAN}123`,
      '4242.4242.4242.4242',
      '4242/4242/4242/4242',
      '4242  4242  4242  4242',
      '4242\u00a04242\u00a04242\u00a04242',
      '4242\n4242\n4242\n4242',
      '4242 - 4242 - 4242 - 4242',
      '\uff14\uff12\uff14\uff12\uff14\uff12\uff14\uff12\uff14\uff12\uff14\uff12\uff14\uff12\uff14\uff12',
      '4000056655665556',
      '378282246310005',
      '6200000000000000005',
    ];
    for (const text of disguised) {
      const sent = toWire(FormEvent.Error, { message: `refused: ${text}!` }) as {
        message: string;
      };
      expect(sent.message).toContain('[redacted]');
      expect(sent.message.replace(/\D/g, '').length).toBeLessThan(13);
    }
  });

  it('searches every text it passes, whichever key it sits under', () => {
    const sent = toWire(FormEvent.Change, {
      elementType: PAN,
      eventName: PAN,
      payload: {
        bin: PAN,
        extendedBin: PAN,
        last4: PAN,
        brand: PAN,
        expiryMonth: PAN,
        expiryYear: PAN,
        formattedExpiry: PAN,
        isCardNumberComplete: true,
        isCardNumberValid: true,
      },
      fields: { cardNumber: { elementType: PAN, brand: PAN, error: PAN } },
    });
    expect(JSON.stringify(sent)).not.toContain(PAN);

    const result = toWire(FormEvent.CommandResult, {
      commandId: PAN,
      name: PAN,
      result: {
        status: PAN,
        vaultType: PAN,
        card: { bin: PAN, last4: PAN, brand: PAN },
        error: { code: PAN, type: PAN, message: PAN },
        data: { savedCard: { paymentMethodToken: PAN } },
      },
    });
    expect(JSON.stringify(result)).not.toContain(PAN);
  });

  it('passes numbers, booleans and null, and nothing else, where text is expected', () => {
    expect(
      toWire(FieldEvent.Change, {
        elementType: { nested: PAN },
        brand: [PAN],
        error: () => PAN,
        empty: false,
        valid: null,
      })
    ).toEqual({ empty: false, valid: null });
    expect(toWire(FieldEvent.Layout, { width: 10, height: Infinity })).toEqual({
      width: 10,
    });
  });

  it('cuts a text to a sane length', () => {
    const sent = toWire(FormEvent.Error, { message: 'x'.repeat(5000) }) as {
      message: string;
    };
    expect(sent.message).toHaveLength(512);
  });

  it('never passes a last four in a change, whatever state the number is in', () => {
    const summary = { bin: '424242', extendedBin: '42424242', last4: '4242', brand: 'Visa' };
    const sentWith = (flags: object) =>
      (
        toWire(FormEvent.Change, { payload: { ...summary, ...flags } }) as {
          payload: Record<string, unknown>;
        }
      ).payload;

    for (const flags of [
      { isCardNumberComplete: true, isCardNumberValid: true },
      { isCardNumberComplete: true, isCardNumberValid: false },
      { isCardNumberComplete: false, isCardNumberValid: true },
      {},
    ]) {
      const sent = sentWith(flags);
      expect(sent).not.toHaveProperty('last4');
      expect(sent.bin).toBe('424242');
      expect(sent.extendedBin).toBe('42424242');
    }
    /* The last four do cross once, on the tokenize result, as the vault reported them. */
    const result = toWire(FormEvent.CommandResult, {
      commandId: 'c1',
      result: { status: 'success', card: { bin: '424242', last4: '4242' } },
    }) as { result: { card: Record<string, unknown> } };
    expect(result.result.card).toEqual({ bin: '424242', last4: '4242' });
  });

  it('follows PCI truncation: six digits, not eight, of a number shorter than sixteen', () => {
    for (const brand of ['AmericanExpress', 'AMEX', 'amex', 'American Express', 'DinersClub', 'DINERSCLUB']) {
      const sent = toWire(FormEvent.Change, {
        payload: { bin: '378282', extendedBin: '37828224', brand },
      }) as { payload: Record<string, unknown> };
      expect(sent.payload.extendedBin).toBeNull();
      expect(sent.payload.bin).toBe('378282');
    }
    const visa = toWire(FormEvent.Change, {
      payload: { bin: '424242', extendedBin: '42424242', brand: 'Visa' },
    }) as { payload: Record<string, unknown> };
    expect(visa.payload.extendedBin).toBe('42424242');
  });

  it('returns a command id as it was sent, digits and all', () => {
    const id = '12345678-1234-1234-1234-123456789012';
    expect(toWire(FormEvent.CommandResult, { commandId: id, ok: true })).toEqual({
      commandId: id,
      ok: true,
    });
  });

  it('reads only its own rules, not what every object inherits', () => {
    const payload = JSON.parse(
      `{"constructor":{"prototype":"${PAN}"},"__proto__":{"message":"${PAN}"},"toString":"${PAN}","message":"ok"}`
    ) as object;
    expect(toWire(FormEvent.Error, payload)).toEqual({ message: 'ok' });
  });

  it("drops the provider's raw response and anything unlisted from a tokenize result", () => {
    const sent = toWire(FormEvent.CommandResult, {
      commandId: 'c1',
      name: 'tokenize',
      ok: true,
      result: {
        status: 'success',
        vaultType: 'vgs',
        data: {
          tokens: { card_number: 'tok_1' },
          raw: { echoed: { card_number: PAN, card_cvc: '123' } },
          request: { card_number: PAN },
        },
        card: { last4: '4242', number: PAN, cvc: '123' },
        error: { code: 'x', message: 'm', type: 't', cause: { body: PAN } },
        number: PAN,
      },
    });
    expect(JSON.stringify(sent)).not.toContain(PAN);
    expect(JSON.stringify(sent)).not.toContain('raw');
    expect(sent).toMatchObject({
      result: { data: { tokens: { card_number: 'tok_1' } }, card: { last4: '4242' } },
    });
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

    /* Not a command's answer, so there is nobody waiting for it. */
    const circular: Record<string, unknown> = {};
    circular.self = circular;
    expect(toWire(FormEvent.Error, { message: circular })).toEqual({});
  });

  it('always answers a command, even when the answer cannot be sent', () => {
    const tokens: Record<string, unknown> = {};
    tokens.self = tokens;
    const unsent = {
      commandId: 'c1',
      name: 'tokenize',
      ok: false,
      message: 'The result could not be passed on.',
    };
    expect(
      toWire(FormEvent.CommandResult, {
        commandId: 'c1',
        name: 'tokenize',
        ok: true,
        result: { status: 'success', data: { tokens } },
      })
    ).toEqual(unsent);
    expect(
      toWire(FormEvent.CommandResult, {
        commandId: 'c1',
        name: 'tokenize',
        ok: true,
        result: { status: 'success', data: { tokens: { big: 'x'.repeat(70000) } } },
      })
    ).toEqual(unsent);
  });
});
