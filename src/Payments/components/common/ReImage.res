open ReactNative
open Style
@react.component
let make = (~uri, ~style=s({width: 33.->dp, height: 33.->dp})) => {
  <Image style source={Image.Source.fromUriSource({uri: uri})} />
}
