import { createRef } from 'react';
import { Text } from 'react-native';
import { describe, it, expect, jest, afterEach } from '@jest/globals';
import { render, screen, act, waitFor } from '@testing-library/react-native';

import { CardForm } from '../CardForm';
import { useCardForm } from '../useCardForm';
import { registerAdapter } from '../../providers/registry';
import { getFormTokenize } from '../formRegistry';
import { HyperswitchPaymentMethods } from '../../HyperswitchPaymentMethods';
import {
  CardNumberField,
  CardExpiryField,
  CardCVCField,
  CardholderNameField,
} from '../../fields';
import { createMockAdapter } from '../../__fixtures__/mockAdapter';
import type {
  CardFormChange,
  CardFormHandle,
  FieldChange,
  FieldHandle,
  TokenizeResult,
  VaultDetails,
} from '../types';

const cleanups: Array<() => void> = [];
afterEach(() => {
  while (cleanups.length) cleanups.pop()!();
});

function useMock(options: Parameters<typeof createMockAdapter>[0] = {}) {
  const adapter = createMockAdapter(options);
  cleanups.push(registerAdapter(adapter));
  return adapter;
}

const details = (vaultType: VaultDetails['vaultType']): VaultDetails => ({
  vaultType,
  vaultData: {},
});

const errorOf = (result: TokenizeResult | undefined) =>
  result && result.status !== 'success' ? result.error : undefined;

function Fields() {
  return (
    <>
      <CardNumberField />
      <CardExpiryField />
      <CardCVCField />
      <CardholderNameField />
    </>
  );
}

