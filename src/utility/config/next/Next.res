type environment = {environment: string}
type env = {env: environment}
@val external process: env = "process"

let getNextEnv = try {
  process.env.environment
} catch {
| _ => ""
}

@module("./NextImpl")
external clistRes: JSON.t = "clistRes"

@module("./NextImpl")
external listRes: JSON.t = "listRes"

@module("./NextImpl")
external sessionsRes: JSON.t = "sessionsRes"
