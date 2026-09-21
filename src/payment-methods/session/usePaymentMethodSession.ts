import { usePaymentMethodsSession } from './usePaymentMethodsSession';
import type { PaymentMethodsSession } from './SessionContext';

export function usePaymentMethodSession(): PaymentMethodsSession {
  return usePaymentMethodsSession();
}
