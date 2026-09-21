import { describe, it, expect, jest, afterEach } from '@jest/globals';
import type { ComponentType } from 'react';
import {
  render,
  screen,
  waitFor,
  act,
  fireEvent,
} from '@testing-library/react-native';

import { CardForm } from '../../core/CardForm';
import { registerAdapter } from '../../providers/registry';
import { CardNumberField, CardExpiryField, CardCVCField } from '..';
import { createMockAdapter } from '../../__fixtures__/mockAdapter';
import type { MockAdapterOptions } from '../../__fixtures__/mockAdapter';
import type { CardFormChange, VaultDetails } from '../../core/types';

const cleanups: Array<() => void> = [];
afterEach(() => {
  while (cleanups.length) cleanups.pop()!();
  jest.restoreAllMocks();
});

function useMock(options: MockAdapterOptions = {}) {
  const adapter = createMockAdapter({ vaultType: 'vgs', ...options });
  cleanups.push(registerAdapter(adapter));
  return adapter;
}

const details: VaultDetails = { vaultType: 'vgs', vaultData: {} };

const forwarded = (elementType: string) =>
  JSON.parse(
    screen.getByTestId(`mock-field-${elementType}`).props.accessibilityValue
      .text
  ) as { placeholder?: string; cardBrandIcon?: string; testID?: string };

const ready = (elementType = 'cardNumber') =>
  waitFor(() =>
    expect(screen.getByTestId(`mock-field-${elementType}`)).toBeTruthy()
  );

describe('nested field options and top-level aliases', () => {
  it('forwards options.placeholder to the provider field', async () => {
    useMock();
    render(
      <CardForm vaultDetails={details}>
        <CardNumberField options={{ placeholder: 'Card number' }} />
        <CardExpiryField options={{ placeholder: 'MM / YY' }} />
        <CardCVCField options={{ placeholder: 'CVC' }} />
      </CardForm>
    );
    await ready();
    expect(forwarded('cardNumber').placeholder).toBe('Card number');
    expect(forwarded('cardExpiry').placeholder).toBe('MM / YY');
    expect(forwarded('cardCvc').placeholder).toBe('CVC');
  });

  it('keeps the top-level placeholder alias, which wins when both are given', async () => {
    useMock();
    render(
      <CardForm vaultDetails={details}>
        <CardNumberField
          placeholder="Top level"
          options={{ placeholder: 'Nested' }}
        />
        <CardExpiryField placeholder="Alias only" />
        <CardCVCField placeholder="" options={{ placeholder: 'Nested' }} />
      </CardForm>
    );
    await ready();
    expect(forwarded('cardNumber').placeholder).toBe('Top level');
    expect(forwarded('cardExpiry').placeholder).toBe('Alias only');
    expect(forwarded('cardCvc').placeholder).toBe('');
  });

  it('forwards options.cvcIcon on the CVC field; the top-level alias wins', async () => {
    useMock();
    render(
      <CardForm vaultDetails={details}>
        <CardCVCField options={{ cvcIcon: 'hidden' }} />
      </CardForm>
    );
    await ready('cardCvc');
    expect(
      screen.getByTestId('mock-field-cardCvc').props.accessibilityHint
    ).toBe('hidden');

    screen.unmount();
    render(
      <CardForm vaultDetails={details}>
        <CardCVCField cvcIcon="default" options={{ cvcIcon: 'hidden' }} />
      </CardForm>
    );
    await ready('cardCvc');
    expect(
      screen.getByTestId('mock-field-cardCvc').props.accessibilityHint
    ).toBe('default');
  });

  it('forwards options.cardBrandIcon on the number field only', async () => {
    useMock();
    render(
      <CardForm vaultDetails={details}>
        <CardNumberField options={{ cardBrandIcon: 'hideGeneric' }} />
        <CardCVCField options={{ cardBrandIcon: 'hidden' }} />
      </CardForm>
    );
    await ready();
    expect(forwarded('cardNumber').cardBrandIcon).toBe('hideGeneric');
    expect(forwarded('cardCvc').cardBrandIcon).toBeUndefined();
  });

  it('passes testID through to the provider field, though it is not a public prop', async () => {
    useMock();
    const Untyped = CardNumberField as unknown as ComponentType<{
      testID: string;
    }>;
    render(
      <CardForm vaultDetails={details}>
        <Untyped testID="card-number-input" />
      </CardForm>
    );
    await ready();
    expect(forwarded('cardNumber').testID).toBe('card-number-input');
  });

  it('does not let a placeholder or icon option leak into savedCard handling', async () => {
    useMock();
    render(
      <CardForm vaultDetails={details}>
        <CardCVCField options={{ placeholder: 'CVC', cvcIcon: 'hidden' }} />
      </CardForm>
    );
    await ready('cardCvc');
    expect(
      screen.getByTestId('mock-field-cardCvc').props.accessibilityLabel
    ).toBeUndefined();
  });
});

