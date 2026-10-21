type stage = Client | Config | Sessions
type progress = {client: option<bool>, config: option<bool>, sessions: option<bool>}

// One tracker per startup generation. Optional wallet-session failure is degraded
// rendering; invalid payment methods/configuration never count as fully rendered.
let make = (~onReady: bool => unit) => {
  let progress = ref({client: None, config: None, sessions: None})
  let reported = ref(false)
  (stage, success) => {
    progress :=
      switch stage {
      | Client => {...progress.contents, client: Some(success)}
      | Config => {...progress.contents, config: Some(success)}
      | Sessions => {...progress.contents, sessions: Some(success)}
      }
    switch progress.contents {
    | {client: Some(true), config: Some(true), sessions: Some(available)} if !reported.contents =>
      reported := true
      onReady(!available)
    | _ => ()
    }
  }
}
