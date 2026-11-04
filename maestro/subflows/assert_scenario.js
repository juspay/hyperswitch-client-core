// KEEP_SCENARIO guard: fails unless the mock server still holds the scenario (and fresh customer) that
// set_scenario.js selected earlier in this flow. Without it, a server restart between two launches
// would silently fall back to the default customer and a "saved card" check could pass by accident.
const port = typeof MOCK_PORT === 'undefined' ? '5252' : MOCK_PORT
const res = http.get('http://localhost:' + port + '/scenario')
const active = json(res.body)
const expected = output.scenario
if (!expected) {
  throw new Error('KEEP_SCENARIO used before any scenario was set in this flow')
}
if (active.name !== expected.name || active.customerId !== expected.customerId) {
  throw new Error('Mock server scenario changed: expected ' + JSON.stringify(expected) + ', got ' + res.body)
}
