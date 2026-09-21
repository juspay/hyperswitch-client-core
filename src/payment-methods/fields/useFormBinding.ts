import { useContext, useSyncExternalStore } from 'react';
import { FormContext } from '../core/FormContext';
import type { FormContextValue } from '../core/FormContext';
import { coreOf } from '../core/formRegistry';
import type { CardFormInstance } from '../core/types';

const NO_STORE = () => () => {};
const NO_SNAPSHOT = () => undefined;

export function useFormBinding(
  form: CardFormInstance | undefined
): FormContextValue | null {
  const context = useContext(FormContext);
  const core = form ? coreOf(form) : undefined;

  const collector = useSyncExternalStore(
    core ? core.subscribe : NO_STORE,
    core ? () => core.collector : NO_SNAPSHOT
  );

  if (!core) return context;

  return {
    vaultType: core.vaultType,
    adapter: core.adapter,
    collector,
    status: core.status,
    appearances: core.appearances,
    unstyled: core.unstyled,
    tokenize: core.tokenize,
    reportChange: core.reportChange,
    registerField: core.registerField,
    forgetField: core.forgetField,
  };
}
