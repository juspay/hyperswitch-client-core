let useGetLocalObj = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  switch nativeProp.configuration.appearance.locale->Option.getOr(En) {
  | En => EnglishLocale.localeStrings
  | He  => HebrewLocale.localeStrings
  | Fr  => FrenchLocale.localeStrings
  | En_GB => EnglishGBLocale.localeStrings
  | Ar  => ArabicLocale.localeStrings
  | Ja => JapaneseLocale.localeStrings
  | De  => DeutschLocale.localeStrings
  | Fr_BE => FrenchBelgiumLocale.localeStrings
  | Es  => EstonianLocale.localeStrings
  | Ca   => CatalanLocale.localeStrings
  | Pt  => PortugueseLocale.localeStrings
  | It  => ItalianLocale.localeStrings
  | Pl => PolishLocale.localeStrings
  | Nl => DutchLocale.localeStrings
  | NI_BE => DutchBelgiumLocale.localeStrings
  | Sv => SwedishLocale.localeStrings
  | Ru => RussianLocale.localeStrings
  | Lt => LithuanianLocale.localeStrings
  | Cs => CzechLocale.localeStrings
  | Sk => SlovakLocale.localeStrings
  | Ls => IcelandicLocale.localeStrings
  | Cy => WelshLocale.localeStrings
  | El => GreekLocale.localeStrings
  | Et => EstonianLocale.localeStrings
  | Fi => FinnishLocale.localeStrings
  | Nb => NorwegianLocale.localeStrings
  | Bs => BosnianLocale.localeStrings
  | Da => DanishLocale.localeStrings
  | Ms => MalayLocale.localeStrings
  | Tr_CY => TurkishLocale.localeStrings
  }
}
