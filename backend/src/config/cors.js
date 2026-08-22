const cors = require('cors');

const extraOrigins = (process.env.CLIENT_URL || '')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);

const isDev = process.env.NODE_ENV !== 'production';
const localOrigin =
  /^https?:\/\/(localhost|127\.0\.0\.1|10\.0\.2\.2)(:\d+)?$/;

const origin = (requestOrigin, callback) => {
  // Native apps and same-origin/server-to-server requests have no Origin header
  if (!requestOrigin) {
    return callback(null, true);
  }
  if (extraOrigins.includes(requestOrigin)) {
    return callback(null, true);
  }
  if (isDev && localOrigin.test(requestOrigin)) {
    return callback(null, true);
  }
  return callback(new Error(`CORS blocked for origin ${requestOrigin}`));
};

const corsOptions = {
  origin,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  optionsSuccessStatus: 200,
};

module.exports = cors(corsOptions);
module.exports.socketCors = {
  origin,
  credentials: true,
  methods: ['GET', 'POST'],
};
