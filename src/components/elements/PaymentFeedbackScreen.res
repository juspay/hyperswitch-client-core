open ReactNative
open Style

@react.component
let make = (~isSuccess: bool) => {
  
  let successColors = [
    ("iconColor", "#4CAF50"),
    ("backgroundColor", "rgba(76, 175, 80, 0.1)"),
    ("outerRing", "rgba(76, 175, 80, 0.2)"),
    ("textColor", "#2E7D32")
  ]->Dict.fromArray
  
  let failureColors = [
    ("iconColor", "#F44336"),
    ("backgroundColor", "rgba(244, 67, 54, 0.1)"),
    ("outerRing", "rgba(244, 67, 54, 0.2)"),
    ("textColor", "#C62828")
  ]->Dict.fromArray
  
  let colors = isSuccess ? successColors : failureColors
  let statusText = isSuccess ? "Payment Successful" : "Payment Failed"
  
  <View style={s({
    alignItems: #center,
    justifyContent: #center,
    paddingHorizontal: 40.->dp
  })}>
    <View style={s({
      width: 180.->dp,
      height: 180.->dp,
      borderRadius: 90.,
      backgroundColor: colors->Dict.get("outerRing")->Option.getOr("rgba(76, 175, 80, 0.2)"),
      alignItems: #center,
      justifyContent: #center,
      marginBottom: 32.->dp
    })}>
      <View style={s({
        width: 140.->dp,
        height: 140.->dp,
        borderRadius: 70.,
        backgroundColor: colors->Dict.get("backgroundColor")->Option.getOr("rgba(76, 175, 80, 0.1)"),
        alignItems: #center,
        justifyContent: #center
      })}>
        <View style={s({
          width: 80.->dp,
          height: 80.->dp,
          borderRadius: 40.,
          backgroundColor: colors->Dict.get("iconColor")->Option.getOr("#4CAF50"),
          alignItems: #center,
          justifyContent: #center
        })}>
          {isSuccess 
            ? <Icon name="checkboxclicked" width=40. height=40. fill="white" />
            : <Icon name="close" width=40. height=40. fill="white" />
          }
        </View>
      </View>
    </View>
    
    <TextWrapper 
      text={statusText}
      textType={Subheading}
      overrideStyle=Some(s({
        fontSize: 18.,
        fontWeight: #"600",
        color: colors->Dict.get("textColor")->Option.getOr("#2E7D32"),
        textAlign: #center
      }))
    />
  </View>
}
