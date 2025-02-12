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
  submitButtonCustomization?: buttonCustomization,
  cancelButtonCustomization?: buttonCustomization,
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

    let buttonObj = getObj(uiObj, "buttonCustomization", Dict.make())

    let submitButtonCustomization = if buttonObj != Dict.make() {
      let submitBtn = getObj(buttonObj, "submit", Dict.make())
      if submitBtn != Dict.make() {
        Some({
          backgroundColor: ?getOptionString(submitBtn, "backgroundColor"),
          cornerRadius: ?getOptionFloat(submitBtn, "cornerRadius"),
          textFontSize: ?getOptionFloat(submitBtn, "textFontSize"),
          textColor: ?getOptionString(submitBtn, "textColor"),
        })
      } else {
        None
      }
    } else {
      None
    }

    let cancelButtonCustomization = if buttonObj != Dict.make() {
      let cancelBtn = getObj(buttonObj, "cancel", Dict.make())
      if cancelBtn != Dict.make() {
        Some({
          backgroundColor: ?getOptionString(cancelBtn, "backgroundColor"),
          cornerRadius: ?getOptionFloat(cancelBtn, "cornerRadius"),
          textFontSize: ?getOptionFloat(cancelBtn, "textFontSize"),
          textColor: ?getOptionString(cancelBtn, "textColor"),
        })
      } else {
        None
      }
    } else {
      None
    }

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
      ?submitButtonCustomization,
      ?cancelButtonCustomization,
      ?viewCustomization,
    }

    Some(finalResult)
  | None => None
  }
}

let getChallengeCustomisationRecord = (netceteraChallengeUICustomizationDict, locale) => {
  let locale = locale->Option.getOr("")
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

  Console.log2("LightMode", lightModeDict)

  let lightX = fun(lightModeDict)
  let darkX = fun(darkModeDict)

  Console.log2("LightMode X", lightX)

  {locale, lightMode: lightX, darkMode: darkX}
}
