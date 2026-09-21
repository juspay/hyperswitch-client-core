import { buildChange } from '../core/CardForm';
import { coreOf } from '../core/formRegistry';
import { messageOf } from '../core/results';
import type {
  CardFormInstance,
  ElementType,
  FieldHandle,
  FormId,
} from '../core/types';
import { initPaymentMethodSession } from '../session/paymentMethodSession';
import type { HostBridge } from './bridge';
import { FormEvent } from './protocol';
import type { FormDescriptor } from './protocol';
import type { HyperswitchConfiguration } from '../session/config';

/* The key says which environment it belongs to, and the payments SDK goes by
   that alone (GlobalVars.checkEnv). Doing the same matters on Android, whose
   configuration names PROD unless told otherwise: a sandbox key would be looked
   up live. INTEG keys look like sandbox keys, so INTEG holds only when named. */
export function withEnvironment(
  hyper: HyperswitchConfiguration
): HyperswitchConfiguration {
  if (hyper.environment === 'INTEG') return hyper;
  return {
    ...hyper,
    environment: hyper.publishableKey.startsWith('pk_snd_') ? 'SANDBOX' : 'PROD',
  };
}

/* Every field view is its own React root, so a field cannot find its form by
   being its child. They meet here instead: one entry per open form, in this
   engine's memory, which no merchant code can reach. */

type FieldHandleGetter = () => FieldHandle | null;

export interface HostedForm {
  readonly formId: FormId;
  /* The form screen's. Everything about the form is reported to it. */
  readonly rootTag: number;
  readonly instance: CardFormInstance | undefined;
  readonly failed: boolean;
  /* Carried across versions of the entry: a field coming or going is not a
     reason to re-render its siblings. */
  readonly fields: Partial<Record<ElementType, FieldHandleGetter>>;
}

const forms = new Map<FormId, HostedForm>();
const listeners = new Set<() => void>();
const notify = () => listeners.forEach((listener) => listener());

export function subscribeForms(listener: () => void): () => void {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

export function getForm(formId: FormId): HostedForm | undefined {
  return forms.get(formId);
}

function replace(formId: FormId, next: Partial<HostedForm>): void {
  const current = forms.get(formId);
  if (!current) return;
  forms.set(formId, { ...current, ...next });
  notify();
}

/* Returns how to close the form, or null when this caller does not own it
   because another screen already opened that id. */
export function openForm(
  descriptor: FormDescriptor,
  rootTag: number,
  bridge: HostBridge
): (() => void) | null {
  const { formId } = descriptor;
  const emit = (event: Parameters<HostBridge['emitForm']>[1], payload: object) =>
    bridge.emitForm(rootTag, event, payload);

  if (forms.has(formId)) {
    emit(FormEvent.Error, { message: `Form "${formId}" is already open.` });
    return null;
  }

  forms.set(formId, {
    formId,
    rootTag,
    instance: undefined,
    failed: false,
    fields: {},
  });
  notify();

  let closed = false;
  let stopWatching: (() => void) | undefined;

  const failWith = (message: string) => {
    replace(formId, { failed: true });
    emit(FormEvent.Error, { message });
  };

  initPaymentMethodSession(withEnvironment(descriptor.hyper), {
    sdkAuthorization: descriptor.sdkAuthorization,
    vaultDetails: descriptor.vaultDetails,
  }).then(
    (session) => {
      if (closed) return;

      let instance: CardFormInstance;
      try {
        instance = session.createCardForm({
          appearance: descriptor.appearance,
          locale: descriptor.locale,
          readyTimeoutMs: descriptor.readyTimeoutMs,
        });
      } catch (error) {
        failWith(messageOf(error));
        return;
      }

      const core = coreOf(instance);
      let announced = false;
      const announce = () => {
        if (announced || !core) return;
        if (core.status === 'ready') {
          announced = true;
          emit(FormEvent.Ready, { elementType: 'cardForm' });
        } else if (core.status === 'error') {
          announced = true;
          failWith('The card form could not be initialised.');
        }
      };
      /* Card details (bin, last four) reach the form from its provider, not
         from a field report, so they are their own reason to tell the host. */
      let details = core?.details;
      stopWatching = core?.subscribe(() => {
        announce();
        if (core && core.details !== details) {
          details = core.details;
          fieldChanged(formId, bridge);
        }
      });
      replace(formId, { instance });
      announce();
    },
    (error: unknown) => {
      if (!closed) failWith(messageOf(error));
    }
  );

  /* Closing is what ends the card data's life: the entry is the only thing
     holding the form, so dropping it releases the collector with it. */
  return () => {
    closed = true;
    stopWatching?.();
    forms.delete(formId);
    notify();
  };
}

export function attachField(
  formId: FormId,
  elementType: ElementType,
  handle: FieldHandleGetter
): () => void {
  const form = forms.get(formId);
  if (!form) return () => {};
  form.fields[elementType] = handle;
  return () => {
    if (form.fields[elementType] === handle) delete form.fields[elementType];
  };
}

/* One form change per field report, as <CardForm> gives in-process callers.
   It comes from the form, so the host hears it once however many field views
   there are. */
export function fieldChanged(formId: FormId, bridge: HostBridge): void {
  const form = forms.get(formId);
  const core = form?.instance ? coreOf(form.instance) : undefined;
  if (!form || !core) return;
  bridge.emitForm(
    form.rootTag,
    FormEvent.Change,
    buildChange(core.fields, core.details)
  );
}
