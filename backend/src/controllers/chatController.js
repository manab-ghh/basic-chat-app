const Chat = require('../models/Chat');
const Message = require('../models/Message');
const User = require('../models/User');

// Get all chats for current user
const getChats = async (req, res, next) => {
  try {
    const userId = req.user._id;

    const chats = await Chat.find({
      participants: userId,
    })
      .populate('participants', 'name email avatar isOnline lastSeen')
      .populate({
        path: 'lastMessage',
        populate: {
          path: 'sender',
          select: 'name email avatar',
        },
      })
      .sort({ updatedAt: -1 });

    res.json({
      success: true,
      data: {
        chats,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Get or create a chat
const getOrCreateChat = async (req, res, next) => {
  try {
    const { userId } = req.body;
    const currentUserId = req.user._id;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID is required',
      });
    }

    // Check if user exists
    const otherUser = await User.findById(userId);
    if (!otherUser) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Check if chat already exists
    let chat = await Chat.findOne({
      participants: { $all: [currentUserId, userId] },
    })
      .populate('participants', 'name email avatar isOnline lastSeen')
      .populate({
        path: 'lastMessage',
        populate: {
          path: 'sender',
          select: 'name email avatar',
        },
      });

    if (!chat) {
      // Create new chat
      chat = await Chat.create({
        participants: [currentUserId, userId],
      });

      chat = await Chat.findById(chat._id)
        .populate('participants', 'name email avatar isOnline lastSeen')
        .populate({
          path: 'lastMessage',
          populate: {
            path: 'sender',
            select: 'name email avatar',
          },
        });
    }

    res.json({
      success: true,
      data: {
        chat,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Get messages for a chat with pagination
const getMessages = async (req, res, next) => {
  try {
    const { chatId } = req.params;
    const { page = 1, limit = 20 } = req.query;
    const userId = req.user._id;

    // Verify user is part of the chat
    const chat = await Chat.findOne({
      _id: chatId,
      participants: userId,
    });

    if (!chat) {
      return res.status(403).json({
        success: false,
        message: 'You are not a participant of this chat',
      });
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const messages = await Message.find({ chatId })
      .populate('sender', 'name email avatar')
      .populate('receiver', 'name email avatar')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const totalMessages = await Message.countDocuments({ chatId });

    res.json({
      success: true,
      data: {
        messages: messages.reverse(), // Return in chronological order
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalMessages / parseInt(limit)),
          totalMessages,
          hasMore: skip + messages.length < totalMessages,
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

// Send a new message (REST fallback)
const sendMessage = async (req, res, next) => {
  try {
    const { chatId, message, messageType = 'text' } = req.body;
    const receiverId = req.body.receiverId || req.body.receiver;
    const senderId = req.user._id;

    if (!message || !message.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Message content is required',
      });
    }

    let chat = await Chat.findById(chatId);
    if (!chat) {
      // Create new chat
      chat = await Chat.create({
        participants: [senderId, receiverId],
      });
    }

    const newMessage = await Message.create({
      chatId: chat._id,
      sender: senderId,
      receiver: receiverId,
      message: message.trim(),
      messageType,
    });

    chat.lastMessage = newMessage._id;
    chat.lastMessageAt = new Date();
    await chat.save();

    const populatedMessage = await Message.findById(newMessage._id)
      .populate('sender', 'name email avatar isOnline')
      .populate('receiver', 'name email avatar isOnline');

    res.status(201).json({
      success: true,
      data: {
        message: populatedMessage,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Mark messages as read (REST fallback)
const markAsRead = async (req, res, next) => {
  try {
    const { chatId } = req.params;
    const userId = req.user._id;

    const result = await Message.updateMany(
      {
        chatId,
        receiver: userId,
        isRead: false,
      },
      {
        isRead: true,
        readAt: new Date(),
      }
    );

    res.json({
      success: true,
      message: `${result.modifiedCount} messages marked as read`,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getChats,
  getOrCreateChat,
  getMessages,
  sendMessage,
  markAsRead,
};