// Checks the backend state of the latest intent the mock server created for the active scenario.
// runScript runs on the host, so the server is localhost on both platforms.
//   EXPECT_STATUS   payment status regex, e.g. succeeded, requires_capture, failed
//   EXPECT_LAST4    optional: last 4 digits of the card that must have been charged
//   EXPECT_NETWORK  optional: card network regex, case-insensitive, e.g. visa, mastercard
//   EXPECT_AUTH     optional: authentication type, e.g. three_ds, no_three_ds
//   EXPECT_EXPIRY   optional: card expiry as MM/YY, e.g. 12/30
//   EXPECT_PM_TYPE  optional: payment method type, e.g. credit, klarna
//   EXPECT_AMOUNT   optional: amount in minor units, e.g. 100
const port = typeof MOCK_PORT === 'undefined' ? '5252' : MOCK_PORT
const res = http.get('http://localhost:' + port + '/scenario/last-payment')
if (res.status !== 200) {
  throw new Error('No backend payment for the active scenario (' + res.status + '): ' + res.body)
}
const payment = json(res.body)
const problems = []
if (typeof EXPECT_STATUS !== 'undefined' && !new RegExp('^(' + EXPECT_STATUS + ')$').test(payment.status)) {
  problems.push('status ' + payment.status + ' does not match ' + EXPECT_STATUS)
}
if (typeof EXPECT_LAST4 !== 'undefined' && payment.cardLast4 !== EXPECT_LAST4) {
  problems.push('card last4 ' + payment.cardLast4 + ' is not ' + EXPECT_LAST4)
}
if (typeof EXPECT_NETWORK !== 'undefined' && !new RegExp('^(' + EXPECT_NETWORK + ')$', 'i').test(String(payment.cardNetwork))) {
  problems.push('card network ' + payment.cardNetwork + ' does not match ' + EXPECT_NETWORK)
}
if (typeof EXPECT_AUTH !== 'undefined' && payment.authenticationType !== EXPECT_AUTH) {
  problems.push('authentication type ' + payment.authenticationType + ' is not ' + EXPECT_AUTH)
}
if (typeof EXPECT_EXPIRY !== 'undefined') {
  const month = String(payment.cardExpMonth || '').padStart(2, '0')
  const year = String(payment.cardExpYear || '').slice(-2)
  if (month + '/' + year !== EXPECT_EXPIRY) {
    problems.push('card expiry ' + month + '/' + year + ' is not ' + EXPECT_EXPIRY)
  }
}
if (typeof EXPECT_PM_TYPE !== 'undefined' && payment.paymentMethodType !== EXPECT_PM_TYPE) {
  problems.push('payment method type ' + payment.paymentMethodType + ' is not ' + EXPECT_PM_TYPE)
}
if (typeof EXPECT_AMOUNT !== 'undefined' && String(payment.amount) !== String(EXPECT_AMOUNT)) {
  problems.push('amount ' + payment.amount + ' is not ' + EXPECT_AMOUNT)
}
if (problems.length > 0) {
  throw new Error('Backend payment ' + payment.paymentId + ': ' + problems.join('; ') + ' :: ' + res.body)
}
output.backendPayment = payment
