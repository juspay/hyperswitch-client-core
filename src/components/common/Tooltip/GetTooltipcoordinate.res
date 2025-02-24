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

let constraintX = (newX, qIndex, screenWidth, tooltipWidth) => {
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

let constraintY = (newY, qIndex, screenHeight, tooltipHeight) => {
  switch qIndex {
  | 2 | 3 => {
      let minY = 10.0
      newY < minY ? minY : newY
    }
  | 0 | 1 => {
      let maxY = screenHeight -. tooltipHeight -. 10.0
      newY > maxY ? maxY : newY
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
  ~tooltipHeight: dimension, // height of the tooltip
) => {
  let tooltipWidthNum = convertDimensionToNumber(
    tooltipWidth,
    ReactNative.Dimensions.get(#window).width,
  )
  let tooltipHeightNum = convertDimensionToNumber(
    tooltipHeight,
    ReactNative.Dimensions.get(#window).height,
  )

  let center = (x +. width /. 2.0, y +. height /. 2.0)
  let (centerX, centerY) = center

  let points = [(centerX, 0.0), (screenWidth, centerY), (centerX, screenHeight), (0.0, centerY)]

  let distances = points->Array.map(point => getPointDistance(center, point))

  let areas = [
    (
      getArea(distances->Array.get(0)->Option.getOr(0.), distances->Array.get(3)->Option.getOr(0.)),
      0,
    ),
    (
      getArea(distances->Array.get(0)->Option.getOr(0.), distances->Array.get(1)->Option.getOr(0.)),
      1,
    ),
    (
      getArea(distances->Array.get(1)->Option.getOr(0.), distances->Array.get(2)->Option.getOr(0.)),
      2,
    ),
    (
      getArea(distances->Array.get(2)->Option.getOr(0.), distances->Array.get(3)->Option.getOr(0.)),
      3,
    ),
  ]
  areas->Array.sort(((a, _), (b, _)) => b -. a)
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
  let newY = centerY +. (dY *. dirY +. deslocY)

  {
    x: constraintX(newX, qIndex, screenWidth, tooltipWidthNum),
    y: constraintY(newY, qIndex, screenHeight, tooltipHeightNum),
  }
}
