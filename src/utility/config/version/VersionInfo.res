type packageJson = {version: string}

@val external importPackageJson: string => packageJson = "require"

let version = importPackageJson("../../../../package.json").version
