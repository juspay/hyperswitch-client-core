type props = {
  height?: string,
  width?: string,
  speed?: float,
  radius?: float,
  style?: ReactNative.Style.t,
}

@module("./CustomLoaderImpl")
external make: React.component<props> = "make"
