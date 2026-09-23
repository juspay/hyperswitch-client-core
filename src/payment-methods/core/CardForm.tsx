import {
  forwardRef,
  useCallback,
  useContext,
  useEffect,
  useImperativeHandle,
  useMemo,
  useRef,
  useState,
} from 'react';
import type { ReactNode } from 'react';

import { FormContext } from './FormContext';
import type { FormContextValue } from './FormContext';
import { createFormSession } from './formSession';
import type { CreateFormSessionOptions } from './formSession';
import { registerForm } from './formRegistry';
import {
  isAdapterNotLoadedError,
  loadAdapter,
  resolveAdapter,
} from '../providers/registry';
import { SessionContext } from '../session/SessionContext';
import type { ProviderAdapter } from './ProviderAdapter';
import { errorResult, tokenizedCardOf } from './results';
import {
  checkConfiguration,
  mountedField,
  savedCardOf,
  withSavedCard,
} from './savedCard';
import type { MountedFields, UnresolvedVault } from './savedCard';
import type {
  Appearance,
  CardDetails,
  CardFormChange,
  CardFormEvent,
  CardFormHandle,
  ElementType,
  FieldChange,
  FieldOptions,
  FormId,
  FormStatus,
  TokenizeResult,
  VaultDetails,
  VaultType,
} from './types';

function unavailableAdapter(vaultType: VaultType): ProviderAdapter {
  return {
    vaultType,
    validateVaultData: (raw) => raw,
    Host: () => null,
    Field: () => null,
    tokenize: async () =>
      errorResult(
        vaultType,
        'tokenization_failed',
        `No provider is available for vault type "${vaultType}".`
      ),
  };
}

interface ResolvedAdapter {
  adapter: ProviderAdapter | null;
  resolveError: unknown;
}

type SyncResolution =
  | { pending: false; result: ResolvedAdapter }
  /* The adapter's SDK is a chunk of its own that is not loaded yet. */
  | { pending: true };

type LoadOutcome =
  | { vaultType: VaultType; adapter: ProviderAdapter }
  | { vaultType: VaultType; error: unknown };

/* The adapter for a vault type: at once when it is injected or already loaded,
   otherwise once its chunk lands. Meanwhile the adapter is null, and the form
   stays initializing. A provider that cannot be resolved at all stands in as
   an adapter that refuses to tokenize, with the reason in resolveError. */
function useAdapter(vaultType: VaultType | undefined): ResolvedAdapter {
  const sync = useMemo<SyncResolution>(() => {
    if (!vaultType) {
      return { pending: false, result: { adapter: null, resolveError: undefined } };
    }
    try {
      return {
        pending: false,
        result: { adapter: resolveAdapter(vaultType), resolveError: undefined },
      };
    } catch (error) {
      if (isAdapterNotLoadedError(error)) return { pending: true };
      return {
        pending: false,
        result: { adapter: unavailableAdapter(vaultType), resolveError: error },
      };
    }
  }, [vaultType]);

  const [loaded, setLoaded] = useState<LoadOutcome | undefined>(undefined);

  useEffect(() => {
    if (!sync.pending || !vaultType) return undefined;
    let alive = true;
    loadAdapter(vaultType).then(
      (adapter) => {
        if (alive) setLoaded({ vaultType, adapter });
      },
      (error: unknown) => {
        if (alive) setLoaded({ vaultType, error });
      }
    );
    return () => {
      alive = false;
    };
  }, [sync, vaultType]);

  return useMemo<ResolvedAdapter>(() => {
    if (!sync.pending) return sync.result;
    if (!loaded || loaded.vaultType !== vaultType) {
      return { adapter: null, resolveError: undefined };
    }
    return 'adapter' in loaded
      ? { adapter: loaded.adapter, resolveError: undefined }
      : { adapter: unavailableAdapter(loaded.vaultType), resolveError: loaded.error };
  }, [sync, loaded, vaultType]);
}

export interface CardFormProps {
  vaultDetails?: VaultDetails;

  appearance?: Appearance;

  unstyled?: boolean;

  id?: FormId;

  onReady?: (event: CardFormEvent) => void;

  onChange?: (event: CardFormChange) => void;

  onError?: (error: unknown) => void;

  readyTimeoutMs?: number;
  children?: ReactNode;
}

