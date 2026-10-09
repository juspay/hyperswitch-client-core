open SuperpositionTypes

let resolveMobileConfiguration = (
  ~rawConfigs: option<JSON.t>,
  ~context: sdkPropsContext,
  ~merchantConfigurationJson: JSON.t,
  ~displayPayButton: bool,
): SdkTypes.configurationType => {
  let resolved = SdkPropsConfigurationService.resolveSdkProps(
    ~rawConfigs,
    ~context,
    ~reshape=SdkPropsHelper.buildMobileNestedConfigFromResolved,
  )
  let merged = CommonUtils.mergeDict(resolved, merchantConfigurationJson->Utils.getDictFromJson)
  SdkTypes.parseConfigurationDict(merged, displayPayButton)
}
