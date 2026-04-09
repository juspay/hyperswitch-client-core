import {
  retrievePaymentStatus,
  pollingCallStatus,
  externalThreeDsModuleStatus,
  authorizeCallStatus,
  authenticationCallStatus,
  threeDsSdkChallengeStatus,
  threeDsSDKGetAReqStatus,
} from '../utility/constants/SdkStatusMessages.bs.js';

describe('SdkStatusMessages', () => {
  describe('retrievePaymentStatus', () => {
    it('is defined and has expected structure', () => {
      expect(retrievePaymentStatus).toBeDefined();
      expect(typeof retrievePaymentStatus).toBe('object');
    });

    it('has successMsg property', () => {
      expect(retrievePaymentStatus.successMsg).toBe('payment successful');
    });

    it('has errorMsg property', () => {
      expect(retrievePaymentStatus.errorMsg).toBe('payment failed');
    });

    it('has apiCallFailure property', () => {
      expect(retrievePaymentStatus.apiCallFailure).toBe('retrieve failure, cannot fetch the status of payment');
    });
  });

  describe('pollingCallStatus', () => {
    it('is defined and has expected structure', () => {
      expect(pollingCallStatus).toBeDefined();
      expect(typeof pollingCallStatus).toBe('object');
    });

    it('has successMsg property', () => {
      expect(pollingCallStatus.successMsg).toBe('polling status complete');
    });

    it('has errorMsg property', () => {
      expect(pollingCallStatus.errorMsg).toBe('payment status pending');
    });

    it('has apiCallFailure property', () => {
      expect(pollingCallStatus.apiCallFailure).toBe('polling failure, cannot fetch the status of payment');
    });
  });

  describe('externalThreeDsModuleStatus', () => {
    it('is defined and has expected structure', () => {
      expect(externalThreeDsModuleStatus).toBeDefined();
      expect(typeof externalThreeDsModuleStatus).toBe('object');
    });

    it('has successMsg property', () => {
      expect(externalThreeDsModuleStatus.successMsg).toBe('external 3DS dependency found');
    });

    it('has errorMsg property', () => {
      expect(externalThreeDsModuleStatus.errorMsg).toBe('integration error, external 3DS dependency not found');
    });

    it('has apiCallFailure property', () => {
      expect(externalThreeDsModuleStatus.apiCallFailure).toBe('');
    });
  });

  describe('authorizeCallStatus', () => {
    it('is defined and has expected structure', () => {
      expect(authorizeCallStatus).toBeDefined();
      expect(typeof authorizeCallStatus).toBe('object');
    });

    it('has successMsg property', () => {
      expect(authorizeCallStatus.successMsg).toBe('payment authorised successfully');
    });

    it('has errorMsg property', () => {
      expect(authorizeCallStatus.errorMsg).toBe('authorize failed');
    });

    it('has apiCallFailure property', () => {
      expect(authorizeCallStatus.apiCallFailure).toBe('authorize failure, cannot process this payment');
    });
  });

  describe('authenticationCallStatus', () => {
    it('is defined and has expected structure', () => {
      expect(authenticationCallStatus).toBeDefined();
      expect(typeof authenticationCallStatus).toBe('object');
    });

    it('has successMsg property', () => {
      expect(authenticationCallStatus.successMsg).toBe('authentication call successful');
    });

    it('has errorMsg property', () => {
      expect(authenticationCallStatus.errorMsg).toBe('authentication call fail');
    });

    it('has apiCallFailure property', () => {
      expect(authenticationCallStatus.apiCallFailure).toBe('authentication failure,something wrong with AReq');
    });
  });

  describe('threeDsSdkChallengeStatus', () => {
    it('is defined and has expected structure', () => {
      expect(threeDsSdkChallengeStatus).toBeDefined();
      expect(typeof threeDsSdkChallengeStatus).toBe('object');
    });

    it('has successMsg property', () => {
      expect(threeDsSdkChallengeStatus.successMsg).toBe('challenge generated successfully');
    });

    it('has errorMsg property', () => {
      expect(threeDsSdkChallengeStatus.errorMsg).toBe('challenge generation failed');
    });

    it('has apiCallFailure property', () => {
      expect(threeDsSdkChallengeStatus.apiCallFailure).toBe('');
    });
  });

  describe('threeDsSDKGetAReqStatus', () => {
    it('is defined and has expected structure', () => {
      expect(threeDsSDKGetAReqStatus).toBeDefined();
      expect(typeof threeDsSDKGetAReqStatus).toBe('object');
    });

    it('has successMsg property', () => {
      expect(threeDsSDKGetAReqStatus.successMsg).toBe('');
    });

    it('has errorMsg property', () => {
      expect(threeDsSDKGetAReqStatus.errorMsg).toBe('3DS SDK DDC failure, cannot generate AReq params');
    });

    it('has apiCallFailure property', () => {
      expect(threeDsSDKGetAReqStatus.apiCallFailure).toBe('');
    });
  });

  describe('all status message objects have consistent structure', () => {
    const allStatusMessages = [
      retrievePaymentStatus,
      pollingCallStatus,
      externalThreeDsModuleStatus,
      authorizeCallStatus,
      authenticationCallStatus,
      threeDsSdkChallengeStatus,
      threeDsSDKGetAReqStatus,
    ];

    it('all have successMsg, errorMsg, and apiCallFailure properties', () => {
      allStatusMessages.forEach((statusObj) => {
        expect(statusObj).toHaveProperty('successMsg');
        expect(statusObj).toHaveProperty('errorMsg');
        expect(statusObj).toHaveProperty('apiCallFailure');
      });
    });

    it('all properties are strings', () => {
      allStatusMessages.forEach((statusObj) => {
        expect(typeof statusObj.successMsg).toBe('string');
        expect(typeof statusObj.errorMsg).toBe('string');
        expect(typeof statusObj.apiCallFailure).toBe('string');
      });
    });
  });
});
