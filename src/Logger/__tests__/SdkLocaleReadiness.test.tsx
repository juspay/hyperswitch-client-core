import React from 'react';
import TestRenderer, {act} from 'react-test-renderer';
import {
  make as LocaleProvider,
  localeReadyContext,
} from '../../contexts/LocaleStringDataContext.bs.js';

const mockFetchLocale = jest.fn();
jest.mock('../../hooks/S3ApiHook.bs.js', () => ({
  useFetchDataFromS3WithGZipDecoding: () => mockFetchLocale,
}));
jest.mock('../../../shared-code/sdk-utils/types/LocaleDataType.bs.js', () => ({
  defaultLocale: {},
  localeTypeToString: locale => locale || 'en',
}));

function deferred() {
  let resolve: (value: any) => void;
  const promise = new Promise(done => {
    resolve = done;
  });
  return {promise, resolve: (value: any) => resolve(value)};
}

describe('locale readiness for the SDK funnel', () => {
  beforeEach(() => mockFetchLocale.mockReset());

  it('remains pending until the requested locale finishes', async () => {
    const request = deferred();
    mockFetchLocale.mockReturnValue(request.promise);
    let ready = false;
    function Observe() {
      ready = React.useContext(localeReadyContext);
      return null;
    }
    let tree: TestRenderer.ReactTestRenderer;
    act(() => {
      tree = TestRenderer.create(
        <LocaleProvider locale="fr">
          <Observe />
        </LocaleProvider>,
      );
    });
    expect(ready).toBe(false);
    await act(async () => request.resolve({title: 'localized'}));
    expect(ready).toBe(true);
    act(() => tree.unmount());
  });

  it('waits for the fallback request when the requested locale fails', async () => {
    const requested = deferred();
    const fallback = deferred();
    mockFetchLocale
      .mockReturnValueOnce(requested.promise)
      .mockReturnValueOnce(fallback.promise);
    let ready = false;
    function Observe() {
      ready = React.useContext(localeReadyContext);
      return null;
    }
    let tree: TestRenderer.ReactTestRenderer;
    act(() => {
      tree = TestRenderer.create(
        <LocaleProvider locale="fr">
          <Observe />
        </LocaleProvider>,
      );
    });
    await act(async () => requested.resolve(undefined));
    expect(mockFetchLocale).toHaveBeenCalledTimes(2);
    expect(ready).toBe(false);
    await act(async () => fallback.resolve({title: 'fallback'}));
    expect(ready).toBe(true);
    act(() => tree.unmount());
  });
});
