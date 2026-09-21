import { jest } from '@jest/globals';

const EMPTY_SVG = '<svg xmlns="http://www.w3.org/2000/svg"></svg>';

export interface MockApiReply {
  ok?: boolean;
  status?: number;
  body?: unknown;
}

/* The vault fetches its brand icons as well as calling the API. Icons always
   get a parseable answer, so a test decides only what the API says, and
   nothing here can reach the real network. */
export function mockFetch(api: MockApiReply = {}) {
  const original = globalThis.fetch;
  const mock = jest.fn(async (url: unknown, _init?: unknown) => {
    const isIcon = String(url).endsWith('.svg');
    const body = isIcon ? EMPTY_SVG : JSON.stringify(api.body ?? {});
    return {
      ok: isIcon ? true : (api.ok ?? true),
      status: isIcon ? 200 : (api.status ?? 200),
      headers: { get: () => (isIcon ? 'image/svg+xml' : 'application/json') },
      json: async () => (isIcon ? {} : (api.body ?? {})),
      text: async () => body,
    };
  });
  globalThis.fetch = mock as unknown as typeof fetch;

  return {
    apiCalls: () =>
      mock.mock.calls.filter(([url]) => !String(url).endsWith('.svg')),
    restore: () => {
      globalThis.fetch = original;
    },
  };
}
