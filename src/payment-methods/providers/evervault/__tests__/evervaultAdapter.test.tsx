import { createRef } from 'react';
import { describe, it, expect, jest, afterEach } from '@jest/globals';
import { render, screen, act, waitFor } from '@testing-library/react-native';

jest.mock(
  '@evervault/react-native',
  () => {
    const React = require('react');
    const { Text } = require('react-native');
    const state: { onChange?: (payload: unknown) => void } = {};
    const Card = ({
      onChange,
      children,
    }: {
      onChange?: (payload: unknown) => void;
      children: React.ReactNode;
    }) => {
      state.onChange = onChange;
      return React.createElement(React.Fragment, null, children);
    };
    const EvervaultProvider = ({ children }: { children: React.ReactNode }) =>
      React.createElement(React.Fragment, null, children);
    const field = (name: string) => () =>
      React.createElement(Text, { testID: `ev-${name}` }, name);
    return {
      __esModule: true,
      EvervaultProvider,
      useEvervault: () => ({}),
      Card,
      CardNumber: field('number'),
      CardExpiry: field('expiry'),
      CardCvc: field('cvc'),
      CardHolder: field('holder'),
      __emit: (payload: unknown) => state.onChange?.(payload),
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
import { evervaultAdapter } from '../adapter';
import type {
  CardFormChange,
  CardFormHandle,
  TokenizeResult,
  VaultDetails,
} from '../../../core/types';

const evervaultDetails: VaultDetails = {
  vaultType: 'evervault',
  vaultData: { teamId: 'team_1', appId: 'app_1' },
};

const completePayload = {
  card: {
    name: 'enc_name',
    brand: 'visa',
    localBrands: [],
    number: 'enc_number',
    lastFour: '4242',
    bin: '424242',
    expiry: { month: '12', year: '30' },
    cvc: 'enc_cvc',
  },
  isValid: true,
  isComplete: true,
  errors: {},
};

const errorOf = (result: TokenizeResult) =>
  result.status === 'success' ? undefined : result.error;

function fakeCollector(payload: unknown): unknown {
  return { getPayload: () => payload };
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('evervaultAdapter', () => {
  it('renders an Evervault field per card field and returns the encrypted payload', async () => {
    const ref = createRef<CardFormHandle>();
    render(
      <CardForm ref={ref} vaultDetails={evervaultDetails}>
        <CardNumberField />
        <CardExpiryField />
        <CardCVCField />
        <CardholderNameField />
      </CardForm>
    );

    await waitFor(() => expect(screen.getByTestId('ev-number')).toBeTruthy());
    expect(screen.getByTestId('ev-expiry')).toBeTruthy();
    expect(screen.getByTestId('ev-cvc')).toBeTruthy();
    expect(screen.getByTestId('ev-holder')).toBeTruthy();

    const mod = require('@evervault/react-native');
    let result: TokenizeResult | undefined;
    await act(async () => {
      mod.__emit(completePayload);
      result = await ref.current!.tokenize();
    });
    expect(result?.status).toBe('success');
    expect(result?.vaultType).toBe('evervault');
    expect(result?.status === 'success' && result.data?.raw).toEqual(
      completePayload.card
    );
  });

  it('reports the card-level details Evervault knows into cardDetailsChange', async () => {
    const changes: CardFormChange[] = [];
    render(
      <CardForm
        vaultDetails={evervaultDetails}
        onChange={(e) => changes.push(e)}
      >
        <CardNumberField />
      </CardForm>
    );
    await waitFor(() => expect(screen.getByTestId('ev-number')).toBeTruthy());

    const mod = require('@evervault/react-native');
    act(() => {
      mod.__emit(completePayload);
    });

    const last = changes.at(-1)!;
    expect(last.eventName).toBe('cardDetailsChange');
    expect(last.payload.bin).toBe('424242');
    expect(last.payload.last4).toBe('4242');
    expect(last.payload.brand).toBe('Visa');
    expect(last.payload.expiryMonth).toBe('12');
    expect(last.payload.expiryYear).toBe('2030');
    expect(last.payload.formattedExpiry).toBe('12 / 30');

    expect(JSON.stringify(changes)).not.toMatch(/enc_/);
  });

  describe('validateVaultData', () => {
    it('accepts vaultData with teamId and appId', () => {
      expect(() =>
        evervaultAdapter.validateVaultData({ teamId: 't', appId: 'a' })
      ).not.toThrow();
    });

    it('throws when appId is missing', () => {
      expect(() => evervaultAdapter.validateVaultData({ teamId: 't' })).toThrow(
        /appId/i
      );
    });
  });

  describe('tokenize', () => {
    it('returns success with encrypted card data when complete', async () => {
      const result = await evervaultAdapter.tokenize(
        fakeCollector(completePayload)
      );
      expect(result.status).toBe('success');
      expect(result.status === 'success' && result.data?.tokens?.number).toBe(
        'enc_number'
      );
    });

    it('returns a validation_error naming the field when incomplete', async () => {
      const result = await evervaultAdapter.tokenize(
        fakeCollector({
          card: {},
          isValid: false,
          isComplete: false,
          errors: { number: 'Invalid card number' },
        })
      );
      expect(result.status).toBe('validation_error');
      expect(errorOf(result)).toEqual({
        code: 'validation_error',
        message: 'cardNumber: Invalid card number',
        type: 'validation_error',
      });
    });

    it('returns a validation_error when no payload has arrived', async () => {
      const result = await evervaultAdapter.tokenize(fakeCollector(null));
      expect(result.status).toBe('validation_error');
      expect(errorOf(result)?.code).toBe('validation_error');
    });
  });
});
