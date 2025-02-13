open Utils

type labelCustomization = {
  headingTextFontSize?: float,
  textFontSize?: float,
}

type textBoxCustomization = {
  borderColor?: string,
  borderWidth?: float,
  cornerRadius?: float,
}

type toolbarCustomization = {
  backgroundColor?: string,
  textColor?: string,
  buttonText?: string,
  headerText?: string,
}

type buttonCustomization = {
  buttonType: string,
  backgroundColor?: string,
  cornerRadius?: float,
  textFontSize?: float,
  textColor?: string,
}

type viewCustomization = {
  challengeViewBackgroundColor?: string,
  progressViewBackgroundColor?: string,
}

type netceteraChallengeUICustomization = {
  labelCustomization?: labelCustomization,
  textBoxCustomization?: textBoxCustomization,
  toolbarCustomization?: toolbarCustomization,
  buttonCustomization?: array<buttonCustomization>,
  viewCustomization?: viewCustomization,
}

type netceteraChallengeUICustomizationType = {
  locale: string,
  lightMode?: option<netceteraChallengeUICustomization>,
  darkMode?: option<netceteraChallengeUICustomization>,
}

let fun = netceteraChallengeUICustomization => {
  switch netceteraChallengeUICustomization {
  | Some(uiObj) =>
    let labelObj = getObj(uiObj, "labelCustomization", Dict.make())
    let labelCustomization = if labelObj != Dict.make() {
      Some({
        headingTextFontSize: ?getOptionFloat(labelObj, "headingTextFontSize"),
        textFontSize: ?getOptionFloat(labelObj, "textFontSize"),
      })
    } else {
      None
    }

    let textBoxObj = getObj(uiObj, "textBoxCustomization", Dict.make())
    let textBoxCustomization = if textBoxObj != Dict.make() {
      Some({
        borderColor: ?getOptionString(textBoxObj, "borderColor"),
        borderWidth: ?getOptionFloat(textBoxObj, "borderWidth"),
        cornerRadius: ?getOptionFloat(textBoxObj, "cornerRadius"),
      })
    } else {
      None
    }

    let toolbarObj = getObj(uiObj, "toolbarCustomization", Dict.make())
    let toolbarCustomization = if toolbarObj != Dict.make() {
      Some({
        backgroundColor: ?getOptionString(toolbarObj, "backgroundColor"),
        textColor: ?getOptionString(toolbarObj, "textColor"),
        buttonText: ?getOptionString(toolbarObj, "buttonText"),
        headerText: ?getOptionString(toolbarObj, "headerText"),
      })
    } else {
      None
    }

    let buttonCustomization = getArrayFromDict(uiObj, "buttonCustomization", [])
    let buttonCustomizationArray = buttonCustomization->Array.map(obj => {
    let objDict = getDictFromJson(obj)
      ({
        buttonType: getOptionString(objDict, "buttonType")->Option.getOr("SUBMIT"),
        backgroundColor: ?getOptionString(objDict, "backgroundColor"),
        cornerRadius: ?getOptionFloat(objDict, "cornerRadius"),
        textFontSize: ?getOptionFloat(objDict, "textFontSize"),
        textColor: ?getOptionString(objDict, "textColor"),
      })
    })


    let viewObj = getObj(uiObj, "viewCustomization", Dict.make())
    let viewCustomization = if viewObj != Dict.make() {
      Some({
        challengeViewBackgroundColor: ?getOptionString(viewObj, "challengeViewBackgroundColor"),
        progressViewBackgroundColor: ?getOptionString(viewObj, "progressViewBackgroundColor"),
      })
    } else {
      None
    }

    let finalResult = {
      ?labelCustomization,
      ?textBoxCustomization,
      ?toolbarCustomization,
      buttonCustomization : buttonCustomizationArray,
      ?viewCustomization,
    }

    Some(finalResult)
  | None => None
  }
}

let getChallengeCustomisationRecord = (netceteraChallengeUICustomizationDict, locale) => {
  let locale = locale->Option.getOr("en")
  let lightModeDict =
    netceteraChallengeUICustomizationDict
    ->Option.getOr(Dict.make())
    ->Dict.get("lightModeCustomization")
    ->Option.flatMap(JSON.Decode.object)

  let darkModeDict =
    netceteraChallengeUICustomizationDict
    ->Option.getOr(Dict.make())
    ->Dict.get("darkModeCustomization")
    ->Option.flatMap(JSON.Decode.object)

  // Console.log2("LightMode", lightModeDict)

  let lightX = fun(lightModeDict)
  let darkX = fun(darkModeDict)

  // Console.log2("LightMode X", lightX)

  {locale, lightMode: lightX, darkMode: darkX}
}
