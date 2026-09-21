import type { FormId } from '../core/types';
import NativeHyperPaymentMethods from '../../specs/NativeHyperPaymentMethods';
import type { CommandEvent } from '../../specs/NativeHyperPaymentMethods';
import type { FieldEventName, FormEventName } from './protocol';
import { toWire } from './wire';

/* A command as the host sent it. commands.ts decides whether it is one this
   bundle understands, so that an unknown one still gets an answer. */
export interface RawCommand {
  rootTag: number;
  formId: FormId;
  commandId: string;
  name: string;
  elementType?: string;
  providerData?: unknown;
}

export interface HostBridge {
  emitField(rootTag: number, event: FieldEventName, payload: object): void;
  emitForm(rootTag: number, event: FormEventName, payload: object): void;
  onCommand(listener: (command: RawCommand) => void): () => void;
}

function readProviderData(raw: string | undefined): unknown {
  if (raw === undefined || raw === '') return undefined;
  try {
    return JSON.parse(raw) as unknown;
  } catch {
    return undefined;
  }
}

const noop = () => {};

export const hostBridge: HostBridge = {
  emitField(rootTag, event, payload) {
    NativeHyperPaymentMethods?.emitFieldEvent(
      rootTag,
      event,
      toWire(event, payload)
    );
  },
  emitForm(rootTag, event, payload) {
    NativeHyperPaymentMethods?.emitFormEvent(
      rootTag,
      event,
      toWire(event, payload)
    );
  },
  onCommand(listener) {
    const attach = NativeHyperPaymentMethods?.onCommand;
    if (!NativeHyperPaymentMethods || !attach) return noop;

    const subscription = attach.call(
      NativeHyperPaymentMethods,
      (event: CommandEvent) => {
        if (typeof event.rootTag !== 'number' || !event.commandId) return;
        listener({
          rootTag: event.rootTag,
          formId: event.formId,
          commandId: event.commandId,
          name: event.name,
          elementType: event.elementType,
          providerData: readProviderData(event.providerData),
        });
      }
    );
    return () => subscription.remove();
  },
};
