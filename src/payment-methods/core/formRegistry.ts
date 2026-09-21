import type { CardFormInstance, FormId, TokenizeResult } from './types';
import type { FormCore } from './formCore';

const cores = new WeakMap<CardFormInstance, FormCore>();

export function attachCore(instance: CardFormInstance, core: FormCore): void {
  cores.set(instance, core);
}

export function coreOf(instance: CardFormInstance): FormCore | undefined {
  return cores.get(instance);
}

export type FormTokenizeFn = (
  providerData?: unknown
) => Promise<TokenizeResult>;

const forms = new Map<FormId, FormTokenizeFn>();

export function registerForm(id: FormId, tokenize: FormTokenizeFn): () => void {
  forms.set(id, tokenize);
  return () => {
    if (forms.get(id) === tokenize) {
      forms.delete(id);
    }
  };
}

export function getFormTokenize(id: FormId): FormTokenizeFn | undefined {
  return forms.get(id);
}
