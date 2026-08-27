import {readFileSync} from 'fs';
import path from 'path';

import {getActionType} from '../src/utility/logics/PaymentUtils.bs.js';
import {getNextAction} from '../src/types/AllApiDataTypes/PaymentConfirmTypes.bs.js';

const source = readFileSync(
  path.join(__dirname, '../src/hooks/AllPaymentHooks.res'),
  'utf8',
);

describe('next-action type selection (behavioural)', () => {
  it.each([
    'three_ds_invoke',
    'third_party_sdk_session_token',
    'display_bank_transfer_information',
    'invoke_ddc',
    'redirect_to_url',
  ])('reads %s off the next action', type => {
    expect(getActionType({redirectToUrl: '', type_: type})).toBe(type);
  });

  it('reads an empty type when there is no next action', () => {
    expect(getActionType(undefined)).toBe('');
  });
});

describe('next-action payload parsing (behavioural)', () => {
  const parse = nextAction => getNextAction({next_action: nextAction}, 'next_action');

  it('lifts the redirect URL', () => {
    expect(parse({type: 'redirect_to_url', redirect_to_url: 'https://3ds.example/go'}).redirectToUrl)
      .toBe('https://3ds.example/go');
  });

  it('lifts the 3DS fields client-core actually uses', () => {
    const parsed = parse({
      type: 'three_ds_invoke',
      three_ds_data: {
        three_ds_authentication_url: 'https://auth.example',
        three_ds_authorize_url: 'https://authorize.example',
        message_version: '2.2.0',
        directory_server_id: 'ds_1',
        poll_config: {poll_id: 'poll_1', delay_in_secs: 2, frequency: 5},
      },
    });
    expect(parsed.threeDsData.threeDsAuthenticationUrl).toBe('https://auth.example');
    expect(parsed.threeDsData.threeDsAuthorizeUrl).toBe('https://authorize.example');
    expect(parsed.threeDsData.messageVersion).toBe('2.2.0');
    expect(parsed.threeDsData.directoryServerId).toBe('ds_1');
    expect(parsed.threeDsData.pollConfig.pollId).toBe('poll_1');
    expect(parsed.threeDsData.pollConfig.delayInSecs).toBe(2);
    expect(parsed.threeDsData.pollConfig.frequency).toBe(5);
  });

  it('lifts the DDC fields, defaulting the timeout to 30s', () => {
    const parsed = parse({type: 'invoke_ddc', ddc_data: {iframe_url: 'https://ddc.example'}});
    expect(parsed.ddc_data.iframeUrl).toBe('https://ddc.example');
    expect(parsed.ddc_data.timeoutMs).toBe(30000);

    const explicit = parse({
      type: 'invoke_ddc',
      ddc_data: {iframe_url: 'https://ddc.example', timeout_ms: 15000},
    });
    expect(explicit.ddc_data.timeoutMs).toBe(15000);
  });

  it('lifts the third-party session token', () => {
    const parsed = parse({
      type: 'third_party_sdk_session_token',
      session_token: {wallet_name: 'open_banking', open_banking_session_token: 'obst_1'},
    });
    expect(parsed.session_token.wallet_name).toBe('open_banking');
    expect(parsed.session_token.open_banking_session_token).toBe('obst_1');
  });

  it('lifts the bank-transfer details', () => {
    const parsed = parse({
      type: 'display_bank_transfer_information',
      bank_transfer_steps_and_charges_details: {
        ach_credit_transfer: {
          account_number: '1234',
          bank_name: 'Example Bank',
          routing_number: '5678',
          swift_code: 'EXMPUS33',
        },
      },
    });
    const ach = parsed.bank_transfer_steps_and_charges_detail.ach_credit_transfer;
    expect(ach.account_number).toBe('1234');
    expect(ach.bank_name).toBe('Example Bank');
  });
});

describe('next-action dispatch table (source pin)', () => {
  const block = /let useNextActionDispatcher = \(\) => \{([\s\S]*?)\n\}/.exec(source);

  it('exists and switches on the next-action type before the status', () => {
    expect(block).not.toBeNull();
    expect(block[1]).toContain('PaymentUtils.getActionType');
  });

  it('is the single implementation — the classic confirm delegates to it', () => {
    expect(source).toContain('let dispatchNextAction = useNextActionDispatcher()');
    expect(/let handleApiRes = dispatchNextAction\(/.test(source)).toBe(true);
    expect(source.match(/switch nextAction->PaymentUtils\.getActionType/g)).toHaveLength(1);
  });

  it.each([
    ['three_ds_invoke', 'handleInvokeThreeDSFlow'],
    ['third_party_sdk_session_token', 'handleThirdPartySDKSessionFlow'],
    ['display_bank_transfer_information', 'handleBankTransferFlow'],
    ['invoke_ddc', 'handleInvokeDDCFlow'],
  ])('routes %s to %s', (type, handler) => {
    const arm = new RegExp(`\\|\\s*"${type}"\\s*=>\\s*(\\w+)`).exec(block[1]);
    expect(arm).not.toBeNull();
    expect(arm[1]).toBe(handler);
  });

  it('falls through to the status switch for every other next action', () => {
    expect(/\|\s*_\s*=>\s*handleDefaultPaymentFlows/.test(block[1])).toBe(true);
  });

  it('handles requires_customer_action by opening a browser redirection', () => {
    const arm = /\|\s*"requires_customer_action"\s*=>([\s\S]{0,600}?)\n\s*\|\s/.exec(source);
    expect(arm).not.toBeNull();
    expect(arm[1]).toContain('browserRedirectionHandler');
  });

  it('drives 3DS through a native module that needs the raw client secret and publishable key', () => {
    const arm = /let handleInvokeThreeDSFlow = \(([\s\S]*?)\n    \}/.exec(source);
    expect(arm).not.toBeNull();
    expect(arm[1]).toContain('~clientSecret');
    expect(arm[1]).toContain('~publishableKey');
    expect(arm[1]).toContain('~netceteraSDKApiKey');
  });

  it('drives the third-party SDK flow through Plaid with the open-banking session token', () => {
    const arm = /let handleThirdPartySDKSessionFlow = \(([\s\S]*?)\n    \}/.exec(source);
    expect(arm).not.toBeNull();
    expect(arm[1]).toContain('Plaid.create');
    expect(arm[1]).toContain('open_banking_session_token');
  });

  it('handles bank transfer by only showing a processing state', () => {
    const arm = /let handleBankTransferFlow = \(([\s\S]*?)\n    \}/.exec(source);
    expect(arm).not.toBeNull();
    expect(arm[1]).toContain('ProcessingPayments');
  });

  it('drives DDC through a native iframe bridge', () => {
    const arm = /let handleInvokeDDCFlow = \(([\s\S]*?)\n      \}\)/.exec(source);
    expect(arm).not.toBeNull();
    expect(arm[1]).toContain('HyperModule.openIframeBridge');
  });
});
