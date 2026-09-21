import { useContext } from 'react';
import { SessionContext } from './SessionContext';
import type { PaymentMethodsSession } from './SessionContext';

export function usePaymentMethodsSession(): PaymentMethodsSession {
  const session = useContext(SessionContext);
  if (!session) {
    throw new Error(
      'usePaymentMethodsSession must be used inside a <HyperPaymentMethodSession>.'
    );
  }
  return session;
}