type ValidatedData =
  { ok: true; value: unknown } | { ok: false; error: unknown };

const twoDigit = (value: string) => (value.length === 1 ? `0${value}` : value);

export function buildChange(
  fields: Partial<Record<ElementType, FieldChange>>,
  details: Partial<CardDetails>
): CardFormChange {
  const number = fields.cardNumber;
  const expiry = fields.cardExpiry;
  const cvc = fields.cardCvc;
  const mounted = Object.values(fields).filter(
    (field): field is FieldChange => field !== undefined
  );
  const expiryMonth = details.expiryMonth ?? null;
  const expiryYear = details.expiryYear ?? null;
  const formattedExpiry =
    details.formattedExpiry ??
    (expiryMonth && expiryYear
      ? `${twoDigit(expiryMonth)} / ${expiryYear.slice(-2)}`
      : null);
  return {
    elementType: 'cardForm',
    eventName: 'cardDetailsChange',
    payload: {
      bin: details.bin ?? null,
      extendedBin: details.extendedBin ?? null,
      last4: details.last4 ?? null,
      brand: details.brand ?? number?.brand ?? null,
      expiryMonth,
      expiryYear,
      formattedExpiry,
      isCardNumberComplete: number?.complete ?? false,
      isCvcComplete: cvc?.complete ?? false,
      isExpiryComplete: expiry?.complete ?? false,
      isCardNumberValid: number?.valid ?? false,
      isExpiryValid: expiry?.valid ?? false,
    },
    complete: mounted.length > 0 && mounted.every((field) => field.complete),
    valid: mounted.length > 0 && mounted.every((field) => field.valid),
    fields: { ...fields },
  };
}

