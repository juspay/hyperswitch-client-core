open ReactNative

@react.component
let make = (~text=None) => {
  switch text {
  | None => React.null
  | Some(val) =>
    val == ""
      ? React.null
      : <View
          accessible={true}
          accessibilityRole=#alert
          accessibilityLiveRegion=#assertive
        >
          <TextWrapper textType={ErrorText}> {val->React.string} </TextWrapper>
        </View>
  }
}
