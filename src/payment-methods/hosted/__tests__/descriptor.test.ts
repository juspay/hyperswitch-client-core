import { describe, it, expect } from '@jest/globals';

import {
  descriptorKey,
  readFieldDescriptor,
  readFormDescriptor,
} from '../descriptor';
import {
  PROTOCOL_VERSION,
  SURFACE_TYPE_FIELD,
  SURFACE_TYPE_FORM,
} from '../protocol';

const form = {
  type: SURFACE_TYPE_FORM,
  protocolVersion: PROTOCOL_VERSION,
  formId: 'form-1',
  hyper: { publishableKey: 'pk_snd_1' },
  sdkAuthorization: 'auth',
};

const field = {
  type: SURFACE_TYPE_FIELD,
  protocolVersion: PROTOCOL_VERSION,
  formId: 'form-1',
  elementType: 'cardNumber',
};

const messageOf = (result: { ok: boolean; message?: string }) =>
  result.ok ? null : result.message;

describe('readFormDescriptor', () => {
  it('accepts a session to look up, or vault details handed over directly', () => {
    expect(readFormDescriptor(form).ok).toBe(true);

    const { sdkAuthorization: _sdkAuthorization, ...withoutAuth } = form;
    expect(messageOf(readFormDescriptor(withoutAuth))).toMatch(
      /sdkAuthorization or vaultDetails/
    );
    expect(
      readFormDescriptor({
        ...withoutAuth,
        vaultDetails: { vaultType: 'vgs', vaultData: {} },
      }).ok
    ).toBe(true);
  });

  it('needs a publishable key and a form id', () => {
    expect(
      messageOf(readFormDescriptor({ ...form, hyper: { publishableKey: ' ' } }))
    ).toMatch(/publishableKey/);
    expect(messageOf(readFormDescriptor({ ...form, formId: '' }))).toMatch(
      /formId/
    );
  });

  it('accepts an older protocol and refuses a newer one', () => {
    expect(readFormDescriptor({ ...form, protocolVersion: 1 }).ok).toBe(true);
    expect(
      messageOf(
        readFormDescriptor({ ...form, protocolVersion: PROTOCOL_VERSION + 1 })
      )
    ).toMatch(/Update the SDK bundle/);
    expect(
      messageOf(readFormDescriptor({ ...form, protocolVersion: '1' }))
    ).toMatch(/positive integer/);
  });
});

describe('readFieldDescriptor', () => {
  it('accepts a known field and refuses an unknown one', () => {
    expect(readFieldDescriptor(field).ok).toBe(true);
    expect(
      messageOf(readFieldDescriptor({ ...field, elementType: 'cardPin' }))
    ).toMatch(/Unknown elementType/);
    expect(messageOf(readFieldDescriptor(form))).toMatch(/Unsupported type/);
  });
});

describe('descriptorKey', () => {
  it('is equal for equal props, whatever object carries them', () => {
    expect(descriptorKey({ ...form })).toBe(descriptorKey({ ...form }));
    expect(descriptorKey({ ...form, formId: 'form-2' })).not.toBe(
      descriptorKey(form)
    );
  });
});

describe('withEnvironment', () => {
  const { withEnvironment } = require('../forms') as typeof import('../forms');

  it('goes by the key, as the payments SDK does', () => {
    expect(withEnvironment({ publishableKey: 'pk_snd_abc' }).environment).toBe(
      'SANDBOX'
    );
    expect(withEnvironment({ publishableKey: 'pk_prd_abc' }).environment).toBe(
      'PROD'
    );
  });

  it('is not misled by a default: Android names PROD unless told otherwise', () => {
    expect(
      withEnvironment({ publishableKey: 'pk_snd_abc', environment: 'PROD' })
        .environment
    ).toBe('SANDBOX');
  });

  it('keeps INTEG, which no key can tell apart from sandbox', () => {
    expect(
      withEnvironment({ publishableKey: 'pk_snd_abc', environment: 'INTEG' })
        .environment
    ).toBe('INTEG');
  });
});
