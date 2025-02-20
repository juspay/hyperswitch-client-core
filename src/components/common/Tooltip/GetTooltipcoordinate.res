open TooltipTypes

let convertDimensionToNumber = (dimension, screenDimension) => {
  switch dimension {
  | String(value) =>
    if Js.String.includes("%", value) {
      let decimal = Js.Float.fromString(Js.String.replaceByRe(%re("/%/"), "", value)) /. 100.0
      decimal *. screenDimension
    } else {
      Js.Float.fromString(value)
    }
  | Number(value) => value
  }
}

let getArea = (a: float, b: float) => a *. b

let getPointDistance = (a: (float, float), b: (float, float)) => {
  let (x1, y1) = a
  let (x2, y2) = b
  Js.Math.sqrt(
    Js.Math.pow_float(~base=x1 -. x2, ~exp=2.0) +. Js.Math.pow_float(~base=y1 -. y2, ~exp=2.0),
  )
}

let constraintX = (newX, qIndex, x, screenWidth, tooltipWidth) => {
  switch qIndex {
  | 0 | 3 => {
      let maxWidth = newX > screenWidth ? screenWidth -. 10.0 : newX
      newX < 1.0 ? 10.0 : maxWidth
    }
  | 1 | 2 => {
      let leftOverSpace = screenWidth -. newX
      leftOverSpace >= tooltipWidth ? newX : newX -. (tooltipWidth -. leftOverSpace +. 10.0)
    }
  | _ => 0.0
  }
}

let getTooltipCoordinate = (
  ~x: float, // x coordinate of the target element
  ~y: float, // y coordinate of the target element
  ~width: float, // width of the target element
  ~height: float, // height of the target element
  ~screenWidth: float, // width of the screen
  ~screenHeight: float, // height of the screen
  ~tooltipWidth: dimension, // width of the tooltip
) => {
  let tooltipWidthNum = convertDimensionToNumber(
    tooltipWidth,
    ReactNative.Dimensions.get(#window).width,
  )
  let center = (x +. width /. 2.0, y +. height /. 2.0)
  let (centerX, centerY) = center

  let points = [(centerX, 0.0), (screenWidth, centerY), (centerX, screenHeight), (0.0, centerY)]

  let distances = points->Array.map(point => getPointDistance(center, point))

  let areas =
    Belt.Array.range(0, 3)
    ->Belt.Array.map(i => {
      let area = getArea(
        distances->Array.get(i)->Option.getOr(0.),
        distances->Array.get(mod(i + 1, 4))->Option.getOr(0.),
      )
      (area, i)
    })
    ->Belt.SortArray.stableSortBy(((a, _), (b, _)) => compare(b, a))

  let (_, qIndex) = areas[0]->Option.getOr((0., 0))

  let dX = 0.001
  let dY = height /. 2.0

  let directionCorrection = [(-1.0, -1.0), (1.0, -1.0), (1.0, 1.0), (-1.0, 1.0)]
  let deslocateReferencePoint = [
    (-.tooltipWidthNum, 0.0),
    (0.0, 0.0),
    (0.0, 0.0),
    (-.tooltipWidthNum, 0.0),
  ]

  let (dirX, dirY) = directionCorrection[qIndex]->Option.getOr((0., 0.))
  let (deslocX, deslocY) = deslocateReferencePoint[qIndex]->Option.getOr((0., 0.))

  let newX = centerX +. (dX *. dirX +. deslocX)

  {
    x: constraintX(newX, qIndex, centerX, screenWidth, tooltipWidthNum),
    y: centerY +. (dY *. dirY +. deslocY),
  }
}
