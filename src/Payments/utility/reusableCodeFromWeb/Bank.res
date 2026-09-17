type bank = {
  displayName: string,
  hyperSwitch: string,
}

let bankNameConverter = (var: array<string>) => {
  let final = var->Array.map(item => {
    let x =
      item
      ->String.split("_")
      ->Array.map(w => {
        w->String.charAt(0)->String.toUpperCase ++ w->String.sliceToEnd(~start=1)
      })
    let data = x->Array.join(" ")
    {
      displayName: data,
      hyperSwitch: item,
    }
  })

  final->Js.Array.sortInPlace
}