describe('runtime validation (JavaScript callers bypass TypeScript)', () => {
  const loose = (value: unknown) => value as never;

  it('falls back to the default and warns for an unknown icon value; empty string is silent', async () => {
    useMock();
    const warn = jest.spyOn(console, 'warn').mockImplementation(() => {});
    render(
      <CardForm vaultDetails={details}>
        <CardNumberField options={{ cardBrandIcon: loose('always') }} />
        <CardCVCField options={{ cvcIcon: loose('none') }} />
      </CardForm>
    );
    await ready();
    expect(forwarded('cardNumber').cardBrandIcon).toBeUndefined();
    expect(
      screen.getByTestId('mock-field-cardCvc').props.accessibilityHint
    ).toBeUndefined();
    expect(warn).toHaveBeenCalledWith(
      expect.stringContaining('options.cardBrandIcon')
    );
    expect(warn).toHaveBeenCalledWith(
      expect.stringContaining('options.cvcIcon')
    );

    warn.mockClear();
    screen.unmount();
    render(
      <CardForm vaultDetails={details}>
        <CardNumberField options={{ cardBrandIcon: loose('') }} />
        <CardCVCField cvcIcon={loose('')} options={{ cvcIcon: loose(null) }} />
      </CardForm>
    );
    await ready();
    expect(forwarded('cardNumber').cardBrandIcon).toBeUndefined();
    expect(warn).not.toHaveBeenCalled();
  });

  it('applies placeholder only when it is a string', async () => {
    useMock();
    render(
      <CardForm vaultDetails={details}>
        <CardNumberField options={{ placeholder: loose(null) }} />
        <CardExpiryField
          placeholder={loose(false)}
          options={{ placeholder: 'MM / YY' }}
        />
        <CardCVCField options={{ placeholder: '' }} />
      </CardForm>
    );
    await ready();
    expect(forwarded('cardNumber').placeholder).toBeUndefined();
    // A non-string alias does not shadow a valid nested value.
    expect(forwarded('cardExpiry').placeholder).toBe('MM / YY');
    expect(forwarded('cardCvc').placeholder).toBe('');
  });
});

// DEFERRED (follow-up PR): coalesced, deduped, unmount-safe CardForm.onChange.
describe.skip('DEFERRED: CardForm.onChange coalescing and lifecycle', () => {
  const fieldState = { empty: false, valid: true, brand: 'visa' };

  it('emits one envelope per task with a consistent payload, and never one per field report', async () => {
    useMock({ fieldState, cardDetails: { bin: '424242', last4: '4242' } });
    const changes: CardFormChange[] = [];
    render(
      <CardForm vaultDetails={details} onChange={(e) => changes.push(e)}>
        <CardNumberField />
        <CardExpiryField />
        <CardCVCField />
      </CardForm>
    );
    await waitFor(() => expect(changes.length).toBeGreaterThanOrEqual(2));
    await act(async () => {});
    // The mock host reports the card details in one task (before the fields
    // mount) and the three fields report in the next: two envelopes.
    expect(changes).toHaveLength(2);
    expect(changes[0]!).toMatchObject({
      eventName: 'cardDetailsChange',
      payload: { bin: '424242', last4: '4242' },
      fields: {},
    });
    expect(changes[1]!).toMatchObject({
      elementType: 'cardForm',
      eventName: 'cardDetailsChange',
      payload: {
        bin: '424242',
        last4: '4242',
        brand: 'Visa',
        isCardNumberComplete: true,
      },
      complete: true,
      valid: true,
    });
    expect(Object.keys(changes[1]!.fields).sort()).toEqual([
      'cardCvc',
      'cardExpiry',
      'cardNumber',
    ]);
  });

  it('never delivers a pending envelope after unmount, and a replacement form starts clean', async () => {
    useMock({ fieldState });
    const first: CardFormChange[] = [];
    const second: CardFormChange[] = [];
    const { unmount } = render(
      <CardForm vaultDetails={details} onChange={(e) => first.push(e)}>
        <CardNumberField />
      </CardForm>
    );
    await waitFor(() => expect(first.length).toBe(1));
    first.length = 0;
    // Report a change and unmount in the same task: the microtask must not fire.
    fireEvent.press(screen.getByTestId('mock-field-cardNumber'));
    unmount();
    await act(async () => {});
    expect(first).toEqual([]);

    render(
      <CardForm vaultDetails={details} onChange={(e) => second.push(e)}>
        <CardNumberField />
      </CardForm>
    );
    await waitFor(() => expect(second.length).toBe(1));
    expect(second[0]!.fields.cardNumber?.brand).toBe('Visa');
  });

  it('surfaces a throwing listener as an uncaught error, not an unhandled rejection', async () => {
    useMock({ fieldState });
    const thrown: unknown[] = [];
    const timeout = jest.spyOn(globalThis, 'setTimeout').mockImplementation(((
      callback: () => void
    ) => {
      try {
        callback();
      } catch (error) {
        thrown.push(error);
      }
      return 0 as unknown as ReturnType<typeof setTimeout>;
    }) as typeof setTimeout);
    const rejections: unknown[] = [];
    const onRejection = (event: unknown) => rejections.push(event);
    process.on('unhandledRejection', onRejection);
    try {
      render(
        <CardForm
          vaultDetails={details}
          onChange={() => {
            throw new Error('listener failed');
          }}
        >
          <CardNumberField />
        </CardForm>
      );
      await act(async () => {});
      await act(async () => {});
      expect(thrown.map(String)).toEqual(['Error: listener failed']);
      expect(rejections).toEqual([]);
    } finally {
      process.off('unhandledRejection', onRejection);
      timeout.mockRestore();
    }
  });
});
