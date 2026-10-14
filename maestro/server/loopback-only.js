// Preloaded (`node -r`) into mockServer.js when e2e-server.js starts it. mockServer.js listens on
// 0.0.0.0; this makes that listen() bind to 127.0.0.1 instead, so the internal backend, which answers
// with the publishable key and creates payments with the secret key, is not reachable from the
// network. mockServer.js itself is not changed.
const net = require('net');

const listen = net.Server.prototype.listen;
net.Server.prototype.listen = function (...args) {
  if (args[1] === '0.0.0.0') {
    args[1] = '127.0.0.1';
  }
  return listen.apply(this, args);
};
