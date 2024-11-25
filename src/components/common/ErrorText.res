@react.component
let make = (~text=None) => {
  switch text {
  | None => React.null
  | Some(val) =>
    val == ""
      ? React.null
      : <>
          <TextWrapper textType={ErrorText}> {val->React.string} </TextWrapper>
        </>
  }
}
