import { createRef } from 'react';
import { describe, it, expect, jest, afterEach } from '@jest/globals';
import { render, screen, act, waitFor } from '@testing-library/react-native';

jest.mock(
  'skyflow-react-native',
  () => {
    const React = require('react');
    const { Text } = require('react-native');
    const container = {
      collect: jest.fn(async () => ({
        records: [{ table: 'cards', fields: { card_number: 'tok_sky' } }],
      })),
    };
    const SkyflowProvider = ({ children }: { children: React.ReactNode }) =>
      React.createElement(React.Fragment, null, children);
    const useCollectContainer = () => container;
    const element =
      (name: string) =>
      (props: {
        column: string;
        onChange?: (state: unknown) => void;
        onBlur?: (state: unknown) => void;
      }) => {
        React.useEffect(() => {
          const state = {
            isValid: true,
            isEmpty: false,
            isFocused: false,
            selectedCardScheme: 'VISA',
          };
          props.onChange?.(state);
          props.onBlur?.(state);
        }, [props]);
        return React.createElement(
          Text,
          { testID: `skyflow-${name}-${props.column}` },
          name
        );
      };
    return {
      __esModule: true,
      SkyflowProvider,
      useCollectContainer,
      CardNumberElement: element('number'),
      ExpirationDateElement: element('expiry'),
      CvvElement: element('cvv'),
      CardHolderNameElement: element('holder'),
      __container: container,
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
import { skyflowAdapter } from '../adapter';
import type {
  CardFormHandle,
  ElementType,
  FieldChange,
  TokenizeResult,
  VaultDetails,
} from '../../../core/types';

const skyflowDetails: VaultDetails = {
  vaultType: 'skyflow',
  vaultData: {
    vaultId: 'v123',
    vaultUrl: 'https://vault.skyflow.test',
    table: 'cards',
    bearerToken: 'tok_bearer',
  },
};

const columns: Record<ElementType, string> = {
  cardNumber: 'card_number',
  cardExpiry: 'card_expiration',
  cardCvc: 'cvv',
  cardholderName: 'cardholder_name',
};

const errorOf = (result: TokenizeResult) =>
  result.status === 'success' ? undefined : result.error;

function fakeCollector(collectImpl: () => Promise<unknown>): {
  collector: unknown;
  collect: jest.Mock;
} {
  const collect = jest.fn(collectImpl);
  return {
    collector: { container: { collect }, table: 'cards', columns },
    collect,
  };
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('skyflowAdapter', () => {
  it('renders a Skyflow element per field (via the hook bridge) and tokenizes', async () => {
    const ref = createRef<CardFormHandle>();
    render(
      <CardForm ref={ref} vaultDetails={skyflowDetails}>
        <CardNumberField />
        <CardExpiryField />
        <CardCVCField />
        <CardholderNameField />
      </CardForm>
    );

    await waitFor(() =>
      expect(screen.getByTestId('skyflow-number-card_number')).toBeTruthy()
    );
    expect(screen.getByTestId('skyflow-expiry-card_expiration')).toBeTruthy();
    expect(screen.getByTestId('skyflow-cvv-cvv')).toBeTruthy();
    expect(screen.getByTestId('skyflow-holder-cardholder_name')).toBeTruthy();

    let result: TokenizeResult | undefined;
    await act(async () => {
      result = await ref.current!.tokenize();
    });
    expect(result?.status).toBe('success');
    expect(result?.vaultType).toBe('skyflow');

    const skyflow = require('skyflow-react-native');
    expect(skyflow.__container.collect).toHaveBeenCalledWith({ tokens: true });
  });

  it('maps Skyflow element state to the web change, and its blur to onBlur', async () => {
    const onChange = jest.fn();
    const onBlur = jest.fn();
    render(
      <CardForm vaultDetails={skyflowDetails}>
        <CardNumberField onChange={onChange} onBlur={onBlur} />
      </CardForm>
    );
    await waitFor(() =>
      expect(screen.getByTestId('skyflow-number-card_number')).toBeTruthy()
    );

    const change = onChange.mock.calls.at(-1)?.[0] as FieldChange;
    expect(change).toEqual({
      elementType: 'cardNumber',
      empty: false,
      complete: true,
      valid: true,
      brand: 'Visa',
      touched: true,
    });
    expect(onBlur).toHaveBeenCalledWith({ elementType: 'cardNumber' });
  });

  describe('validateVaultData', () => {
    it('accepts complete vaultData', () => {
      expect(() =>
        skyflowAdapter.validateVaultData({
          vaultId: 'v',
          vaultUrl: 'https://x',
          table: 'cards',
        })
      ).not.toThrow();
    });

    it('throws when vaultUrl is missing', () => {
      expect(() =>
        skyflowAdapter.validateVaultData({ vaultId: 'v', table: 'cards' })
      ).toThrow(/vaultUrl/i);
    });
  });

  describe('tokenize', () => {
    it('collects with tokens and extracts tokens from records', async () => {
      const { collector, collect } = fakeCollector(async () => ({
        records: [{ table: 'cards', fields: { card_number: 'tok_1' } }],
      }));
      const result = await skyflowAdapter.tokenize(collector);
      expect(collect).toHaveBeenCalledWith({ tokens: true });
      expect(result.status).toBe('success');
      expect(result.status === 'success' && result.data?.tokens).toEqual({
        card_number: 'tok_1',
      });
    });

    it('maps a rejected collect to tokenization_failed', async () => {
      const { collector } = fakeCollector(async () => {
        throw new Error('collect failed');
      });
      const result = await skyflowAdapter.tokenize(collector);
      expect(result.status).toBe('error');
      expect(errorOf(result)?.code).toBe('tokenization_failed');
      expect(errorOf(result)?.message).toMatch(/collect failed/);
    });
  });
});
