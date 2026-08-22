const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const {
  getChats,
  getOrCreateChat,
  getMessages,
  sendMessage,
  markAsRead,
} = require('../controllers/chatController');
const { validateMessage, validate } = require('../validators/chatValidator');

// All chat routes are protected
router.use(auth);

// Chat routes
router.get('/', getChats);
router.post('/', getOrCreateChat);

// Message routes
router.get('/:chatId/messages', getMessages);
router.post('/messages', validateMessage, validate, sendMessage);
router.put('/:chatId/read', markAsRead);

module.exports = router;