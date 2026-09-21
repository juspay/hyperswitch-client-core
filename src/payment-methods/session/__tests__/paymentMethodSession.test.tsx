import {
  describe,
  it,
  expect,
  jest,
  afterEach,
  beforeEach,
} from '@jest/globals';
import { render, screen, act, waitFor } from '@testing-library/react-native';

import { Hyperswitch } from '../init';
import { registerAdapter } from '../../providers/registry';
import { CardNumberField, CardExpiryField, CardCVCField } from '../../fields';
import { createMockAdapter } from '../../__fixtures__/mockAdapter';
import type { MockAdapterOptions } from '../../__fixtures__/mockAdapter';
import type { TokenizeResult, VaultDetails } from '../../core/types';

const cleanups: Array<() => void> = [];
afterEach(() => {
  while (cleanups.length) cleanups.pop()!();
});

function installMock(options: MockAdapterOptions = {}) {
  cleanups.push(registerAdapter(createMockAdapter(options)));
}

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

const details = (): VaultDetails => ({ vaultType: 'vgs', vaultData: {} });

const originalFetch = globalThis.fetch;
let fetchMock: jest.Mock<(...args: unknown[]) => Promise<unknown>>;

beforeEach(() => {
  fetchMock = jest.fn<(...args: unknown[]) => Promise<unknown>>();
  (globalThis as { fetch?: unknown }).fetch = fetchMock;
});
afterEach(() => {
  (globalThis as { fetch?: unknown }).fetch = originalFetch;
});

describe('hyper.initPaymentMethodSession', () => {
  it('looks the vault up and hands back a session that can build a form', async () => {
    installMock({ vaultType: 'vgs' });
    fetchMock.mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => vgsSession,
    });

    const hyper = await Hyperswitch.init({
      publishableKey: 'pk_test',
      environment: 'SANDBOX',
    });
    const session = await hyper.initPaymentMethodSession({
      sdkAuthorization: VALID_AUTH,
    });

    expect(session.vaultDetails).toEqual({
      vaultType: 'vgs',
      vaultData: { vaultId: 'tnt_abc', environment: 'sandbox' },
    });
    expect(fetchMock.mock.calls[0]![0]).toBe(
      'https://app.hyperswitch.io/api/v1/payment-method-sessions/0a_pms_0192'
    );

    const cardForm = session.createCardForm();
    render(
      <>
        <CardNumberField form={cardForm} />
        <CardExpiryField form={cardForm} />
        <CardCVCField form={cardForm} />
      </>
    );

    await waitFor(() =>
      expect(screen.getByTestId('mock-field-cardNumber')).toBeTruthy()
    );

    let result: TokenizeResult | undefined;
    await act(async () => {
      result = await cardForm.tokenize();
    });
    expect(result?.status).toBe('success');
    expect(cardForm.status).toBe('ready');
  });

  it('skips the lookup when vaultDetails is supplied', async () => {
    installMock({ vaultType: 'vgs' });
    const hyper = await Hyperswitch.init({ publishableKey: 'pk_test' });
    const session = await hyper.initPaymentMethodSession({
      vaultDetails: details(),
    });

    expect(session.vaultDetails).toEqual(details());
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('rejects when the lookup fails, at the call site', async () => {
    installMock({ vaultType: 'vgs' });
    fetchMock.mockResolvedValue({
      ok: false,
      status: 401,
      json: async () => ({}),
    });

    const hyper = await Hyperswitch.init({ publishableKey: 'pk_test' });
    await expect(
      hyper.initPaymentMethodSession({ sdkAuthorization: VALID_AUTH })
    ).rejects.toThrow(/status 401/);
  });

  it('refuses to build a detached form for a provider that needs its own React provider', async () => {
    /* An adapter with no createCollector — Skyflow, Basis Theory and Evervault are these. */
    cleanups.push(
      registerAdapter({
        vaultType: 'skyflow',
        validateVaultData: (raw) => raw,
        Host: () => null,
        Field: () => null,
        tokenize: async () => ({ status: 'success' as const }),
      })
    );

    const hyper = await Hyperswitch.init({ publishableKey: 'pk_test' });
    const session = await hyper.initPaymentMethodSession({
      vaultDetails: { vaultType: 'skyflow', vaultData: {} },
    });

    expect(() => session.createCardForm()).toThrow(
      /cannot be mounted detached.*<CardForm>/s
    );
  });

  it('rejects when neither sdkAuthorization nor vaultDetails is given', async () => {
    const hyper = await Hyperswitch.init({ publishableKey: 'pk_test' });
    await expect(hyper.initPaymentMethodSession({})).rejects.toThrow(
      /sdkAuthorization or vaultDetails/
    );
  });

  it('tokenizes with no field mounted and no wrapper, once the collector attaches', async () => {
    installMock({ vaultType: 'vgs' });
    const hyper = await Hyperswitch.init({ publishableKey: 'pk_test' });
    const session = await hyper.initPaymentMethodSession({
      vaultDetails: details(),
    });
    const cardForm = session.createCardForm();

    const result = await cardForm.tokenize();
    expect(result.status).toBe('success');
  });
});
