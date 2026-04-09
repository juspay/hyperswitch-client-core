import {
  getThreeDsNextActionObj,
  getThreeDsDataObj,
  generateAuthenticationCallBody,
  getAuthCallHeaders,
  isStatusSuccess,
  sdkEnvironmentToStrMapper,
} from '../utility/logics/ThreeDsUtils.bs.js';

describe('ThreeDsUtils', () => {
  describe('getThreeDsNextActionObj', () => {
    it('returns parsed 3DS next action object', () => {
      const nextAction = {
        redirectToUrl: 'https://example.com/3ds',
        type_: 'three_ds',
        threeDsData: {
          threeDsAuthenticationUrl: 'https://auth.example.com',
          threeDsAuthorizeUrl: 'https://authorize.example.com',
          messageVersion: '2.1.0',
          directoryServerId: '12345',
          pollConfig: {
            pollId: 'poll_123',
            delayInSecs: 5,
            frequency: 10,
          },
        },
      };
      const result = getThreeDsNextActionObj(nextAction);
      expect(result.redirectToUrl).toBe('https://example.com/3ds');
      expect(result.type_).toBe('three_ds');
      expect(result.threeDsData.messageVersion).toBe('2.1.0');
    });

    it('returns default object for undefined input', () => {
      const result = getThreeDsNextActionObj(undefined);
      expect(result.redirectToUrl).toBe('');
      expect(result.type_).toBe('');
      expect(result.threeDsData.threeDsAuthenticationUrl).toBe('');
    });

    it('handles missing threeDsData', () => {
      const nextAction = {
        redirectToUrl: 'https://example.com',
        type_: 'redirect',
      };
      const result = getThreeDsNextActionObj(nextAction);
      expect(result.redirectToUrl).toBe('https://example.com');
    });
  });

  describe('getThreeDsDataObj', () => {
    it('returns 3DS data from next action object', () => {
      const nextAction = {
        redirectToUrl: '',
        type_: '',
        threeDsData: {
          threeDsAuthenticationUrl: 'https://auth.example.com',
          threeDsAuthorizeUrl: 'https://authorize.example.com',
          messageVersion: '2.1.0',
          directoryServerId: '12345',
          pollConfig: {
            pollId: 'poll_123',
            delayInSecs: 5,
            frequency: 10,
          },
        },
      };
      const result = getThreeDsDataObj(nextAction);
      expect(result.threeDsAuthenticationUrl).toBe('https://auth.example.com');
      expect(result.messageVersion).toBe('2.1.0');
      expect(result.pollConfig.pollId).toBe('poll_123');
    });

    it('returns default object for missing threeDsData', () => {
      const nextAction = {
        redirectToUrl: '',
        type_: '',
      };
      const result = getThreeDsDataObj(nextAction);
      expect(result.threeDsAuthenticationUrl).toBe('');
      expect(result.messageVersion).toBe('');
    });
  });

  describe('generateAuthenticationCallBody', () => {
    it('generates correct authentication call body', () => {
      const clientSecret = 'pay_123_secret_abc';
      const aReqParams = {
        sdkAppId: 'app_123',
        deviceData: 'encrypted_data',
        sdkEphemeralKey: JSON.stringify({
          kty: 'EC',
          crv: 'P-256',
          x: 'x_value',
          y: 'y_value',
        }),
        sdkTransId: 'trans_123',
        sdkReferenceNo: 'ref_123',
      };
      const result = JSON.parse(generateAuthenticationCallBody(clientSecret, aReqParams));
      expect(result.client_secret).toBe('pay_123_secret_abc');
      expect(result.device_channel).toBe('APP');
      expect(result.sdk_information.sdk_app_id).toBe('app_123');
      expect(result.sdk_information.sdk_ephem_pub_key.kty).toBe('EC');
      expect(result.sdk_information.sdk_trans_id).toBe('trans_123');
      expect(result.sdk_information.sdk_max_timeout).toBe(10);
    });

    it('throws for invalid JSON ephemeral key', () => {
      const clientSecret = 'pay_123_secret_abc';
      const aReqParams = {
        sdkAppId: 'app_123',
        deviceData: 'encrypted_data',
        sdkEphemeralKey: 'invalid json',
        sdkTransId: 'trans_123',
        sdkReferenceNo: 'ref_123',
      };
      expect(() => generateAuthenticationCallBody(clientSecret, aReqParams)).toThrow();
    });

    it('includes correct device channel', () => {
      const aReqParams = {
        sdkAppId: 'app_123',
        deviceData: 'data',
        sdkEphemeralKey: '{}',
        sdkTransId: 'trans_123',
        sdkReferenceNo: 'ref_123',
      };
      const result = JSON.parse(generateAuthenticationCallBody('secret', aReqParams));
      expect(result.device_channel).toBe('APP');
    });
  });

  describe('getAuthCallHeaders', () => {
    it('returns correct headers object', () => {
      const result = getAuthCallHeaders('pk_test_123');
      expect(result['Content-Type']).toBe('application/json');
      expect(result['api-key']).toBe('pk_test_123');
      expect(result['Accept']).toBe('application/json');
    });

    it('handles empty publishable key', () => {
      const result = getAuthCallHeaders('');
      expect(result['api-key']).toBe('');
    });

    it('handles production key', () => {
      const result = getAuthCallHeaders('pk_prd_live_123');
      expect(result['api-key']).toBe('pk_prd_live_123');
    });
  });

  describe('isStatusSuccess', () => {
    it('returns true for success status', () => {
      expect(isStatusSuccess({ status: 'success' })).toBe(true);
    });

    it('returns false for failed status', () => {
      expect(isStatusSuccess({ status: 'failed' })).toBe(false);
    });

    it('returns false for pending status', () => {
      expect(isStatusSuccess({ status: 'pending' })).toBe(false);
    });

    it('returns false for empty status', () => {
      expect(isStatusSuccess({ status: '' })).toBe(false);
    });

    it('is case sensitive', () => {
      expect(isStatusSuccess({ status: 'Success' })).toBe(false);
      expect(isStatusSuccess({ status: 'SUCCESS' })).toBe(false);
    });
  });

  describe('sdkEnvironmentToStrMapper', () => {
    it('returns PROD for production environment', () => {
      expect(sdkEnvironmentToStrMapper('PROD')).toBe('PROD');
    });

    it('returns SANDBOX for sandbox environment', () => {
      expect(sdkEnvironmentToStrMapper('SANDBOX')).toBe('SANDBOX');
    });

    it('returns INTEG for integration environment', () => {
      expect(sdkEnvironmentToStrMapper('INTEG')).toBe('INTEG');
    });
  });
});
