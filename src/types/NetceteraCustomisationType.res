open Utils

type labelCustomization = {
  textFontName?: string,
  textColor?: string,
  textFontSize?: float,
  headingTextFontName?: string,
  headingTextColor?: string,
  headingTextFontSize?: float,
}

type textBoxCustomization = {
  textFontName?: string,
  textColor?: string,
  textFontSize?: float,
  borderWidth?: float,
  borderColor?: string,
  cornerRadius?: float,
}

type toolbarCustomization = {
  textFontName?: string,
  textColor?: string,
  textFontSize?: string,
  backgroundColor?: string,
  headerText?: string,
  buttonText?: string,
}

type buttonCustomization = {
  buttonType: string,
  backgroundColor?: string,
  cornerRadius?: float,
  textFontName?: string,
  textFontSize?: string,
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
        textFontName: ?getOptionString(labelObj, "textFontName"),
        headingTextFontName: ?getOptionString(labelObj, "headingTextFontName"),
        headingTextColor: ?getOptionString(labelObj, "headingTextColor"),
        textColor: ?getOptionString(labelObj, "textColor"),
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
        textFontName: ?getOptionString(textBoxObj, "textFontName"),
        textColor: ?getOptionString(textBoxObj, "textColor"),
        textFontSize: ?getOptionFloat(textBoxObj, "textFontSize"),
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
        textFontName: ?getOptionString(toolbarObj, "textFontName"),
        textFontSize: ?getOptionString(toolbarObj, "textFontSize"),
      })
    } else {
      None
    }

    let buttonCustomization = getArrayFromDict(uiObj, "buttonCustomization", [])
    let buttonCustomizationArray = buttonCustomization->Array.map(obj => {
      let objDict = getDictFromJson(obj)
      {
        buttonType: getOptionString(objDict, "buttonType")->Option.getOr("SUBMIT"),
        backgroundColor: ?getOptionString(objDict, "backgroundColor"),
        cornerRadius: ?getOptionFloat(objDict, "cornerRadius"),
        textFontName: ?getOptionString(objDict, "textFontName"),
        textFontSize: ?getOptionString(objDict, "textFontSize"),
        textColor: ?getOptionString(objDict, "textColor"),
      }
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
      buttonCustomization: buttonCustomizationArray,
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

  let lightX = fun(lightModeDict)
  let darkX = fun(darkModeDict)

  {locale, lightMode: lightX, darkMode: darkX}
}
