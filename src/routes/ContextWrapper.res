// Provider stack shared by both React roots: the payments root (`App`, mounted
// as `hyperSwitch`) and the PMM root (`PMMRoot`, mounted as `hyperPMM`) sit on
// top of the same context tree.
@react.component
let make = (~props, ~rootTag, ~children) => {
  let nativeProp = SdkTypes.nativeJsonToRecord(props, rootTag)
  <NativePropContext nativeProp>
    <LoggerContext>
      <SafeAreaContext>
        <ThemeContext appearance=nativeProp.configuration.appearance>
          <LocaleStringDataContext locale=nativeProp.configuration.locale>
            <CountryStateDataContext>
              <LoadingContext>
                <EntranceGate>
                  <BannerContext> children </BannerContext>
                </EntranceGate>
              </LoadingContext>
            </CountryStateDataContext>
          </LocaleStringDataContext>
        </ThemeContext>
      </SafeAreaContext>
    </LoggerContext>
  </NativePropContext>
}
