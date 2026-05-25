open Utils

type visibility = Hidden | Shown
type cardBrandVisibility = Hidden | Animated | Standard | HideDefault 
type layoutType = Tabs | Accordion
type paymentMethodsArrangement = ArrangementDefault | ArrangementGrid
type groupingBehavior = {
  displayInSeparateScreen: bool,
  displayInSeparateSection: bool,
  groupByPaymentMethods: bool,
}

type savedMethodCustomization = {
  hideCardExpiry: bool,
  hideCVCError: bool,
  cvcIcon: visibility,
  groupingBehavior: groupingBehavior,
  defaultCollapsed: bool,
  hiddenPaymentMethods: array<string>,
}

type layout = {
  layoutType: layoutType,
  showOneClickWalletsOnTop: bool,
  paymentMethodsArrangementForTabs: paymentMethodsArrangement,
  defaultCollapsed: bool,
  radios: bool,
  spacedAccordionItems: bool,
  maxAccordionItems: int,
  cvcIcon: visibility,
  cardBrandIcon: cardBrandVisibility,
  showCheckedIconForSelection: bool,
  savedMethodCustomization: savedMethodCustomization,
}

let defaultLayout: layout = {
  layoutType: Tabs,
  showOneClickWalletsOnTop: true,
  paymentMethodsArrangementForTabs: ArrangementDefault,
  defaultCollapsed: true,
  radios: false,
  spacedAccordionItems: true,
  maxAccordionItems: 4,
  cvcIcon: Shown,
  cardBrandIcon: Animated,
  showCheckedIconForSelection: false,
  savedMethodCustomization: {
    hideCardExpiry: false,
    hideCVCError: false,
    cvcIcon: Shown,
    defaultCollapsed: false,
    groupingBehavior: {
      displayInSeparateScreen: true,
      displayInSeparateSection: false,
      groupByPaymentMethods: false,
    },
    hiddenPaymentMethods: [],
  },
}

let parseLayout = (configObj: Dict.t<JSON.t>) => {
  let layoutRaw = configObj->Dict.get("paymentMethodLayout")
  let layoutObj = layoutRaw->Option.flatMap(JSON.Decode.object)

  switch layoutObj {
  | Some(obj) => {
      let savedMethodCustomizationDict =
        obj
        ->Dict.get("savedMethodCustomization")
        ->Option.flatMap(JSON.Decode.object)
        ->Option.getOr(Dict.make())
      {
        layoutType: switch getString(obj, "type", "tabs") {
        | "accordion" | "spacedAccordion" => Accordion
        | _ => Tabs
        },
        showOneClickWalletsOnTop: getBool(obj, "showOneClickWalletsOnTop", true),
        paymentMethodsArrangementForTabs: switch getString(
          obj,
          "paymentMethodsArrangementForTabs",
          "default",
        ) {
        | "grid" => ArrangementGrid
        | _ => ArrangementDefault
        },
        defaultCollapsed: getBool(obj, "defaultCollapsed", false),
        radios: getBool(obj, "radios", true),
        spacedAccordionItems: getBool(obj, "spacedAccordionItems", false),
        maxAccordionItems: getInt(obj, "maxAccordionItems", 4),
        cvcIcon: switch getString(obj, "cvcIcon", "shown") {
        | "hidden" => Hidden
        | _ => Shown
        },
        cardBrandIcon: switch getString(obj, "cardBrandIcon", "animated") {
        | "hidden" => Hidden
        | "standard" => Standard
        | "hideDefault" => HideDefault
        | _ => Animated
        },
        showCheckedIconForSelection: getBool(obj, "showCheckedIconForSelection", false),
        savedMethodCustomization: {
          hideCardExpiry: getBool(savedMethodCustomizationDict, "hideCardExpiry", false),
          hideCVCError: getBool(savedMethodCustomizationDict, "hideCVCError", false),
          cvcIcon: switch getString(
            savedMethodCustomizationDict,
            "cvcIcon",
            getString(obj, "cvcIcon", "shown"),
          ) {
          | "hidden" => Hidden
          | _ => Shown
          },
          groupingBehavior: switch savedMethodCustomizationDict
          ->Dict.get("groupingBehavior")
          ->Option.flatMap(JSON.Decode.object) {
          | Some(gbObj) => {
              displayInSeparateScreen: getBool(gbObj, "displayInSeparateScreen", true),
              displayInSeparateSection: getBool(gbObj, "displayInSeparateSection", false),
              groupByPaymentMethods: getBool(gbObj, "groupByPaymentMethods", false),
            }
          | None =>
            switch getString(savedMethodCustomizationDict, "groupingBehavior", "default") {
            | "groupByPaymentMethods" => {
                displayInSeparateScreen: false,
                displayInSeparateSection: false,
                groupByPaymentMethods: true,
              }
            | _ => defaultLayout.savedMethodCustomization.groupingBehavior
            }
          },
          defaultCollapsed: getBool(savedMethodCustomizationDict, "defaultCollapsed", false),
          hiddenPaymentMethods: savedMethodCustomizationDict
          ->Dict.get("hiddenPaymentMethods")
          ->Option.flatMap(JSON.Decode.array)
          ->Option.getOr([])
          ->Array.filterMap(JSON.Decode.string),
        },
      }
    }
  | None => {
      ...defaultLayout,
      layoutType: switch getString(configObj, "layout", "") {
      | "accordion" => Accordion
      | _ => Tabs
      },
    }
  }
}
