import { createRef } from 'react';
import { describe, it, expect, jest, afterEach } from '@jest/globals';
import { render, screen, act, waitFor } from '@testing-library/react-native';

jest.mock(
  '@basis-theory/react-native-elements',
  () => {
    const React = require('react');
    const { Text } = require('react-native');
    const bt = {
      tokens: { create: jest.fn(async () => ({ id: 'tok_bt_123' })) },
    };
    const useBasisTheory = () => ({ bt });
    const BasisTheoryProvider = ({ children }: { children: React.ReactNode }) =>
      React.createElement(React.Fragment, null, children);
    const element =
      (name: string) => (props: { onChange?: (event: unknown) => void }) => {
        React.useEffect(() => {
          props.onChange?.({
            empty: false,
            valid: true,
            errors: [],
            brand: 'visa',
          });
        }, [props]);
        return React.createElement(Text, { testID: `bt-${name}` }, name);
      };
    return {
      __esModule: true,
      useBasisTheory,
      BasisTheoryProvider,
      CardNumberElement: element('number'),
      CardExpirationDateElement: element('expiry'),
      CardVerificationCodeElement: element('cvc'),
      TextElement: element('holder'),
      __bt: bt,
    };
  },
  { virtual: true }
);

import { CardForm } from '../../../core/CardForm';
import {
  CardNumberField,
  CardExpiryField,
  CardCVCField,
  CardholderNameField,
} from '../../../fields';
import { basisTheoryAdapter } from '../adapter';
import type {
  CardFormHandle,
  FieldChange,
  TokenizeResult,
  VaultDetails,
} from '../../../core/types';

const btDetails: VaultDetails = {
  vaultType: 'basis_theory',
  vaultData: { apiKey: 'key_test' },
};

const errorOf = (result: TokenizeResult) =>
  result.status === 'success' ? undefined : result.error;

function fakeCollector(createImpl: () => Promise<unknown>): {
  collector: unknown;
  create: jest.Mock;
} {
  const create = jest.fn(createImpl);
  const refs = {
    cardNumber: { current: { id: 'n' } },
    cardExpiry: {
      current: {
        month: () => ({ datepart: 'month' }),
        year: () => ({ datepart: 'year' }),
      },
    },
    cardCvc: { current: { id: 'c' } },
    cardholderName: { current: { id: 'h' } },
  };
  return { collector: { bt: { tokens: { create } }, refs }, create };
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('basisTheoryAdapter', () => {
  it('renders a BT element per field and creates a card token on tokenize', async () => {
    const ref = createRef<CardFormHandle>();
    render(
      <CardForm ref={ref} vaultDetails={btDetails}>
        <CardNumberField />
        <CardExpiryField />
        <CardCVCField />
        <CardholderNameField />
      </CardForm>
    );

    await waitFor(() => expect(screen.getByTestId('bt-number')).toBeTruthy());
    expect(screen.getByTestId('bt-expiry')).toBeTruthy();
    expect(screen.getByTestId('bt-cvc')).toBeTruthy();
    expect(screen.getByTestId('bt-holder')).toBeTruthy();

    let result: TokenizeResult | undefined;
    await act(async () => {
      result = await ref.current!.tokenize();
    });
    expect(result?.status).toBe('success');
    expect(result?.vaultType).toBe('basis_theory');

    const mod = require('@basis-theory/react-native-elements');
    expect(mod.__bt.tokens.create).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'card' }),
      undefined
    );
  });

  it('maps Basis Theory element events to the web change', async () => {
    const onChange = jest.fn();
    render(
      <CardForm vaultDetails={btDetails}>
        <CardNumberField onChange={onChange} />
      </CardForm>
    );
    await waitFor(() => expect(screen.getByTestId('bt-number')).toBeTruthy());

    const change = onChange.mock.calls.at(-1)?.[0] as FieldChange;
    expect(change).toEqual({
      elementType: 'cardNumber',
      empty: false,
      complete: true,
      valid: true,
      brand: 'Visa',
      touched: true,
    });
  });

  describe('validateVaultData', () => {
    it('accepts vaultData with an apiKey', () => {
      expect(() =>
        basisTheoryAdapter.validateVaultData({ apiKey: 'key' })
      ).not.toThrow();
    });

    it('throws when apiKey is missing', () => {
      expect(() => basisTheoryAdapter.validateVaultData({})).toThrow(/apiKey/i);
    });
  });

  describe('tokenize', () => {
    it('builds a card token from the field refs and returns the token id', async () => {
      const { collector, create } = fakeCollector(async () => ({
        id: 'tok_bt_999',
      }));
      const result = await basisTheoryAdapter.tokenize(collector);

      expect(create).toHaveBeenCalledTimes(1);
      const [payload] = create.mock.calls[0] as [
        { type: string; data: Record<string, unknown> },
      ];
      expect(payload.type).toBe('card');
      expect(payload.data.number).toEqual({ id: 'n' });
      expect(payload.data.expiration_month).toEqual({ datepart: 'month' });
      expect(result.status).toBe('success');
      expect(result.status === 'success' && result.data?.raw).toEqual({
        id: 'tok_bt_999',
      });
    });

    it('maps a rejected token create to tokenization_failed', async () => {
      const { collector } = fakeCollector(async () => {
        throw new Error('tokenization failed');
      });
      const result = await basisTheoryAdapter.tokenize(collector);
      expect(result.status).toBe('error');
      expect(errorOf(result)?.code).toBe('tokenization_failed');
      expect(errorOf(result)?.message).toMatch(/tokenization failed/);
    });
  });
});
