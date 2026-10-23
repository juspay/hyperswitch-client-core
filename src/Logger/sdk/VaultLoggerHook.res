// Log field names and completion only. Never retain card data or provider payloads.
let useFieldLogger = (~elementType: string) => {
  let mountedAt = React.useRef(None)
  let rendered = React.useRef(false)

  let ensureMounted = () =>
    if mountedAt.current->Option.isNone {
      mountedAt.current = Some(Date.now())
      SdkLogger.logState(~event=CardFieldMounted({scope: VaultForm, field: elementType}))
    }

  React.useEffect1(() => {
    ensureMounted()
    Some(
      () => {
        SdkLogger.logState(~event=CardFieldUnmounted({scope: VaultForm, field: elementType}))
        mountedAt.current = None
        rendered.current = false
      },
    )
  }, [elementType])

  () => {
    ensureMounted()
    if !rendered.current {
      rendered.current = true
      SdkLogger.logState(
        ~event=CardFieldRendered({scope: VaultForm, field: elementType}),
        ~durationMs=?mountedAt.current->Option.map(start => Date.now() -. start),
      )
    }
  }
}

let useFormLogger = (~formId: string, ~savedMethod=false) => {
  let completed = React.useRef(false)

  React.useEffect1(() => {
    completed.current = false
    SdkLogger.logState(~event=CardFormCreated({scope: VaultForm}))
    Some(() => SdkLogger.logState(~event=CardFormDestroyed({scope: VaultForm})))
  }, [formId])

  (event: VaultBindings.cardFormChange) =>
    if event.complete && event.valid && !completed.current {
      completed.current = true
      let fields =
        ["cardNumber", "cardExpiry", "cardCvc", "cardholderName"]->Array.filter(field =>
          event.fields->Dict.get(field)->Option.mapOr(false, field => field.complete && field.valid)
        )
      SdkLogger.logState(~event=CardFormCompleted({scope: VaultForm, fields}))
      SdkFunnelLogger.log(
        ~event=PaymentDetailsFilled({savedMethod: savedMethod}),
        ~once=true,
        ~paymentMethod=Card,
      )
    }
}
