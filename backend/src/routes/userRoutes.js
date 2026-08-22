const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const upload = require('../middleware/upload');
const {
  getUsers,
  searchUsers,
  updateProfile,
  uploadAvatar,
} = require('../controllers/userController');

// All user routes are protected
router.use(auth);

router.get('/', getUsers);
router.get('/search', searchUsers);
router.put('/profile', updateProfile);
router.post('/avatar', upload.single('avatar'), uploadAvatar);

module.exports = router;
