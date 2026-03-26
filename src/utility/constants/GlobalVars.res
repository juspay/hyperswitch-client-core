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