export const CardForm = forwardRef<CardFormHandle, CardFormProps>(
  function CardFormImpl(
    {
      vaultDetails,
      appearance,
      unstyled,
      id,
      onReady,
      onChange,
      onError,
      readyTimeoutMs,
      children,
    },
    ref
  ) {
    const session = useContext(SessionContext);

    const details = vaultDetails ?? session?.vaultDetails;
    const vaultType = details?.vaultType;

    const { adapter, resolveError } = useAdapter(vaultType);

    const validated = useMemo<ValidatedData>(() => {
      if (resolveError !== undefined) return { ok: false, error: resolveError };
      if (!adapter || !details) return { ok: false, error: undefined };
      try {
        return {
          ok: true,
          value: adapter.validateVaultData(details.vaultData),
        };
      } catch (error) {
        return { ok: false, error };
      }
    }, [adapter, details, resolveError]);

    const sessionOptions = useMemo<CreateFormSessionOptions>(
      () => ({
        ...(readyTimeoutMs !== undefined ? { readyTimeoutMs } : {}),
        ...(vaultType ? { vaultType } : {}),
      }),
      [readyTimeoutMs, vaultType]
    );

    /* Keyed on the vault, not the adapter: a tokenize() that is waiting while
       the adapter's chunk loads must be answered by this same session. */
    const formSession = useMemo(
      () => createFormSession(null, sessionOptions),
      [sessionOptions]
    );
    if (adapter) formSession.attachAdapter(adapter);

    const [collector, setCollector] = useState<unknown>(undefined);
    const [status, setStatus] = useState<FormStatus>('initializing');

    const onChangeRef = useRef(onChange);
    onChangeRef.current = onChange;
    const onReadyRef = useRef(onReady);
    onReadyRef.current = onReady;

    const fieldsRef = useRef<Partial<Record<ElementType, FieldChange>>>({});
    const mountedRef = useRef<MountedFields>({});
    const detailsRef = useRef<Partial<CardDetails>>({});

    const unresolvedRef = useRef<UnresolvedVault>({ pending: false });
    unresolvedRef.current = {
      pending: session?.loading ?? false,
      reason: session?.error
        ? `Could not resolve the vault configuration: ${session.error.message}`
        : undefined,
    };

    const emitChange = useCallback(() => {
      const listener = onChangeRef.current;
      if (listener)
        listener(buildChange(fieldsRef.current, detailsRef.current));
    }, []);

    // const aliveRef = useRef(true);
    // useEffect(() => {
    //   aliveRef.current = true;
    //   return () => {
    //     aliveRef.current = false;
    //   };
    // }, []);
    // const flushScheduledRef = useRef(false);
    // const lastEmittedRef = useRef('');
    // const sessionKey = details ? JSON.stringify(details) : '';
    // useEffect(() => {
    //   lastEmittedRef.current = '';
    // }, [sessionKey]);
    // const flushChange = useCallback(() => {
    //   flushScheduledRef.current = false;
    //   if (!aliveRef.current) return;
    //   const listener = onChangeRef.current;
    //   if (!listener) return;
    //   const change = buildChange(fieldsRef.current, detailsRef.current);
    //   const serialized = JSON.stringify(change);
    //   if (serialized === lastEmittedRef.current) return;
    //   lastEmittedRef.current = serialized;
    //   try {
    //     listener(change);
    //   } catch (error) {
    //     setTimeout(() => {
    //   throw error;
    //     }, 0);
    //   }
    // }, []);
    // const emitChange = useCallback(() => {
    //   if (flushScheduledRef.current) return;
    //   flushScheduledRef.current = true;
    //   Promise.resolve().then(flushChange);
    // }, [flushChange]);

    const reportChange = useCallback(
      (change: FieldChange) => {
        fieldsRef.current[change.elementType] = change;
        emitChange();
      },
      [emitChange]
    );

    const registerField = useCallback(
      (elementType: ElementType, options?: FieldOptions) => {
        mountedRef.current[elementType] = mountedField(elementType, options);
      },
      []
    );

    const forgetField = useCallback((elementType: ElementType) => {
      delete fieldsRef.current[elementType];
      delete mountedRef.current[elementType];
    }, []);

    const handleCardDetails = useCallback(
      (next: Partial<CardDetails>) => {
        detailsRef.current = { ...detailsRef.current, ...next };
        emitChange();
      },
      [emitChange]
    );

    const handleReady = useCallback(
      (next: unknown) => {
        formSession.attachCollector(next);
        setCollector(next);
        setStatus('ready');
        onReadyRef.current?.({ elementType: 'cardForm' });
      },
      [formSession]
    );

    const handleError = useCallback(
      (error: unknown) => {
        formSession.fail(error);
        setStatus('error');
        onError?.(error);
      },
      [formSession, onError]
    );

    const tokenize = useCallback(
      async (providerData?: unknown): Promise<TokenizeResult> => {
        const mounted = mountedRef.current;

        const problem = checkConfiguration(
          vaultType,
          mounted,
          unresolvedRef.current
        );
        if (problem) return problem;

        const result = await formSession.tokenize(providerData);
        setStatus(formSession.status);
        if (result.status !== 'success') return result;

        const card = tokenizedCardOf(detailsRef.current);
        return withSavedCard(
          card ? { ...result, card } : result,
          savedCardOf(mounted)
        );
      },
      [formSession, vaultType]
    );

    useImperativeHandle(
      ref,
      () => ({
        tokenize,
        get status() {
          return status;
        },
      }),
      [tokenize, status]
    );

    useEffect(() => {
      if (!id) return;
      return registerForm(id, tokenize);
    }, [id, tokenize]);

    useEffect(() => {
      if (!validated.ok && validated.error !== undefined) {
        handleError(validated.error);
      }
    }, [validated, handleError]);

    const appearances = useMemo<readonly Appearance[]>(() => {
      const layers: Appearance[] = [];
      if (session?.appearance) layers.push(session.appearance);
      if (appearance) layers.push(appearance);
      return layers;
    }, [session?.appearance, appearance]);

    const value = useMemo<FormContextValue>(
      () => ({
        vaultType,
        adapter,
        collector,
        status,
        appearances,
        unstyled,
        tokenize,
        reportChange,
        registerField,
        forgetField,
      }),
      [
        vaultType,
        adapter,
        collector,
        status,
        appearances,
        unstyled,
        tokenize,
        reportChange,
        registerField,
        forgetField,
      ]
    );

    const Host = adapter?.Host;

    return (
      <FormContext.Provider value={value}>
        {validated.ok && Host ? (
          <Host
            vaultData={validated.value}
            onReady={handleReady}
            onError={handleError}
            onCardDetails={handleCardDetails}
          >
            {children}
          </Host>
        ) : (
          children
        )}
      </FormContext.Provider>
    );
  }
);
