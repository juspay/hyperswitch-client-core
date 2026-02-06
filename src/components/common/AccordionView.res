open ReactNative
open Style

type accordionSection = {
  key: int,
  title: string,
  isExpanded: bool,
  icon?: string,
  accessible?: bool,
  accessibilityLabel?: string,
  testID?: string,
  componentHoc: AllApiDataModifier.componentHoc,
}

@react.component
let make = (
  ~sections: array<accordionSection>,
  ~expandedSections: array<int>,
  ~onSectionToggle: int => unit,
  ~renderSectionHeader: (~section: accordionSection, ~isExpanded: bool) => React.element,
  ~renderSectionContent: (~section: accordionSection) => React.element,
  ~style: option<ReactNative.Style.t>=?,
  ~sectionStyle: option<ReactNative.Style.t>=?,
  ~headerStyle: option<ReactNative.Style.t>=?,
  ~contentStyle: option<ReactNative.Style.t>=?,
  ~animationDuration: int=300,
  ~allowMultipleExpanded: bool=false,
  ~layout: SdkTypes.layoutType,
) => {
  let isExpanded = (sectionKey: int) => {
    expandedSections->Array.includes(sectionKey)
  }

  let handleSectionPress = (sectionKey: int) => {
    onSectionToggle(sectionKey)
  }

  let {component, borderWidth, borderRadius} = ThemebasedStyle.useThemeBasedStyle()

  <View ?style>
    {sections
    ->Array.map(section => {
      let expanded = isExpanded(section.key)

      let isFirstElement = section.key === 0
      let isLastElement = section.key === sections->Array.length - 1

      <View
        key={section.key->Int.toString}
        style={array([
          layout === SpacedAccordion
            ? s({
                marginBottom: 10.->dp,
                borderWidth,
                borderRadius,
                borderColor: component.borderColor,
              })
            : s({
                borderWidth,
                borderTopWidth: isFirstElement ? borderWidth : borderWidth /. 2.,
                borderBottomWidth: isLastElement ? borderWidth : borderWidth /. 2.,
                borderTopLeftRadius: isFirstElement ? borderRadius : 0.,
                borderTopRightRadius: isFirstElement ? borderRadius : 0.,
                borderBottomLeftRadius: isLastElement ? borderRadius : 0.,
                borderBottomRightRadius: isLastElement ? borderRadius : 0.,
                borderColor: component.borderColor,
              }),
          sectionStyle->Option.getOr(empty),
        ])}
      >
        <CustomPressable
          onPress={_ => handleSectionPress(section.key)}
          style=?headerStyle
          focusable={section.accessible->Option.getOr(true)}
          accessibilityLabel={section.accessibilityLabel->Option.getOr("")}
          testID={section.testID->Option.getOr("")}
        >
          {renderSectionHeader(~section, ~isExpanded=expanded)}
        </CustomPressable>
        <UIUtils.RenderIf condition={expanded}>
          <View
            style={array([
              s({
                paddingBottom: 16.->dp,
                paddingHorizontal: 24.->dp,
              }),
              contentStyle->Option.getOr(empty),
            ])}
          >
            {renderSectionContent(~section)}
          </View>
        </UIUtils.RenderIf>
      </View>
    })
    ->React.array}
  </View>
}
