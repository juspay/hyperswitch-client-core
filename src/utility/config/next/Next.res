type environment = {environment: string}
type env = {env: environment}
@val external process: env = "process"

let getNextEnv = try {
  process.env.environment
} catch {
| _ => ""
}

@module("./NextImpl")
external clientResponse: JSON.t = "clientResponse"

@module("./NextImpl")
external sessionsRes: JSON.t = "sessionsRes"
