const express = require('express');
const router = express.Router();
const { register, login, getMe, logout } = require('../controllers/authController');
const { validateRegister, validateLogin, validate } = require('../validators/authValidator');
const auth = require('../middleware/auth');

// Public routes
router.post('/register', validateRegister, validate, register);
router.post('/login', validateLogin, validate, login);

// Protected route
router.get('/me', auth, getMe);
router.post('/logout', auth, logout);

module.exports = router;