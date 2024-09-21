open ReactNative
open Style

@react.component
let make = () => {
  let {component} = ThemebasedStyle.useThemeBasedStyle()
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let (isLoading, setIsLoading) = React.useState(_ => true)
  let (savedMethods, setSavedMethods) = React.useState(_ => [])

  React.useEffect(() => {
    switch allApiData.savedPaymentMethods {
    | Loading => setIsLoading(_ => true)
    | Some(data) =>
      setSavedMethods(_ => data.pmList->Option.getOr([]))
      setIsLoading(_ => false)
    | None => setIsLoading(_ => false)
    }
    None
  }, [allApiData.savedPaymentMethods])

  isLoading
    ? <View
        style={viewStyle(
          ~backgroundColor=component.background,
          ~width=100.->pct,
          ~height=100.->pct,
          ~flex=1.,
          ~justifyContent=#center,
          ~alignItems=#center,
          (),
        )}>
        <TextWrapper text={"Loading ..."} textType={CardText} />
      </View>
    : <View
        style={viewStyle(
          ~backgroundColor=component.background,
          ~height=100.->pct,
          ~paddingTop=20.->pct,
          (),
        )}>
        <ScrollView>
          {savedMethods
          ->Array.mapWithIndex((item, i) => {
            <PaymentMethodListItem
              key={i->Int.toString}
              pmDetails={item}
              isLastElement={Some(savedMethods)->Option.getOr([])->Array.length - 1 != i}
            />
          })
          ->React.array}
        </ScrollView>
      </View>
}
