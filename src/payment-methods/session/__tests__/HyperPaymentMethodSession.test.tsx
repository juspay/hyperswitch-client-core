import { createRef } from 'react';
import type { ReactNode, RefObject } from 'react';
import { Text } from 'react-native';
import {
  describe,
  it,
  expect,
  jest,
  afterEach,
  beforeEach,
} from '@jest/globals';
import { render, screen, act, waitFor } from '@testing-library/react-native';

import { HyperPaymentMethodSession } from '../HyperPaymentMethodSession';
import { usePaymentMethodsSession } from '../usePaymentMethodsSession';
import { Hyperswitch } from '../init';
import { CardForm } from '../../core/CardForm';
import { registerAdapter } from '../../providers/registry';
import { CardNumberField, CardExpiryField, CardCVCField } from '../../fields';
import { createMockAdapter } from '../../__fixtures__/mockAdapter';
import type { MockAdapterOptions } from '../../__fixtures__/mockAdapter';
import type { HyperswitchConfiguration } from '../init';
import type {
  CardFormHandle,
  SavedCard,
  TokenizeResult,
  VaultDetails,
} from '../../core/types';

const cleanups: Array<() => void> = [];
afterEach(() => {
  while (cleanups.length) cleanups.pop()!();
});

function installMock(options: MockAdapterOptions = {}) {
  const adapter = createMockAdapter(options);
  cleanups.push(registerAdapter(adapter));
  return adapter;
}

const details = (
  vaultType: VaultDetails['vaultType'] = 'vgs'
): VaultDetails => ({ vaultType, vaultData: {} });

const hyper: HyperswitchConfiguration = {
  publishableKey: 'pk_test',
  profileId: 'pro_456',
};

const saved = (paymentMethodToken: string, cardNetwork?: string): SavedCard =>
  cardNetwork
    ? { paymentMethodToken, paymentMethodData: { card: { cardNetwork } } }
    : { paymentMethodToken };

const errorOf = (result: TokenizeResult | undefined) =>
  result && result.status !== 'success' ? result.error : undefined;

const dataOf = (result: TokenizeResult | undefined) =>
  result && result.status === 'success' ? result.data : undefined;

async function tokenizeVia(ref: RefObject<CardFormHandle | null>) {
  let result: TokenizeResult | undefined;
  await act(async () => {
    result = await ref.current!.tokenize();
  });
  return result;
}

