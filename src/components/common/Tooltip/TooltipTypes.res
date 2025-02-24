type dimension = String(string) | Number(float)

type elementInfo = {
  xOffset: float,
  yOffset: float,
  elementWidth: float,
  elementHeight: float,
}

type coordinate = {
  x: float,
  y: float,
}

type coordinates = Loading | Coordinate(coordinate)