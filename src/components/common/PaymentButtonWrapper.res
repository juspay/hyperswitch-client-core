open ReactNative
open Style

@react.component
let make = (~children) => {
  Platform.os === #web
    ? children
    : <View
        style={s({flex: 1., flexDirection: #row, width: 100.->pct, height: 100.->pct})}
        pointerEvents=#none>
        children
      </View>
}
