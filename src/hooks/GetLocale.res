let useGetLocalObj = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  LocaleString.localeStrings
  ->Array.get(
    switch nativeProp.configuration.appearance.locale->Option.getOr(En) {
    | En => 0
    | He => 1
    | Fr => 2
    | En_GB => 3
    | Ar => 4
    | Ja => 5
    | De => 6
    | Fr_BE => 7
    | Es => 8
    | Ca => 9
    | Pt => 10
    | It => 11
    | Pl => 12
    | Nl => 13
    | NI_BE => 14
    | Sv => 15
    | Ru => 16
    | Lt => 17
    | Cs => 18
    | Sk => 19
    | Ls => 20
    | Cy => 21
    | El => 22
    | Et => 23
    | Fi => 24
    | Nb => 25
    | Bs => 26
    | Da => 27
    | Ms => 28
    | Tr_CY => 29
    },
  )
  ->Option.getOr(LocaleString.defaultLocale)
}
