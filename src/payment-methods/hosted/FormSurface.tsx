import { useEffect, useMemo, useState, useSyncExternalStore } from 'react';

import { coreOf } from '../core/formRegistry';
import { hostBridge } from './bridge';
import type { HostBridge } from './bridge';
import { descriptorKey, readFormDescriptor } from './descriptor';
import { getForm, openForm, subscribeForms } from './forms';
import { FormEvent } from './protocol';

export interface FormSurfaceProps {
  props?: unknown;
  rootTag: number;
  bridge?: HostBridge;
}

const NO_STORE = () => () => {};
const NO_SNAPSHOT = () => undefined;

/* Draws nothing. The form lives exactly as long as this screen does, which
   gives the host one plain way to end it: stop the screen. */
export function FormSurface({
  props,
  rootTag,
  bridge = hostBridge,
}: FormSurfaceProps) {
  const key = descriptorKey(props);
  // eslint-disable-next-line react-hooks/exhaustive-deps -- key is props by value
  const parsed = useMemo(() => readFormDescriptor(props), [key]);

  const [owned, setOwned] = useState(false);
  useEffect(() => {
    if (!parsed.ok) {
      bridge.emitForm(rootTag, FormEvent.Error, { message: parsed.message });
      return undefined;
    }
    const close = openForm(parsed.descriptor, rootTag, bridge);
    if (!close) return undefined;

    setOwned(true);
    return () => {
      setOwned(false);
      close();
    };
  }, [parsed, rootTag, bridge]);

  const formId = parsed.ok ? parsed.descriptor.formId : undefined;
  const form = useSyncExternalStore(subscribeForms, () =>
    owned && formId !== undefined ? getForm(formId) : undefined
  );
  const core = form?.instance ? coreOf(form.instance) : undefined;
  const collector = useSyncExternalStore(
    core ? core.subscribe : NO_STORE,
    core ? () => core.collector : NO_SNAPSHOT
  );

  /* Some vaults only work while something of theirs is mounted (the Hyperswitch
     vault's tokenizer is one). Only the screen that owns the form mounts it, so
     a refused duplicate cannot start a second one. */
  const DetachedHost = core?.adapter.DetachedHost;
  if (!DetachedHost || collector === undefined) return null;
  return <DetachedHost collector={collector} />;
}
