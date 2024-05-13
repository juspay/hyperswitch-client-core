@react.component
let make = (~text) => {
  switch text {
  | None => React.null
  | Some(val) =>
    val == ""
      ? React.null
      : <>
          <Space height=4. />
          <TextWrapper textType={ErrorText}> {val->React.string} </TextWrapper>
          <Space />
        </>
  }
}