describe('HyperPaymentMethodSession', () => {
  it('configures a bare <CardForm> from options.vaultDetails', async () => {
    installMock({ vaultType: 'skyflow' });
    const ref = createRef<CardFormHandle>();

    render(
      <HyperPaymentMethodSession
        hyper={hyper}
        options={{
          sdkAuthorization: 'sdk_auth',
          vaultDetails: details('skyflow'),
        }}
      >
        <CardForm ref={ref}>
          <CardNumberField />
          <CardExpiryField />
          <CardCVCField />
        </CardForm>
      </HyperPaymentMethodSession>
    );

    await waitFor(() =>
      expect(screen.getByTestId('mock-field-cardNumber')).toBeTruthy()
    );

    const result = await tokenizeVia(ref);
    expect(result?.status).toBe('success');
    expect(result?.vaultType).toBe('skyflow');
  });

  it('resolves the hyper promise and exposes it, without gating the fields on it', async () => {
    installMock();
    let resolveHyper: (instance: HyperswitchConfiguration) => void = () => {};
    const hyperPromise = new Promise<HyperswitchConfiguration>((resolve) => {
      resolveHyper = resolve;
    });

    function Probe() {
      const session = usePaymentMethodsSession();
      return (
        <Text testID="probe">
          {`${session.loading}:${session.hyper?.publishableKey ?? null}:${session.sdkAuthorization}`}
        </Text>
      );
    }

    render(
      <HyperPaymentMethodSession
        hyper={hyperPromise}
        options={{
          sdkAuthorization: 'sdk_auth',
          vaultDetails: details(),
        }}
      >
        <Probe />
        <CardForm>
          <CardNumberField />
        </CardForm>
      </HyperPaymentMethodSession>
    );

    await waitFor(() =>
      expect(screen.getByTestId('mock-field-cardNumber')).toBeTruthy()
    );
    expect(screen.getByTestId('probe').props.children).toBe(
      'true:null:sdk_auth'
    );

    await act(async () => {
      resolveHyper({ publishableKey: 'pk_test', profileId: 'pro_456' });
    });

    await waitFor(() =>
      expect(screen.getByTestId('probe').props.children).toBe(
        'false:pk_test:sdk_auth'
      )
    );
  });

  it('reports a rejected hyper promise through onError and the session', async () => {
    installMock();
    const onError = jest.fn();

    const rejected = Promise.reject(new Error('init failed'));

    function Probe() {
      const session = usePaymentMethodsSession();
      return <Text testID="probe">{session.error?.message ?? 'none'}</Text>;
    }

    render(
      <HyperPaymentMethodSession
        hyper={rejected}
        options={{
          sdkAuthorization: 'sdk_auth',
          vaultDetails: details(),
        }}
        onError={onError}
      >
        <Probe />
      </HyperPaymentMethodSession>
    );

    await waitFor(() =>
      expect(screen.getByTestId('probe').props.children).toBe('init failed')
    );
    expect(onError).toHaveBeenCalledTimes(1);
  });

  it("lets a form's own vaultDetails override the session's", async () => {
    installMock({ vaultType: 'evervault' });
    const ref = createRef<CardFormHandle>();

    render(
      <HyperPaymentMethodSession
        hyper={hyper}
        options={{
          sdkAuthorization: 'sdk_auth',
          vaultDetails: details('vgs'),
        }}
      >
        <CardForm ref={ref} vaultDetails={details('evervault')}>
          <CardNumberField />
        </CardForm>
      </HyperPaymentMethodSession>
    );

    await waitFor(() =>
      expect(screen.getByTestId('mock-field-cardNumber')).toBeTruthy()
    );
    expect((await tokenizeVia(ref))?.vaultType).toBe('evervault');
  });

  it('answers unsupported_configuration, with no request, when no vault is in scope', async () => {
    const onTokenize = jest.fn();
    installMock({ onTokenize });
    const ref = createRef<CardFormHandle>();

    render(
      <CardForm ref={ref}>
        <CardNumberField />
      </CardForm>
    );

    const result = await tokenizeVia(ref);
    expect(result?.status).toBe('error');
    expect(errorOf(result)?.code).toBe('unsupported_configuration');
    expect(errorOf(result)?.message).toMatch(/vaultDetails/);
    expect(onTokenize).not.toHaveBeenCalled();
  });
});

describe('appearance', () => {
  const sessionAppearance = {
    container: { borderWidth: 1, borderColor: '#ccc' },
    fields: { cardCvc: { container: { borderColor: '#00f' } } },
  };

  it('folds session defaults under the per-type defaults and the field own styles', async () => {
    installMock();

    render(
      <HyperPaymentMethodSession
        hyper={hyper}
        options={{
          sdkAuthorization: 'sdk_auth',
          vaultDetails: details(),
          appearance: sessionAppearance,
        }}
      >
        <CardForm>
          <CardNumberField />
          <CardCVCField styles={{ container: { borderWidth: 4 } }} />
        </CardForm>
      </HyperPaymentMethodSession>
    );

    await waitFor(() =>
      expect(screen.getByTestId('mock-field-cardNumber')).toBeTruthy()
    );

    expect(screen.getByTestId('mock-field-cardNumber').props.style).toEqual({
      borderWidth: 1,
      borderColor: '#ccc',
    });

    expect(screen.getByTestId('mock-field-cardCvc').props.style).toEqual({
      borderWidth: 4,
      borderColor: '#00f',
    });
  });

  it("folds the form's appearance over the session's", async () => {
    installMock();

    render(
      <HyperPaymentMethodSession
        hyper={hyper}
        options={{
          sdkAuthorization: 'sdk_auth',
          vaultDetails: details(),
          appearance: { container: { borderWidth: 1, borderColor: '#ccc' } },
        }}
      >
        <CardForm appearance={{ container: { borderColor: '#0f0' } }}>
          <CardNumberField />
        </CardForm>
      </HyperPaymentMethodSession>
    );

    await waitFor(() =>
      expect(screen.getByTestId('mock-field-cardNumber')).toBeTruthy()
    );
    expect(screen.getByTestId('mock-field-cardNumber').props.style).toEqual({
      borderWidth: 1,
      borderColor: '#0f0',
    });
  });
});

