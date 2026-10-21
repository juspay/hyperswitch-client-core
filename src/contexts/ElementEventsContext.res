/* Element lifecycle events: need no subscription, and native routes them to onReady/onFocus/onBlur,
   never onChange. `ready` fires once per element; `focus` when its first field gains focus and
   `blur` once none holds it. A field's blur settles briefly, so moving between fields emits nothing. */

type elementEvents = {
  markReady: unit => unit,
  fieldFocused: unit => unit,
  fieldBlurred: unit => unit,
}

// Outside an element (no provider, or a non-element surface) there is nothing to emit.
let noEvents = {markReady: () => (), fieldFocused: () => (), fieldBlurred: () => ()}
let elementEventsContext = React.createContext(noEvents)

module Provider = {
  let make = React.Context.provider(elementEventsContext)
}

let isElement = (sdkState: SdkTypes.sdkState) =>
  switch sdkState {
  | WidgetPaymentSheet | WidgetTabSheet | WidgetButtonSheet | CvcWidget => true
  | _ => false
  }

let blurSettleMs = 50

let emit = (~rootTag, eventName) =>
  HyperModule.emitPaymentEvent(rootTag, eventName, Dict.make()->JSON.Encode.object)

@react.component
let make = (~children) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let rootTag = nativeProp.rootTag
  let emitsLifecycle = isElement(nativeProp.sdkState)

  // Refs, not state: updated inside focus handlers and never rendered.
  let readyEmitted = React.useRef(false)
  let focusedFields = React.useRef(0)
  let pendingBlur = React.useRef(None)

  let cancelPendingBlur = () => {
    pendingBlur.current->Option.forEach(clearTimeout)
    pendingBlur.current = None
  }

  // On unmount: drop a pending blur and zero the count so a later field unmount can't schedule one.
  React.useEffect0(() => Some(
    () => {
      cancelPendingBlur()
      focusedFields.current = 0
    },
  ))

  let events = React.useMemo2(() =>
    emitsLifecycle
      ? {
          markReady: () =>
            if !readyEmitted.current {
              readyEmitted.current = true
              emit(~rootTag, "ready")
            },
          fieldFocused: () => {
            let elementHadFocus = focusedFields.current > 0 || pendingBlur.current->Option.isSome
            cancelPendingBlur()
            focusedFields.current = focusedFields.current + 1
            if !elementHadFocus {
              emit(~rootTag, "focus")
            }
          },
          fieldBlurred: () =>
            if focusedFields.current > 0 {
              focusedFields.current = focusedFields.current - 1
              if focusedFields.current === 0 {
                pendingBlur.current = Some(setTimeout(() => {
                    pendingBlur.current = None
                    if focusedFields.current === 0 {
                      emit(~rootTag, "blur")
                    }
                  }, blurSettleMs))
              }
            },
        }
      : noEvents
  , (emitsLifecycle, rootTag))

  <Provider value=events> children </Provider>
}

let useMarkReady = () => React.useContext(elementEventsContext).markReady

/* The ref makes repeated focus/blur callbacks idempotent, and lets an input unmounted while
   focused (it never gets its blur callback) release its hold on the element. */
let useFieldFocus = () => {
  let {fieldFocused, fieldBlurred} = React.useContext(elementEventsContext)
  let focused = React.useRef(false)
  React.useEffect0(() => Some(() => focused.current ? fieldBlurred() : ()))
  let onFieldFocus = () =>
    if !focused.current {
      focused.current = true
      fieldFocused()
    }
  let onFieldBlur = () =>
    if focused.current {
      focused.current = false
      fieldBlurred()
    }
  (onFieldFocus, onFieldBlur)
}
