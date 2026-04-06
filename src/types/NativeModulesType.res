open Utils

// Widget action types that can be triggered from native side
type widgetActionType = ConfirmPayment

let widgetActionTypeToString = actionType =>
  switch actionType {
  | ConfirmPayment => "confirmPayment"
  }

let widgetActionTypeFromString = (str: string): option<widgetActionType> =>
  switch str {
  | "confirmPayment" => Some(ConfirmPayment)
  | _ => None
  }

// Widget action data structure received from native
type widgetActionData = {
  actionType: widgetActionType,
  rootTag: int,
}

let widgetActionDataMapper = (dict: Dict.t<JSON.t>): option<widgetActionData> => {
  let actionTypeStr = dict->getString("actionType", "")
  let rootTag = dict->getInt("rootTag", -1);

  actionTypeStr
  ->widgetActionTypeFromString
  ->Option.map(actionType => {
    actionType,
    rootTag,
  })
}
