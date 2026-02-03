open Utils

type layoutType = Tab | Accordion
type paymentMethodsArrangement = ArrangementDefault | ArrangementGrid
type groupingBehavior = GroupByPaymentMethods | GroupingDefault

type savedMethodCustomization = {
  groupingBehavior: groupingBehavior,
}

type layout = {
  layoutType: layoutType,
  showOneClickWalletsOnTop: bool,
  paymentMethodsArrangementForTabs: paymentMethodsArrangement,
  defaultCollapsed: bool,
  radios: bool,
  spacedAccordionItems: bool,
  maxAccordionItems: int,
  savedMethodCustomization: savedMethodCustomization,
}

let defaultLayout: layout = {
  layoutType: Tab,
  showOneClickWalletsOnTop: true,
  paymentMethodsArrangementForTabs: ArrangementDefault,
  defaultCollapsed: false,
  radios: false,
  spacedAccordionItems: false,
  maxAccordionItems: 4,
  savedMethodCustomization: {groupingBehavior: GroupingDefault},
}

let parseLayout = (appearanceDict: Dict.t<JSON.t>) => {
  let layoutRaw = appearanceDict->Dict.get("layout")
  let layoutObj = layoutRaw->Option.flatMap(JSON.Decode.object)

  switch layoutObj {
  | Some(obj) => {
      let savedMethodCustomizationDict =
        obj->Dict.get("savedMethodCustomization")->Option.flatMap(JSON.Decode.object)
      {
        layoutType: switch getString(obj, "type", "tabs") {
        | "tabs" => Tab
        | "accordion" | "spacedAccordion" => Accordion
        | _ => Tab
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
        radios: getBool(obj, "radios", false),
        spacedAccordionItems: getBool(obj, "spacedAccordionItems", false),
        maxAccordionItems: getInt(obj, "maxAccordionItems", 4),
        savedMethodCustomization: {
          groupingBehavior: switch savedMethodCustomizationDict {
          | Some(smDict) =>
            switch getString(smDict, "groupingBehavior", "default") {
            | "groupByPaymentMethods" => GroupByPaymentMethods
            | _ => GroupingDefault
            }
          | None => GroupingDefault
          },
        },
      }
    }
  | None =>
    {
      layoutType: switch getString(appearanceDict, "layout", "") {
      | "tabs" => Tab
      | "accordion" | "spacedAccordion" => Accordion
      | _ => Tab
      },
      showOneClickWalletsOnTop: true,
      paymentMethodsArrangementForTabs: ArrangementDefault,
      defaultCollapsed: false,
      radios: false,
      spacedAccordionItems: false,
      maxAccordionItems: 4,
      savedMethodCustomization: {groupingBehavior: GroupingDefault},
    }
  }
}
