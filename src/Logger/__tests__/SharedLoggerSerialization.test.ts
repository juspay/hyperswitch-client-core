import {serializeRow} from '../../../shared-code/sdk-utils/logging/SharedLoggerSerialization.bs.js';

describe('wire-only empty string omission', () => {
  it('omits empty object properties at every level, including the encoded envelope', () => {
    const envelope = {schema_version: 8, href: '', occurrence: 1, details: {
      empty: '', nested: {empty: '', keep: 'x'}, zero: 0, no: false, nil: null,
      whitespace: ' ', array: ['', 0, false, null, {empty: '', keep: 'x'}],
      encodedDetail: '{"empty":""}',
    }};
    const row: any = {event_name: 'state.test', session_id: '', payment_id: '',
      browser_name: '', component: 'MOBILE', value: JSON.stringify(envelope)};
    const original = JSON.stringify(row);
    const wire = JSON.parse(serializeRow(row));
    expect(wire).not.toHaveProperty('session_id');
    expect(wire).not.toHaveProperty('payment_id');
    expect(wire).not.toHaveProperty('browser_name');
    expect(JSON.parse(wire.value)).toEqual({schema_version: 8, occurrence: 1, details: {
      nested: {keep: 'x'}, zero: 0, no: false, nil: null, whitespace: ' ',
      array: ['', 0, false, null, {keep: 'x'}], encodedDetail: '{"empty":""}',
    }});
    expect(typeof wire.value).toBe('string');
    expect(JSON.stringify(row)).toBe(original);
    expect(Buffer.byteLength(JSON.stringify(wire))).toBeLessThan(Buffer.byteLength(original));
  });

  it('preserves nonempty strings, nulls and arrays outside the envelope too', () => {
    const row: any = {event_name: 'state.test', value: '', space: ' ', zero: 0,
      no: false, nil: null, objects: [{blank: '', ok: 'x'}], array: ['', '', null]};
    expect(JSON.parse(serializeRow(row))).toEqual({event_name: 'state.test', space: ' ',
      zero: 0, no: false, nil: null, objects: [{ok: 'x'}], array: ['', '', null]});
  });

  it('leaves malformed envelope strings intact', () => {
    const row: any = {event_name: 'state.test', value: 'not-json', session_id: ''};
    expect(JSON.parse(serializeRow(row))).toEqual({event_name: 'state.test', value: 'not-json'});
  });
});
