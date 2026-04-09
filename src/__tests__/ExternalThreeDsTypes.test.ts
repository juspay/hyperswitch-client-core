import {
  authResponseItemToObjMapper,
  pollResponseItemToObjMapper,
} from '../types/ExternalThreeDsTypes.bs.js';

describe('ExternalThreeDsTypes', () => {
  describe('authResponseItemToObjMapper', () => {
    describe('happy path - auth response', () => {
      it('returns AUTH_RESPONSE for valid dict with trans_status', () => {
        const dict = {
          trans_status: 'Y',
          acs_signed_content: 'signed_content_value',
          acs_reference_number: 'ref_123',
          acs_trans_id: 'trans_456',
          three_ds_requestor_app_url: 'https://example.com',
          three_dsserver_trans_id: 'server_trans_789',
        };
        const result = authResponseItemToObjMapper(dict);
        expect(result.TAG).toBe('AUTH_RESPONSE');
        expect(result._0.transStatus).toBe('Y');
        expect(result._0.acsSignedContent).toBe('signed_content_value');
        expect(result._0.acsRefNumber).toBe('ref_123');
        expect(result._0.acsTransactionId).toBe('trans_456');
        expect(result._0.threeDSRequestorAppURL).toBe('https://example.com');
        expect(result._0.threeDSServerTransId).toBe('server_trans_789');
        expect(result._0.dsTransactionId).toBe('');
      });

      it('returns AUTH_RESPONSE with empty strings for missing optional fields', () => {
        const dict = {};
        const result = authResponseItemToObjMapper(dict);
        expect(result.TAG).toBe('AUTH_RESPONSE');
        expect(result._0.transStatus).toBe('');
        expect(result._0.acsSignedContent).toBe('');
        expect(result._0.acsRefNumber).toBe('');
        expect(result._0.acsTransactionId).toBe('');
        expect(result._0.threeDSRequestorAppURL).toBeUndefined();
        expect(result._0.threeDSServerTransId).toBe('');
        expect(result._0.dsTransactionId).toBe('');
      });

      it('returns AUTH_RESPONSE with partial data', () => {
        const dict = {
          trans_status: 'N',
          acs_trans_id: 'trans_only',
        };
        const result = authResponseItemToObjMapper(dict);
        expect(result.TAG).toBe('AUTH_RESPONSE');
        expect(result._0.transStatus).toBe('N');
        expect(result._0.acsTransactionId).toBe('trans_only');
        expect(result._0.acsSignedContent).toBe('');
      });
    });

    describe('error path - auth error', () => {
      it('returns AUTH_ERROR when dict contains error object', () => {
        const dict = {
          error: {
            code: 'ERR_001',
            message: 'Authentication failed',
          },
        };
        const result = authResponseItemToObjMapper(dict);
        expect(result.TAG).toBe('AUTH_ERROR');
        expect(result._0.errorCode).toBe('"ERR_001"');
        expect(result._0.errorMessage).toBe('"Authentication failed"');
      });

      it('returns AUTH_ERROR with nested error structure', () => {
        const dict = {
          error: {
            code: { value: 'COMPLEX_CODE' },
            message: { text: 'Complex error message' },
          },
        };
        const result = authResponseItemToObjMapper(dict);
        expect(result.TAG).toBe('AUTH_ERROR');
        expect(result._0.errorCode).toBe('{"value":"COMPLEX_CODE"}');
        expect(result._0.errorMessage).toBe('{"text":"Complex error message"}');
      });

      it('returns AUTH_ERROR with missing code and message', () => {
        const dict = {
          error: {},
        };
        const result = authResponseItemToObjMapper(dict);
        expect(result.TAG).toBe('AUTH_ERROR');
        expect(result._0.errorCode).toBe('null');
        expect(result._0.errorMessage).toBe('null');
      });
    });

    describe('edge cases', () => {
      it('handles null input gracefully', () => {
        const result = authResponseItemToObjMapper(null);
        expect(result.TAG).toBe('AUTH_RESPONSE');
      });

      it('handles undefined input gracefully', () => {
        const result = authResponseItemToObjMapper(undefined);
        expect(result.TAG).toBe('AUTH_RESPONSE');
      });

      it('handles empty object input', () => {
        const result = authResponseItemToObjMapper({});
        expect(result.TAG).toBe('AUTH_RESPONSE');
        expect(result._0.transStatus).toBe('');
      });
    });
  });

  describe('pollResponseItemToObjMapper', () => {
    describe('happy path', () => {
      it('returns poll response with poll_id and status', () => {
        const dict = {
          poll_id: 'poll_123',
          status: 'completed',
        };
        const result = pollResponseItemToObjMapper(dict);
        expect(result.pollId).toBe('poll_123');
        expect(result.status).toBe('completed');
      });

      it('returns poll response with different status values', () => {
        const dict = {
          poll_id: 'poll_456',
          status: 'pending',
        };
        const result = pollResponseItemToObjMapper(dict);
        expect(result.pollId).toBe('poll_456');
        expect(result.status).toBe('pending');
      });
    });

    describe('edge cases', () => {
      it('returns empty strings for missing poll_id', () => {
        const dict = {
          status: 'active',
        };
        const result = pollResponseItemToObjMapper(dict);
        expect(result.pollId).toBe('');
        expect(result.status).toBe('active');
      });

      it('returns empty strings for missing status', () => {
        const dict = {
          poll_id: 'poll_789',
        };
        const result = pollResponseItemToObjMapper(dict);
        expect(result.pollId).toBe('poll_789');
        expect(result.status).toBe('');
      });

      it('returns empty strings for empty dict', () => {
        const result = pollResponseItemToObjMapper({});
        expect(result.pollId).toBe('');
        expect(result.status).toBe('');
      });

      it('handles extra fields gracefully', () => {
        const dict = {
          poll_id: 'poll_123',
          status: 'completed',
          extra_field: 'ignored',
        };
        const result = pollResponseItemToObjMapper(dict);
        expect(result.pollId).toBe('poll_123');
        expect(result.status).toBe('completed');
      });
    });
  });
});
