const rateLimit = require('express-rate-limit');

// Safely parse environment variables
const getEnvNumber = (key, defaultValue) => {
  const value = process.env[key];
  if (value === undefined || value === null || value === '') {
    return defaultValue;
  }
  const parsed = parseInt(value, 10);
  return isNaN(parsed) ? defaultValue : parsed;
};

const windowMinutes = getEnvNumber('RATE_LIMIT_WINDOW', 15);
const maxRequests = getEnvNumber('RATE_LIMIT_MAX', 100);

console.log(`📊 Rate Limiter: ${maxRequests} requests per ${windowMinutes} minutes`);

const limiter = rateLimit({
  windowMs: windowMinutes * 60 * 1000, // Convert to milliseconds
  limit: maxRequests,
  message: {
    success: false,
    message: 'Too many requests, please try again later.',
  },
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => {
    // Skip rate limiting for health check endpoint
    return req.path === '/health';
  },
});

module.exports = limiter;