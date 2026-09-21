import { createRef } from 'react';
import { describe, it, expect, jest, afterEach } from '@jest/globals';
import { render, screen, act, waitFor } from '@testing-library/react-native';

jest.mock(
  '@vgs/collect-react-native',
  () => {
    const React = require('react');
    const { Text } = require('react-native');
    class VGSCollect {
      id: string;
      environment?: string;
      routeId?: string;
      constructor(id: string, environment?: string) {
        this.id = id;
        this.environment = environment;
      }
      setRouteId(routeId: string) {
        this.routeId = routeId;
      }
      setCname() {
        return Promise.resolve();
      }
      submit = jest.fn(async () => ({
        status: 200,
        response: { card_number: 'tok_vgs' },
      }));
    }
    const makeField =
      (label: string) =>
      (props: {
        fieldName: string;
        onStateChange?: (state: unknown) => void;
      }) => {
        React.useEffect(() => {
          props.onStateChange?.({
            isValid: true,
            isEmpty: false,
            isDirty: true,
            isFocused: true,
            validationErrors: [],
            cardBrand: 'visa',
          });
        }, [props]);
        return React.createElement(
          Text,
          { testID: `vgs-${props.fieldName}` },
          label
        );
      };
    const VGSTextInput = makeField('text-input');
    const VGSCardInput = makeField('card-input');
    const VGSCVCInput = makeField('cvc-input');
    return {
      __esModule: true,
      VGSCollect,
      VGSTextInput,
      VGSCardInput,
      VGSCVCInput,
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
import { vgsAdapter } from '../adapter';
import type {
  CardFormHandle,
  FieldChange,
  TokenizeResult,
  VaultDetails,
} from '../../../core/types';

const vgsDetails: VaultDetails = {
  vaultType: 'vgs',
  vaultData: { vaultId: 'tntabc123', environment: 'sandbox' },
};

const errorOf = (result: TokenizeResult) =>
  result.status === 'success' ? undefined : result.error;

type FakeCollector = { submit: jest.Mock };
function fakeCollector(
  impl: () => Promise<{ status: number; response: unknown }>
): { collector: unknown; submit: jest.Mock } {
  const submit = jest.fn(impl);
  return { collector: { submit } as FakeCollector, submit };
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('vgsAdapter', () => {
  it('renders a VGS field for each card field and tokenizes successfully', async () => {
    const ref = createRef<CardFormHandle>();
    render(
      <CardForm ref={ref} vaultDetails={vgsDetails}>
        <CardNumberField />
        <CardExpiryField />
        <CardCVCField />
        <CardholderNameField />
      </CardForm>
    );

    await waitFor(() =>
      expect(screen.getByTestId('vgs-card_number')).toBeTruthy()
    );
    expect(screen.getByTestId('vgs-expiration_date')).toBeTruthy();
    expect(screen.getByTestId('vgs-card_cvc')).toBeTruthy();
    expect(screen.getByTestId('vgs-card_holder')).toBeTruthy();

    expect(screen.getByTestId('vgs-card_number')).toHaveTextContent(
      'card-input'
    );
    expect(screen.getByTestId('vgs-card_cvc')).toHaveTextContent('cvc-input');
    expect(screen.getByTestId('vgs-expiration_date')).toHaveTextContent(
      'text-input'
    );
    expect(screen.getByTestId('vgs-card_holder')).toHaveTextContent(
      'text-input'
    );

    let result: TokenizeResult | undefined;
    await act(async () => {
      result = await ref.current!.tokenize();
    });
    expect(result?.status).toBe('success');
    expect(result?.vaultType).toBe('vgs');
  });

  it('maps VGS field state to the web change, and its focus flag to onFocus', async () => {
    const onChange = jest.fn();
    const onFocus = jest.fn();
    render(
      <CardForm vaultDetails={vgsDetails}>
        <CardNumberField onChange={onChange} onFocus={onFocus} />
      </CardForm>
    );
    await waitFor(() =>
      expect(screen.getByTestId('vgs-card_number')).toBeTruthy()
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
    expect(onFocus).toHaveBeenCalledWith({ elementType: 'cardNumber' });
  });

  describe('validateVaultData', () => {
    it('accepts vaultData with a string vaultId', () => {
      expect(() =>
        vgsAdapter.validateVaultData({ vaultId: 'tnt', environment: 'live' })
      ).not.toThrow();
    });

    it('throws when vaultId is missing', () => {
      expect(() =>
        vgsAdapter.validateVaultData({ environment: 'live' })
      ).toThrow(/vaultId/i);
    });
  });

  describe('tokenize', () => {
    it('maps a 2xx VGS response to a success result with raw payload', async () => {
      const { collector, submit } = fakeCollector(async () => ({
        status: 200,
        response: { card_number: 'tok_1' },
      }));
      const result = await vgsAdapter.tokenize(collector);
      expect(submit).toHaveBeenCalledWith('/post', 'POST', undefined);
      expect(result.status).toBe('success');
      expect(result.status === 'success' && result.data?.raw).toEqual({
        card_number: 'tok_1',
      });
      expect(result.status === 'success' && result.data?.tokens).toEqual({
        card_number: 'tok_1',
      });
    });

    it('maps a non-2xx VGS response to tokenization_failed', async () => {
      const { collector } = fakeCollector(async () => ({
        status: 422,
        response: { error: 'bad' },
      }));
      const result = await vgsAdapter.tokenize(collector);
      expect(result.status).toBe('error');
      expect(errorOf(result)?.code).toBe('tokenization_failed');
      expect(errorOf(result)?.type).toBe('api_error');
      expect(errorOf(result)?.message).toMatch(/422/);
    });

    it('maps a rejected VGS submit to tokenization_failed', async () => {
      const { collector } = fakeCollector(async () => {
        throw new Error('validation failed');
      });
      const result = await vgsAdapter.tokenize(collector);
      expect(result.status).toBe('error');
      expect(errorOf(result)?.message).toMatch(/validation failed/);
    });

    it('forwards path, method and extraData from providerData', async () => {
      const { collector, submit } = fakeCollector(async () => ({
        status: 200,
        response: {},
      }));
      await vgsAdapter.tokenize(collector, {
        path: '/cards',
        method: 'PUT',
        extraData: { merchant: 'acme' },
      });
      expect(submit).toHaveBeenCalledWith('/cards', 'PUT', {
        merchant: 'acme',
      });
    });
  });
});
