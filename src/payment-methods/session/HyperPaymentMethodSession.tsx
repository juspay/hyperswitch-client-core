import { useEffect, useMemo, useRef, useState } from 'react';
import type { ReactNode } from 'react';

import { SessionContext } from './SessionContext';
import type { PaymentMethodsSession } from './SessionContext';
import type { HyperswitchConfiguration } from './config';
import { fetchVaultDetails } from './fetchVaultDetails';
import type { Appearance, VaultDetails } from '../core/types';

interface CommonOptions {
  appearance?: Appearance;

  locale?: string;
}

export type HyperPaymentMethodSessionOptions =
  | (CommonOptions & { vaultDetails: VaultDetails; sdkAuthorization?: string })
  | (CommonOptions & { sdkAuthorization: string; vaultDetails?: VaultDetails });

export interface HyperPaymentMethodSessionProps {
  hyper: HyperswitchConfiguration | Promise<HyperswitchConfiguration>;

  options:
    | HyperPaymentMethodSessionOptions
    | Promise<HyperPaymentMethodSessionOptions>;

  onError?: (error: Error) => void;

  children: ReactNode;
}

function isPromiseLike<T>(value: T | Promise<T>): value is Promise<T> {
  return (
    typeof value === 'object' &&
    value !== null &&
    typeof (value as Promise<T>).then === 'function'
  );
}

const toError = (reason: unknown): Error =>
  reason instanceof Error ? reason : new Error(String(reason));

export function HyperPaymentMethodSession({
  hyper,
  options,
  onError,
  children,
}: HyperPaymentMethodSessionProps) {
  const onErrorRef = useRef(onError);
  onErrorRef.current = onError;

  const immediateOptions = isPromiseLike(options) ? null : options;
  const [awaitedOptions, setAwaitedOptions] =
    useState<HyperPaymentMethodSessionOptions | null>(null);
  const [optionsError, setOptionsError] = useState<Error | null>(null);

  useEffect(() => {
    if (!isPromiseLike(options)) {
      setOptionsError(null);
      return;
    }
    let cancelled = false;
    options.then(
      (value) => {
        if (cancelled) return;
        setAwaitedOptions(value);
        setOptionsError(null);
      },
      (reason: unknown) => {
        if (cancelled) return;
        const failure = toError(reason);
        setAwaitedOptions(null);
        setOptionsError(failure);
        onErrorRef.current?.(failure);
      }
    );
    return () => {
      cancelled = true;
    };
  }, [options]);

  const resolvedOptions = immediateOptions ?? awaitedOptions;
  const appearance = resolvedOptions?.appearance;
  const locale = resolvedOptions?.locale;
  const providedVaultDetails = resolvedOptions?.vaultDetails;
  const sdkAuthorization = resolvedOptions?.sdkAuthorization;

  const [resolvedHyper, setResolvedHyper] =
    useState<HyperswitchConfiguration | null>(null);
  const [hyperError, setHyperError] = useState<Error | null>(null);

  const [fetchedVaultDetails, setFetchedVaultDetails] =
    useState<VaultDetails | null>(null);
  // const [fetchedExpiry, setFetchedExpiry] = useState<string | null>(null);
  const [vaultLoading, setVaultLoading] = useState(false);
  const [vaultError, setVaultError] = useState<Error | null>(null);

  useEffect(() => {
    let cancelled = false;

    Promise.resolve(hyper).then(
      (instance) => {
        if (cancelled) return;
        setResolvedHyper(instance);
        setHyperError(null);
      },
      (reason: unknown) => {
        if (cancelled) return;
        const failure = toError(reason);
        setResolvedHyper(null);
        setHyperError(failure);
        onErrorRef.current?.(failure);
      }
    );

    return () => {
      cancelled = true;
    };
  }, [hyper]);

  useEffect(() => {
    if (providedVaultDetails || !sdkAuthorization) {
      setFetchedVaultDetails(null);
      // setFetchedExpiry(null);
      setVaultLoading(false);
      setVaultError(null);
      return;
    }

    // setFetchedVaultDetails(null);
    // setFetchedExpiry(null);
    setVaultLoading(true);
    setVaultError(null);
    if (!resolvedHyper) return;

    let cancelled = false;
    const controller = new AbortController();

    fetchVaultDetails({
      sdkAuthorization,
      environment: resolvedHyper.environment,
      customEndpoints: resolvedHyper.customEndpoints,
      signal: controller.signal,
    }).then((result) => {
      if (cancelled) return;
      if (result.ok) {
        setFetchedVaultDetails(result.vaultDetails);
        // setFetchedExpiry(result.expiresAt ?? null);
        setVaultLoading(false);
        return;
      }
      const failure = new Error(result.message);
      setFetchedVaultDetails(null);
      // setFetchedExpiry(null);
      setVaultError(failure);
      setVaultLoading(false);
      onErrorRef.current?.(failure);
    });

    return () => {
      cancelled = true;
      controller.abort();
    };
  }, [providedVaultDetails, sdkAuthorization, resolvedHyper]);

  const optionsPending = resolvedOptions === null && optionsError === null;

  const value = useMemo<PaymentMethodsSession>(
    () => ({
      hyper: resolvedHyper,
      sdkAuthorization: sdkAuthorization ?? null,
      vaultDetails: providedVaultDetails ?? fetchedVaultDetails,
      appearance: appearance ?? null,
      locale: locale ?? null,
      // expiresAt: providedVaultDetails ? null : fetchedExpiry,
      loading:
        (!resolvedHyper && !hyperError) || vaultLoading || optionsPending,
      error: hyperError ?? optionsError ?? vaultError,
    }),
    [
      resolvedHyper,
      sdkAuthorization,
      providedVaultDetails,
      fetchedVaultDetails,
      appearance,
      locale,
      hyperError,
      optionsError,
      optionsPending,
      vaultLoading,
      vaultError,
    ]
  );

  return (
    <SessionContext.Provider value={value}>{children}</SessionContext.Provider>
  );
}
