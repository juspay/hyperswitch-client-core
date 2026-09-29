// Selects the e2e server scenario (maestro/server/scenarios.js) before the app creates its payment intent.
// runScript runs on the host machine, so the server is localhost here on both platforms.
const name = typeof SCENARIO === 'undefined' ? 'default' : SCENARIO
const port = typeof MOCK_PORT === 'undefined' ? '5252' : MOCK_PORT
const res = http.post('http://localhost:' + port + '/scenario', {
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({name: name}),
})
if (res.status !== 200) {
  throw new Error('Scenario ' + name + ' unavailable (' + res.status + '): ' + res.body)
}
output.scenario = json(res.body)