describe('saved-card CVC', () => {
  function renderSavedCard(
    savedCard: SavedCard,
    extra?: ReactNode,
    options: MockAdapterOptions = {}
  ) {
    installMock(options);
    const ref = createRef<CardFormHandle>();
    render(
      <HyperPaymentMethodSession
        hyper={hyper}
        options={{
          sdkAuthorization: 'sdk_auth',
          vaultDetails: details(),
        }}
      >
        <CardForm ref={ref}>
          <CardCVCField options={{ savedCard }} />
          {extra}
        </CardForm>
      </HyperPaymentMethodSession>
    );
    return ref;
  }

  it('tokenizes the CVC through the vault and hands the stored card back', async () => {
    const ref = renderSavedCard(saved('tok_saved', 'amex'));

    await waitFor(() =>
      expect(screen.getByTestId('mock-field-cardCvc')).toBeTruthy()
    );

    const result = await tokenizeVia(ref);
    expect(result?.status).toBe('success');
    expect(dataOf(result)?.tokens).toEqual({ card_number: 'tok_mock' });

    expect(dataOf(result)?.savedCard).toEqual({
      paymentMethodToken: 'tok_saved',
      paymentMethodData: { card: { cardNetwork: 'AmericanExpress' } },
    });
  });

  it('passes the saved card down to the provider field', async () => {
    renderSavedCard(saved('tok_saved', 'Visa'));

    await waitFor(() =>
      expect(
        screen.getByTestId('mock-field-cardCvc').props.accessibilityLabel
      ).toBe('saved:tok_saved:Visa')
    );
  });

  it('refuses, with no request, when another field is mounted beside it', async () => {
    const onTokenize = jest.fn();
    const ref = renderSavedCard(saved('tok_saved'), <CardNumberField />, {
      onTokenize,
    });

    await waitFor(() =>
      expect(screen.getByTestId('mock-field-cardNumber')).toBeTruthy()
    );

    const result = await tokenizeVia(ref);
    expect(result?.status).toBe('error');
    expect(errorOf(result)?.code).toBe('unsupported_configuration');
    expect(errorOf(result)?.message).toMatch(/only field/i);
    expect(onTokenize).not.toHaveBeenCalled();
  });

  it('refuses, with no request, when the token is blank', async () => {
    const onTokenize = jest.fn();
    const ref = renderSavedCard(saved('   '), undefined, { onTokenize });

    await waitFor(() =>
      expect(screen.getByTestId('mock-field-cardCvc')).toBeTruthy()
    );

    const result = await tokenizeVia(ref);
    expect(result?.status).toBe('validation_error');
    expect(errorOf(result)?.code).toBe('validation_error');
    expect(errorOf(result)?.type).toBe('validation_error');
    expect(onTokenize).not.toHaveBeenCalled();
  });

  it('refuses when savedCard is passed to a field that is not the CVC', async () => {
    const onTokenize = jest.fn();
    installMock({ onTokenize });
    const ref = createRef<CardFormHandle>();

    render(
      <HyperPaymentMethodSession
        hyper={hyper}
        options={{
          sdkAuthorization: 'sdk_auth',
          vaultDetails: details(),
        }}
      >
        <CardForm ref={ref}>
          <CardNumberField options={{ savedCard: saved('tok_saved') }} />
        </CardForm>
      </HyperPaymentMethodSession>
    );

    await waitFor(() =>
      expect(screen.getByTestId('mock-field-cardNumber')).toBeTruthy()
    );

    const result = await tokenizeVia(ref);
    expect(errorOf(result)?.code).toBe('unsupported_configuration');
    expect(errorOf(result)?.message).toMatch(/cardNumber/);
    expect(onTokenize).not.toHaveBeenCalled();
  });

  it('stops treating the form as saved-card once the CVC field unmounts', async () => {
    installMock();
    const ref = createRef<CardFormHandle>();

    const view = render(
      <HyperPaymentMethodSession
        hyper={hyper}
        options={{
          sdkAuthorization: 'sdk_auth',
          vaultDetails: details(),
        }}
      >
        <CardForm ref={ref}>
          <CardCVCField options={{ savedCard: saved('tok_saved') }} />
        </CardForm>
      </HyperPaymentMethodSession>
    );

    await waitFor(() =>
      expect(screen.getByTestId('mock-field-cardCvc')).toBeTruthy()
    );

    view.rerender(
      <HyperPaymentMethodSession
        hyper={hyper}
        options={{
          sdkAuthorization: 'sdk_auth',
          vaultDetails: details(),
        }}
      >
        <CardForm ref={ref}>
          <CardNumberField />
        </CardForm>
      </HyperPaymentMethodSession>
    );

    await waitFor(() =>
      expect(screen.getByTestId('mock-field-cardNumber')).toBeTruthy()
    );

    const result = await tokenizeVia(ref);
    expect(result?.status).toBe('success');
    expect(dataOf(result)?.savedCard).toBeUndefined();
  });

  it('keeps the incoming result.card alongside the saved card', async () => {
    const ref = renderSavedCard(saved('tok_saved', 'Visa'), undefined, {
      cardDetails: { last4: '4242', brand: 'Visa' },
    });

    await waitFor(() =>
      expect(screen.getByTestId('mock-field-cardCvc')).toBeTruthy()
    );

    const result = await tokenizeVia(ref);
    expect(result?.status === 'success' && result.card).toEqual({
      last4: '4242',
      brand: 'Visa',
    });
    expect(dataOf(result)?.savedCard).toEqual({
      paymentMethodToken: 'tok_saved',
      paymentMethodData: { card: { cardNetwork: 'Visa' } },
    });
  });
});

