import { describe, it, expect } from '@jest/globals';

import { Hyperswitch, init } from '../init';

describe('Hyperswitch.init', () => {
  it('resolves to the instance the session takes', async () => {
    const instance = await init({
      publishableKey: 'pk_test',
      profileId: 'pro_456',
    });
    expect(instance).toMatchObject({
      publishableKey: 'pk_test',
      profileId: 'pro_456',
    });
    expect(typeof instance.initPaymentMethodSession).toBe('function');
  });

  it('is reachable as Hyperswitch.init, as the checkout SDK spells it', async () => {
    await expect(
      Hyperswitch.init({ publishableKey: 'pk_test' })
    ).resolves.toMatchObject({ publishableKey: 'pk_test' });
  });

  it('carries the endpoint configuration', async () => {
    await expect(
      init({
        publishableKey: 'pk_test',
        platformPublishableKey: 'pk_platform',
        environment: 'PROD',
        customEndpoints: { commonEndpoint: 'https://vault.acme.test/api' },
      })
    ).resolves.toMatchObject({
      publishableKey: 'pk_test',
      platformPublishableKey: 'pk_platform',
      environment: 'PROD',
      customEndpoints: { commonEndpoint: 'https://vault.acme.test/api' },
    });
  });

  it('omits a blank member rather than carrying undefined', async () => {
    const instance = await init({
      publishableKey: '  pk_test  ',
      profileId: '   ',
    });
    expect(instance.publishableKey).toBe('pk_test');
    expect('profileId' in instance).toBe(false);
    expect('environment' in instance).toBe(false);
  });

  it('rejects a missing publishable key', async () => {
    await expect(init({ publishableKey: '  ' })).rejects.toThrow(
      /non-empty publishableKey/
    );
  });
});
