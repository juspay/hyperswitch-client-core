type envType = INTEG | SANDBOX | PROD

let checkEnv = publishableKey => {
  if publishableKey != "" && publishableKey->String.startsWith("pk_prd_") {
    PROD
  } else {
    SANDBOX
  }
}

let isValidPK = (env: envType, publishableKey) => {
  switch (env, publishableKey) {
  | (_, "") => false
  | (PROD, pk) => pk->String.startsWith("pk_prd_")
  | (SANDBOX, pk) => pk->String.startsWith("pk_snd_")
  | (INTEG, pk) => pk->String.startsWith("pk_snd_")
  }
}

let atob: string => string = %raw(`
  function(str) {
    try {
      // Try global atob first (React Native has this in the global scope)
      if (typeof global !== 'undefined' && typeof global.atob === 'function') {
        return global.atob(str);
      }
      // Fallback: pure JavaScript base64 decode
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
      let output = '';
      let i = 0;
      str = str.replace(/[^A-Za-z0-9+/=]/g, '');
      while (i < str.length) {
        const enc1 = chars.indexOf(str.charAt(i++));
        const enc2 = chars.indexOf(str.charAt(i++));
        const enc3 = chars.indexOf(str.charAt(i++));
        const enc4 = chars.indexOf(str.charAt(i++));
        const chr1 = (enc1 << 2) | (enc2 >> 4);
        const chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
        const chr3 = ((enc3 & 3) << 6) | enc4;
        output += String.fromCharCode(chr1);
        if (enc3 !== 64) output += String.fromCharCode(chr2);
        if (enc4 !== 64) output += String.fromCharCode(chr3);
      }
      console.log('Decoded output length:', output.length);
      return output;
    } catch(e) {
      console.error('Base64 decode error:', e);
      return '';
    }
  }
`)