describe('usePaymentMethodsSession', () => {
  it('throws outside a <HyperPaymentMethodSession>', () => {
    function Probe() {
      usePaymentMethodsSession();
      return null;
    }
    expect(() => render(<Probe />)).toThrow(
      /must be used inside a <HyperPaymentMethodSession>/
    );
  });
});

describe('resolving the vault from an sdkAuthorization', () => {
  const VALID_AUTH = Buffer.from(
    'payment_method_session_id=0a_pms_0192,profile_id=pro_456',
    'utf8'
  ).toString('base64');

  const vgsSession = {
    id: '0a_pms_0192',
    external_vault_details: {
      vgs: { external_vault_id: 'tnt_abc', sdk_env: 'sandbox' },
    },
  };

  const originalFetch = globalThis.fetch;
  let fetchMock: jest.Mock<(...args: unknown[]) => Promise<unknown>>;

  beforeEach(() => {
    fetchMock = jest.fn<(...args: unknown[]) => Promise<unknown>>();
    (globalThis as { fetch?: unknown }).fetch = fetchMock;
  });

  afterEach(() => {
    (globalThis as { fetch?: unknown }).fetch = originalFetch;
  });

  function VaultProbe() {
    const session = usePaymentMethodsSession();
    return (
      <Text testID="vault">
        {session.vaultDetails
          ? `${session.vaultDetails.vaultType}:${JSON.stringify(
              session.vaultDetails.vaultData
            )}`
          : `none:${session.loading}:${session.error?.message ?? ''}`}
      </Text>
    );
  }

  it('looks the vault up, then drives the form with it', async () => {
    installMock({ vaultType: 'vgs' });
    fetchMock.mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => vgsSession,
    });
    const ref = createRef<CardFormHandle>();

    render(
      <HyperPaymentMethodSession
        hyper={hyper}
        options={{ sdkAuthorization: VALID_AUTH }}
      >
        <VaultProbe />
        <CardForm ref={ref}>
          <CardNumberField />
        </CardForm>
      </HyperPaymentMethodSession>
    );

    await waitFor(() =>
      expect(screen.getByTestId('vault').props.children).toBe(
        'vgs:{"vaultId":"tnt_abc","environment":"sandbox"}'
      )
    );

    await waitFor(() =>
      expect(screen.getByTestId('mock-field-cardNumber')).toBeTruthy()
    );
    expect((await tokenizeVia(ref))?.status).toBe('success');
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('accepts a checkout-SDK session as the instance', async () => {
    installMock({ vaultType: 'vgs' });
    fetchMock.mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => vgsSession,
    });

    const checkoutSession = Promise.resolve({ publishableKey: 'pk_test' });

    render(
      <HyperPaymentMethodSession
        hyper={checkoutSession}
        options={{ sdkAuthorization: VALID_AUTH }}
      >
        <VaultProbe />
      </HyperPaymentMethodSession>
    );

    await waitFor(() =>
      expect(screen.getByTestId('vault').props.children).toBe(
        'vgs:{"vaultId":"tnt_abc","environment":"sandbox"}'
      )
    );
    const init = fetchMock.mock.calls[0]![1] as {
      headers: Record<string, string>;
    };
    expect(init.headers.Authorization).toBe(VALID_AUTH);
    expect('X-Profile-Id' in init.headers).toBe(false);
  });

  it('takes the endpoint configuration off the instance, not options', async () => {
    installMock({ vaultType: 'vgs' });
    fetchMock.mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => vgsSession,
    });

    render(
      <HyperPaymentMethodSession
        hyper={Hyperswitch.init({
          publishableKey: 'pk_test',
          profileId: 'pro_456',
          environment: 'PROD',
        })}
        options={{ sdkAuthorization: VALID_AUTH }}
      >
        <VaultProbe />
      </HyperPaymentMethodSession>
    );

    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(1));
    expect(fetchMock.mock.calls[0]![0]).toBe(
      'https://live.hyperswitch.io/api/v1/payment-method-sessions/0a_pms_0192'
    );
  });

  it('skips the lookup entirely when vaultDetails is supplied too', async () => {
    installMock({ vaultType: 'skyflow' });
    const ref = createRef<CardFormHandle>();

    render(
      <HyperPaymentMethodSession
        hyper={hyper}
        options={{
          sdkAuthorization: VALID_AUTH,
          vaultDetails: details('skyflow'),
        }}
      >
        <CardForm ref={ref}>
          <CardNumberField />
        </CardForm>
      </HyperPaymentMethodSession>
    );

    await waitFor(() =>
      expect(screen.getByTestId('mock-field-cardNumber')).toBeTruthy()
    );
    expect((await tokenizeVia(ref))?.vaultType).toBe('skyflow');
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('answers sdk_not_ready while the lookup is still in flight', async () => {
    installMock({ vaultType: 'vgs' });

    fetchMock.mockImplementation(
      (_url, init) =>
        new Promise((_resolve, reject) => {
          const signal = (init as { signal?: AbortSignal } | undefined)?.signal;
          signal?.addEventListener('abort', () => reject(new Error('aborted')));
        })
    );
    const ref = createRef<CardFormHandle>();

    render(
      <HyperPaymentMethodSession
        hyper={hyper}
        options={{ sdkAuthorization: VALID_AUTH }}
      >
        <VaultProbe />
        <CardForm ref={ref}>
          <CardNumberField />
        </CardForm>
      </HyperPaymentMethodSession>
    );

    await waitFor(() =>
      expect(screen.getByTestId('vault').props.children).toBe('none:true:')
    );

    const result = await tokenizeVia(ref);
    expect(result?.status).toBe('error');
    expect(errorOf(result)?.code).toBe('sdk_not_ready');
  });

  it('reports a failed lookup, and says why when tokenize is called', async () => {
    installMock({ vaultType: 'vgs' });
    fetchMock.mockResolvedValue({
      ok: false,
      status: 401,
      json: async () => ({}),
    });
    const onError = jest.fn();
    const ref = createRef<CardFormHandle>();

    render(
      <HyperPaymentMethodSession
        hyper={hyper}
        options={{ sdkAuthorization: VALID_AUTH }}
        onError={onError}
      >
        <VaultProbe />
        <CardForm ref={ref}>
          <CardNumberField />
        </CardForm>
      </HyperPaymentMethodSession>
    );

    await waitFor(() =>
      expect(screen.getByTestId('vault').props.children).toBe(
        'none:false:The payment-method-session lookup returned status 401.'
      )
    );
    expect(onError).toHaveBeenCalledTimes(1);

    const result = await tokenizeVia(ref);
    expect(errorOf(result)?.code).toBe('unsupported_configuration');
    expect(errorOf(result)?.message).toMatch(/status 401/);
  });
});
