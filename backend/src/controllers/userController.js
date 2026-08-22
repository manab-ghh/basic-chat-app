const User = require('../models/User');

const toPublicUser = (user) => ({
  _id: user._id,
  name: user.name,
  email: user.email,
  avatar: user.avatar,
  isOnline: user.isOnline,
  lastSeen: user.lastSeen,
});

// Get all users (except current user)
const getUsers = async (req, res, next) => {
  try {
    const currentUserId = req.user._id;

    const users = await User.find({
      _id: { $ne: currentUserId },
    })
      .select('name email avatar isOnline lastSeen')
      .sort({ name: 1 });

    res.json({
      success: true,
      data: {
        users,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Search users
const searchUsers = async (req, res, next) => {
  try {
    const { q } = req.query;
    const currentUserId = req.user._id;

    if (!q || q.trim().length < 2) {
      return res.json({
        success: true,
        data: {
          users: [],
        },
      });
    }

    const users = await User.find({
      _id: { $ne: currentUserId },
      $or: [
        { name: { $regex: q, $options: 'i' } },
        { email: { $regex: q, $options: 'i' } },
      ],
    })
      .select('name email avatar isOnline lastSeen')
      .limit(20);

    res.json({
      success: true,
      data: {
        users,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Update user profile
const updateProfile = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const { name, avatar } = req.body;

    const updateData = {};
    if (name) updateData.name = name;
    if (avatar) updateData.avatar = avatar;

    const user = await User.findByIdAndUpdate(userId, updateData, {
      new: true,
      runValidators: true,
    }).select('name email avatar isOnline lastSeen');

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        user,
      },
    });
  } catch (error) {
    next(error);
  }
};

const uploadAvatar = async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Avatar image is required',
      });
    }

    const avatarUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;
    const user = await User.findByIdAndUpdate(
      req.user._id,
      { avatar: avatarUrl },
      { new: true, runValidators: true }
    ).select('name email avatar isOnline lastSeen');

    res.json({
      success: true,
      message: 'Avatar updated successfully',
      data: {
        user: toPublicUser(user),
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getUsers,
  searchUsers,
  updateProfile,
  uploadAvatar,
};
