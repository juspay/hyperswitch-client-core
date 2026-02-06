open ReactNative
open Style

module SectionHeader = {
  @react.component
  let make = (~section: AccordionView.accordionSection, ~isExpanded: bool) => {
    let {iconColor, primaryColor} = ThemebasedStyle.useThemeBasedStyle()

    <View style={s({flex: 1., alignItems: #center, justifyContent: #center})}>
      <View
        style={array([
          s({
            width: 100.->pct,
            flexDirection: #row,
            minWidth: 115.->dp,
            padding: 20.->dp,
          }),
        ])}
      >
        <CustomRadioButton size=20.5 selected=isExpanded color=primaryColor />
        <Space height=5. />
        {section.title === "loading"
          ? <CustomLoader height="18" width="18" />
          : <Icon
              name=section.title width=18. height=18. fill={isExpanded ? primaryColor : iconColor}
            />}
        <Space height=5. />
        {section.title === "loading"
          ? <CustomLoader height="18" width="40" />
          : <TextWrapper text=section.title textType=CardTextBold />}
      </View>
    </View>
  }
}

module MoreButton = {
  @react.component
  let make = (~handleMoreToggle) => {
    let {component, borderRadius, borderWidth} = ThemebasedStyle.useThemeBasedStyle()

    <View style={s({flex: 1., alignItems: #center, justifyContent: #center, paddingTop: 10.->dp})}>
      <CustomPressable
        onPress={_ => handleMoreToggle()}
        style={array([
          s({
            width: 100.->pct,
            flexDirection: #row,
            alignItems: #center,
            justifyContent: #"flex-start",
            borderWidth,
            borderColor: component.borderColor,
            minWidth: 115.->dp,
            padding: 20.->dp,
            borderRadius,
          }),
        ])}
      >
        <ChevronIcon width=12. height=12. fill="grey" />
        <Space height=5. />
        <TextWrapper text="More" textType=CardTextBold />
      </CustomPressable>
    </View>
  }
}

@react.component
let make = (
  ~hocComponentArr: array<AllApiDataModifier.hoc>=[],
  ~isLoading=true,
  ~setConfirmButtonData,
  ~allowMultipleExpanded: bool=false,
  ~maxVisibleItems: int=2,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (expandedSections, setExpandedSections) = React.useState(_ => [0])
  let (showMore, setShowMore) = React.useState(_ => true)

  let handleSectionToggle = (sectionKey: int) => {
    setExpandedSections(prevExpanded => {
      if allowMultipleExpanded {
        if prevExpanded->Array.includes(sectionKey) {
          prevExpanded->Array.filter(key => key !== sectionKey)
        } else {
          prevExpanded->Array.concat([sectionKey])
        }
      } else {
        [sectionKey]
      }
    })
  }

  let allSections = hocComponentArr->Array.mapWithIndex((hoc, index) => {
    AccordionView.key: index,
    title: hoc.name,
    isExpanded: expandedSections->Array.includes(index),
    componentHoc: hoc.componentHoc,
  })

  let visibleSections = if allSections->Array.length > maxVisibleItems && showMore {
    allSections->Array.slice(~start=0, ~end=maxVisibleItems)
  } else {
    allSections
  }

  let renderSectionHeader = (~section: AccordionView.accordionSection, ~isExpanded: bool) => {
    <SectionHeader section isExpanded />
  }

  let renderSectionContent = (~section: AccordionView.accordionSection) => {
    let isScreenFocus = expandedSections->Array.includes(section.key)
    section.componentHoc(~isScreenFocus, ~setConfirmButtonData)
  }

  <UIUtils.RenderIf condition={hocComponentArr->Array.length > 0}>
    <Space />
    <AccordionView
      sections=visibleSections
      expandedSections
      onSectionToggle=handleSectionToggle
      renderSectionHeader
      renderSectionContent
      style={s({marginHorizontal: -10.->dp})}
      sectionStyle={s({marginHorizontal: 10.->dp})}
      allowMultipleExpanded
      layout=nativeProp.configuration.appearance.layout
    />
    <UIUtils.RenderIf condition={allSections->Array.length > maxVisibleItems && showMore}>
      <MoreButton
        handleMoreToggle={() => {
          setShowMore(_ => false)
        }}
      />
    </UIUtils.RenderIf>
  </UIUtils.RenderIf>
}