describe('CardForm', () => {
  it('renders a placeholder for each field before the collector is ready', () => {
    useMock({ vaultType: 'vgs', neverReady: true });
    render(
      <CardForm vaultDetails={details('vgs')}>
        <Fields />
      </CardForm>
    );

    expect(screen.getByTestId('hs-placeholder-cardNumber')).toBeTruthy();
    expect(screen.getByTestId('hs-placeholder-cardExpiry')).toBeTruthy();
    expect(screen.queryByTestId('mock-field-cardNumber')).toBeNull();
  });

  it('swaps placeholders for provider fields once the collector attaches, and says so on onReady', async () => {
    useMock({ vaultType: 'vgs', readyDelayMs: 0 });
    const onReady = jest.fn();
    const fieldReady = jest.fn();
    render(
      <CardForm vaultDetails={details('vgs')} onReady={onReady}>
        <CardNumberField onReady={fieldReady} />
        <CardExpiryField />
        <CardCVCField />
        <CardholderNameField />
      </CardForm>
    );

    await waitFor(() =>
      expect(screen.getByTestId('mock-field-cardNumber')).toBeTruthy()
    );
    expect(screen.getByTestId('mock-field-cardExpiry')).toBeTruthy();
    expect(screen.getByTestId('mock-field-cardCvc')).toBeTruthy();
    expect(screen.getByTestId('mock-field-cardholderName')).toBeTruthy();
    expect(screen.queryByTestId('hs-placeholder-cardNumber')).toBeNull();
    expect(onReady).toHaveBeenCalledWith({ elementType: 'cardForm' });
    expect(fieldReady).toHaveBeenCalledWith({ elementType: 'cardNumber' });
  });

  it('forwards cvcIcon on CardCVCField to the provider field', async () => {
    useMock({ vaultType: 'hyperswitch' });
    render(
      <CardForm vaultDetails={details('hyperswitch')}>
        <CardNumberField />
        <CardCVCField cvcIcon="hidden" />
      </CardForm>
    );

    const cvc = await screen.findByTestId('mock-field-cardCvc');
    expect(cvc.props.accessibilityHint).toBe('hidden');
    expect(
      screen.getByTestId('mock-field-cardNumber').props.accessibilityHint
    ).toBeUndefined();
  });

  it('forwards label, labelBehavior, errorDisplay and unstyled, from a prop or from options', async () => {
    useMock({ vaultType: 'hyperswitch' });
    render(
      <CardForm vaultDetails={details('hyperswitch')}>
        <CardNumberField
          label="Card number"
          labelBehavior="floating"
          errorDisplay="colorOnly"
          unstyled
        />
        <CardCVCField
          options={{
            label: 'Security code',
            labelBehavior: 'above',
            errorDisplay: 'none',
            unstyled: true,
          }}
        />
      </CardForm>
    );

    const number = await screen.findByTestId('mock-field-cardNumber');
    expect(JSON.parse(number.props.accessibilityValue.text)).toMatchObject({
      label: 'Card number',
      labelBehavior: 'floating',
      errorDisplay: 'colorOnly',
      unstyled: true,
    });
    expect(
      JSON.parse(
        screen.getByTestId('mock-field-cardCvc').props.accessibilityValue.text
      )
    ).toMatchObject({
      label: 'Security code',
      labelBehavior: 'above',
      errorDisplay: 'none',
      unstyled: true,
    });
  });

  it('drops an unknown labelBehavior or errorDisplay rather than passing it on', async () => {
    useMock({ vaultType: 'hyperswitch' });
    const warn = jest.spyOn(console, 'warn').mockImplementation(() => {});
    render(
      <CardForm vaultDetails={details('hyperswitch')}>
        <CardNumberField
          labelBehavior={'sideways' as never}
          errorDisplay={'loud' as never}
        />
      </CardForm>
    );

    const number = await screen.findByTestId('mock-field-cardNumber');
    const forwarded = JSON.parse(number.props.accessibilityValue.text);
    expect(forwarded.labelBehavior).toBeUndefined();
    expect(forwarded.errorDisplay).toBeUndefined();
    expect(warn).toHaveBeenCalledWith(expect.stringContaining('labelBehavior'));
    expect(warn).toHaveBeenCalledWith(expect.stringContaining('errorDisplay'));
    warn.mockRestore();
  });

  it('tokenize resolves with the provider result once ready', async () => {
    useMock({ vaultType: 'vgs', readyDelayMs: 0 });
    const ref = createRef<CardFormHandle>();
    render(
      <CardForm ref={ref} vaultDetails={details('vgs')}>
        <Fields />
      </CardForm>
    );
    await waitFor(() =>
      expect(screen.getByTestId('mock-field-cardNumber')).toBeTruthy()
    );

    let result: TokenizeResult | undefined;
    await act(async () => {
      result = await ref.current!.tokenize();
    });

    expect(result?.status).toBe('success');
    expect(
      result?.status === 'success' && result.data?.tokens?.card_number
    ).toBe('tok_mock');
  });

  it('echoes the card the provider reported onto the successful result', async () => {
    useMock({
      vaultType: 'evervault',
      cardDetails: {
        bin: '424242',
        last4: '4242',
        brand: 'Visa',
        expiryMonth: '12',
        expiryYear: '2030',
      },
    });
    const ref = createRef<CardFormHandle>();
    render(
      <CardForm ref={ref} vaultDetails={details('evervault')}>
        <Fields />
      </CardForm>
    );
    await waitFor(() =>
      expect(screen.getByTestId('mock-field-cardNumber')).toBeTruthy()
    );

    let result: TokenizeResult | undefined;
    await act(async () => {
      result = await ref.current!.tokenize();
    });

    expect(result?.status === 'success' && result.card).toEqual({
      bin: '424242',
      last4: '4242',
      brand: 'Visa',
      expiryMonth: '12',
      expiryYear: '2030',
    });
  });

  it('omits card entirely when the provider described none', async () => {
    useMock({ vaultType: 'vgs' });
    const ref = createRef<CardFormHandle>();
    render(
      <CardForm ref={ref} vaultDetails={details('vgs')}>
        <Fields />
      </CardForm>
    );
    await waitFor(() =>
      expect(screen.getByTestId('mock-field-cardNumber')).toBeTruthy()
    );

    let result: TokenizeResult | undefined;
    await act(async () => {
      result = await ref.current!.tokenize();
    });

    expect(result?.status).toBe('success');
    expect(result && 'card' in result).toBe(false);
  });

  it('tokenize called before ready waits for the collector then succeeds', async () => {
    useMock({ vaultType: 'vgs', readyDelayMs: 40 });
    const ref = createRef<CardFormHandle>();
    render(
      <CardForm ref={ref} vaultDetails={details('vgs')} readyTimeoutMs={1000}>
        <Fields />
      </CardForm>
    );

    let result: TokenizeResult | undefined;
    await act(async () => {
      result = await ref.current!.tokenize();
    });

    expect(result?.status).toBe('success');
  });

  it('tokenize answers sdk_not_ready when the collector never attaches', async () => {
    useMock({ vaultType: 'vgs', neverReady: true });
    const ref = createRef<CardFormHandle>();
    render(
      <CardForm ref={ref} vaultDetails={details('vgs')} readyTimeoutMs={30}>
        <Fields />
      </CardForm>
    );

    let result: TokenizeResult | undefined;
    await act(async () => {
      result = await ref.current!.tokenize();
    });

    expect(result?.status).toBe('error');
    expect(errorOf(result)?.code).toBe('sdk_not_ready');
    expect(result?.vaultType).toBe('vgs');
  });

  it('surfaces an adapter-resolution failure (e.g. missing provider SDK) via onError without crashing', async () => {
    const onError = jest.fn();
    const ref = createRef<CardFormHandle>();

    const unknown = 'no_such_provider' as VaultDetails['vaultType'];
    render(
      <CardForm ref={ref} vaultDetails={details(unknown)} onError={onError}>
        <Fields />
      </CardForm>
    );

    expect(screen.getByTestId('hs-placeholder-cardNumber')).toBeTruthy();

    await waitFor(() => expect(onError).toHaveBeenCalledTimes(1));
    expect(String(onError.mock.calls[0]?.[0])).toMatch(/no provider adapter/i);

    let result: TokenizeResult | undefined;
    await act(async () => {
      result = await ref.current!.tokenize();
    });
    expect(result?.status).toBe('error');
    expect(errorOf(result)?.code).toBe('tokenization_failed');
    expect(result?.vaultType).toBe(unknown);
  });

  it('exposes tokenize and status to descendants via useCardForm', async () => {
    useMock({ vaultType: 'vgs', readyDelayMs: 0 });
    function StatusProbe() {
      const { status } = useCardForm();
      return <Text testID="probe-status">{status}</Text>;
    }
    render(
      <CardForm vaultDetails={details('vgs')}>
        <StatusProbe />
      </CardForm>
    );

    await waitFor(() =>
      expect(screen.getByTestId('probe-status').props.children).toBe('ready')
    );
  });

  it('routes HyperswitchPaymentMethods.tokenize(id) to the form and unregisters on unmount', async () => {
    useMock({ vaultType: 'vgs', readyDelayMs: 0 });
    const view = render(
      <CardForm id="checkout" vaultDetails={details('vgs')}>
        <Fields />
      </CardForm>
    );
    await waitFor(() =>
      expect(screen.getByTestId('mock-field-cardNumber')).toBeTruthy()
    );

    let result: TokenizeResult | undefined;
    await act(async () => {
      result = await HyperswitchPaymentMethods.tokenize('checkout');
    });
    expect(result?.status).toBe('success');

    view.unmount();
    expect(getFormTokenize('checkout')).toBeUndefined();
  });

  it('field focus()/blur()/clear() are safe no-ops when the provider does not support them', async () => {
    useMock({ vaultType: 'vgs', readyDelayMs: 0 });
    const ref = createRef<FieldHandle>();
    render(
      <CardForm vaultDetails={details('vgs')}>
        <CardNumberField ref={ref} />
      </CardForm>
    );
    await waitFor(() =>
      expect(screen.getByTestId('mock-field-cardNumber')).toBeTruthy()
    );

    act(() => {
      ref.current?.focus();
      ref.current?.blur();
      ref.current?.clear();
    });
    expect(Object.keys(ref.current!).sort()).toEqual([
      'blur',
      'clear',
      'focus',
    ]);
  });

  it('carries the eight-digit extendedBin a provider reports through to the payload', async () => {
    useMock({
      vaultType: 'vgs',
      readyDelayMs: 0,
      fieldState: { empty: false, valid: true, brand: 'visa' },
      /* What a host reports once eight digits are typed — six for `bin`, eight for `extendedBin`. */
      cardDetails: { bin: '424242', extendedBin: '42424242', last4: '4242' },
    });
    const formChanges: CardFormChange[] = [];
    render(
      <CardForm
        vaultDetails={details('vgs')}
        onChange={(e) => formChanges.push(e)}
      >
        <CardNumberField />
        <CardExpiryField />
        <CardCVCField />
      </CardForm>
    );
    await waitFor(() =>
      expect(formChanges.at(-1)?.payload.extendedBin).toBe('42424242')
    );
    expect(formChanges.at(-1)!.payload).toMatchObject({
      bin: '424242',
      extendedBin: '42424242',
      last4: '4242',
    });
  });

  it('emits the cardDetailsChange envelope on the form and the web change on each field', async () => {
    useMock({
      vaultType: 'vgs',
      readyDelayMs: 0,
      fieldState: { empty: false, valid: true, brand: 'visa' },
    });
    const formChanges: CardFormChange[] = [];
    const numberChanges: FieldChange[] = [];
    render(
      <CardForm
        vaultDetails={details('vgs')}
        onChange={(e) => formChanges.push(e)}
      >
        <CardNumberField onChange={(c) => numberChanges.push(c)} />
        <CardExpiryField />
        <CardCVCField />
      </CardForm>
    );
    await waitFor(() => expect(formChanges.length).toBeGreaterThanOrEqual(3));

    expect(numberChanges.at(-1)).toEqual({
      elementType: 'cardNumber',
      empty: false,
      complete: true,
      valid: true,
      brand: 'Visa',
      touched: true,
    });

    const last = formChanges.at(-1)!;
    expect(last.elementType).toBe('cardForm');
    expect(last.eventName).toBe('cardDetailsChange');
    expect(last.payload).toEqual({
      bin: null,
      /* Eight digits are only reported once eight have been typed; this fixture types none. */
      extendedBin: null,
      last4: null,
      brand: 'Visa',
      expiryMonth: null,
      expiryYear: null,
      formattedExpiry: null,
      isCardNumberComplete: true,
      isCvcComplete: true,
      isExpiryComplete: true,
      isCardNumberValid: true,
      isExpiryValid: true,
    });
    expect(last.complete).toBe(true);
    expect(last.valid).toBe(true);
    expect(Object.keys(last.fields).sort()).toEqual([
      'cardCvc',
      'cardExpiry',
      'cardNumber',
    ]);
    expect(JSON.stringify(formChanges)).not.toMatch(/4242|cvc":/);
  });

  it('keeps two forms with different providers isolated', async () => {
    useMock({
      vaultType: 'vgs',
      readyDelayMs: 0,
      tokenizeResult: { status: 'success', vaultType: 'vgs' },
    });
    useMock({
      vaultType: 'skyflow',
      readyDelayMs: 0,
      tokenizeResult: { status: 'success', vaultType: 'skyflow' },
    });
    const vgsRef = createRef<CardFormHandle>();
    const skyflowRef = createRef<CardFormHandle>();
    render(
      <>
        <CardForm ref={vgsRef} vaultDetails={details('vgs')}>
          <CardNumberField />
        </CardForm>
        <CardForm ref={skyflowRef} vaultDetails={details('skyflow')}>
          <CardNumberField />
        </CardForm>
      </>
    );
    await waitFor(() =>
      expect(screen.getAllByTestId('mock-field-cardNumber').length).toBe(2)
    );

    let vgsResult: TokenizeResult | undefined;
    let skyflowResult: TokenizeResult | undefined;
    await act(async () => {
      vgsResult = await vgsRef.current!.tokenize();
      skyflowResult = await skyflowRef.current!.tokenize();
    });

    expect(vgsResult?.vaultType).toBe('vgs');
    expect(skyflowResult?.vaultType).toBe('skyflow');
  });
});
