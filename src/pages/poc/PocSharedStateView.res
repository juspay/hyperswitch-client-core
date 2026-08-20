// ---------------------------------------------------------------------------
// POC ONLY — DELETE AFTER DEMO. See PocSharedState.res for the explanation.
// ---------------------------------------------------------------------------
open ReactNative
open Style

let btn = s({
  backgroundColor: "#444",
  paddingHorizontal: 10.->dp,
  paddingVertical: 6.->dp,
  borderRadius: 4.,
})

@react.component
let make = (~rootTag: int) => {
  let (lastRead, setLastRead) = React.useState(_ => "-")
  <View
    style={s({
      padding: 8.->dp,
      backgroundColor: "#1b1b2c",
      borderTopWidth: 1.,
      borderTopColor: "#444",
    })}>
    <Text style={s({color: "#0f0", fontSize: 11.})}>
      {React.string(
        `[PoC] vmUid=${PocSharedState.vmUid->Js.String2.slice(~from=0, ~to_=7)}  rootTag=${rootTag->Belt.Int.toString}`,
      )}
    </Text>
    <View style={s({flexDirection: #row, marginTop: 6.->dp})}>
      <TouchableOpacity style=btn onPress={_ => PocSharedState.write(~rootTag)->ignore}>
        <Text style={s({color: "#fff", fontSize: 12.})}> {React.string("WRITE")} </Text>
      </TouchableOpacity>
      <View style={s({width: 8.->dp})} />
      <TouchableOpacity
        style=btn onPress={_ => setLastRead(_ => PocSharedState.readAll(~rootTag))}>
        <Text style={s({color: "#fff", fontSize: 12.})}> {React.string("READ SHARED")} </Text>
      </TouchableOpacity>
    </View>
    <Text style={s({color: "#9cf", fontSize: 11., marginTop: 6.->dp})}>
      {React.string(`read: ${lastRead}`)}
    </Text>
  </View>
}
