// The `session_id` of every row. Native may pass its own `sdkParams.sessionId`; when it does not
// (Android sends "", iOS sends nothing), client-core generates one, once, and every row uses it from
// the first row to the last, for as long as this JS runtime lives.

// UUID v7 (RFC 9562): a 48-bit Unix millisecond timestamp, then random bits, so ids sort by when
// they were created. React Native has no `crypto.getRandomValues` unless the app adds a polyfill,
// so Math.random is the fallback; that is enough for an id that only groups log rows.
let uuidV7: unit => string = %raw(`
  function () {
    var bytes = new Uint8Array(16);
    var filled = false;
    try {
      var c = typeof globalThis !== "undefined" ? globalThis.crypto : undefined;
      if (c && typeof c.getRandomValues === "function") {
        c.getRandomValues(bytes);
        filled = true;
      }
    } catch (_) {}
    if (!filled) {
      for (var i = 0; i < 16; i++) bytes[i] = Math.floor(Math.random() * 256);
    }
    var ms = Date.now();
    for (var j = 0; j < 6; j++) bytes[j] = Math.floor(ms / Math.pow(2, 8 * (5 - j))) % 256;
    bytes[6] = 0x70 | (bytes[6] & 0x0f);
    bytes[8] = 0x80 | (bytes[8] & 0x3f);
    var hex = "";
    for (var k = 0; k < 16; k++) hex += (bytes[k] + 0x100).toString(16).slice(1);
    return hex.slice(0, 8) + "-" + hex.slice(8, 12) + "-" + hex.slice(12, 16) + "-" +
      hex.slice(16, 20) + "-" + hex.slice(20);
  }
`)

let generated: ref<option<string>> = ref(None)

// Generated on first use and never replaced.
let generatedId = () =>
  switch generated.contents {
  | Some(id) => id
  | None =>
    let id = uuidV7()
    generated := Some(id)
    id
  }

// The session id for a root: the native one when native sends it, otherwise the generated one.
let resolve = nativeSessionId =>
  switch nativeSessionId->String.trim {
  | "" => generatedId()
  | sessionId => sessionId
  }
