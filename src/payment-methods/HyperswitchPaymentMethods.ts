import { getFormTokenize } from './core/formRegistry';
import { errorResult } from './core/results';
import type { FormId, TokenizeResult } from './core/types';

export const HyperswitchPaymentMethods = {
  async tokenize(id: FormId, providerData?: unknown): Promise<TokenizeResult> {
    const tokenize = getFormTokenize(id);
    if (!tokenize) {
      return errorResult(
        undefined,
        'incomplete_field_set',
        `No <CardForm id="${id}"> is currently mounted. Pass that id to a form, or call tokenize() on the form ref instead.`
      );
    }
    return tokenize(providerData);
  },
};
