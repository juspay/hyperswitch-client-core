

@react.component
let make = (~text) => {

  switch text {
  | "" => React.null
  | val =>
    <>
      <Space height=4. />
      <TextWrapper textType={ErrorText}>
        {val->React.string}
      </TextWrapper>
      <Space />
    </>
  }
}
