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
        ])}>
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
    let {
      iconColor,
      component,
      borderRadius,
      borderWidth,
    } = ThemebasedStyle.useThemeBasedStyle()

    <View
      style={s({flex: 1., alignItems: #center, justifyContent: #center, paddingVertical: 10.->dp})}>
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
        ])}>
        <svg
          ariaHidden=true
          className="SVGInline-svg SVGInline--cleaned-svg SVG-svg Icon-svg Icon--chevronDown-svg Icon-color-svg Icon-color--blue-svg"
          height="12"
          width="12"
          viewBox="0 0 16 16"
          fill=iconColor
          xmlns="http://www.w3.org/2000/svg">
          <path
            fillRule="evenodd"
            clipRule="evenodd"
            d="M.381 4.381a.875.875 0 0 1 1.238 0L8 10.763l6.381-6.382A.875.875 0 1 1 15.62 5.62l-7 7a.875.875 0 0 1-1.238 0l-7-7a.875.875 0 0 1 0-1.238Z"
          />
        </svg>
        <Space height=5. />
        <TextWrapper text="More" textType=CardTextBold />
      </CustomPressable>
    </View>
  }
}

@react.component
let make = (
  ~hocComponentArr: array<PMListModifier.hoc>=[],
  ~loading=true,
  ~setConfirmButtonDataRef,
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

  let data = React.useMemo1(() => {
    if loading {
      hocComponentArr
      ->Array.pushMany([
        {
          name: "loading",
          componentHoc: (~isScreenFocus as _, ~setConfirmButtonDataRef as _) => <>
            <Space height=20. />
            <CustomLoader height="33" />
            <Space height=5. />
            <CustomLoader height="33" />
          </>,
        },
        {
          name: "loading",
          componentHoc: (~isScreenFocus as _, ~setConfirmButtonDataRef as _) => React.null,
        },
      ])
      ->ignore
      hocComponentArr
    } else {
      hocComponentArr
    }
  }, [hocComponentArr])

  let allSections = data->Array.mapWithIndex((hoc, index) => {
    let section: AccordionView.accordionSection = {
      key: index,
      title: hoc.name,
      isExpanded: expandedSections->Array.includes(index),
      componentHoc: hoc.componentHoc,
    }
    section
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
    section.componentHoc(~isScreenFocus, ~setConfirmButtonDataRef)
  }

  <UIUtils.RenderIf condition={data->Array.length > 0}>
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
