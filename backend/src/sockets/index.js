const { verifyToken } = require('../utils/jwt');
const User = require('../models/User');
const { handleSendMessage, handleTyping, handleMarkRead } = require('./events');

const toId = (value) => (value == null ? value : value.toString());

const socketHandler = (io) => {
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token;
      if (!token) {
        return next(new Error('Authentication required'));
      }

      const decoded = verifyToken(token);
      if (!decoded) {
        return next(new Error('Invalid token'));
      }

      const user = await User.findById(decoded.userId);
      if (!user) {
        return next(new Error('User not found'));
      }

      socket.userId = user._id;
      socket.user = user;
      next();
    } catch (error) {
      next(new Error('Authentication error'));
    }
  });

  io.on('connection', async (socket) => {
    const userId = toId(socket.userId);
    console.log(`User connected: ${userId}`);

    await User.findByIdAndUpdate(socket.userId, {
      isOnline: true,
      lastSeen: new Date(),
    });

    socket.broadcast.emit('user_online', {
      userId,
      isOnline: true,
    });

    socket.join(`user_${userId}`);

    socket.on('join_room', async (data) => {
      const chatId = data?.chatId;
      if (chatId) {
        socket.join(chatId);
        console.log(`User ${userId} joined room: ${chatId}`);
      }
    });

    socket.on('leave_room', (data) => {
      const chatId = data?.chatId;
      if (chatId) {
        socket.leave(chatId);
        console.log(`User ${userId} left room: ${chatId}`);
      }
    });

    socket.on('send_message', async (data, ack) => {
      await handleSendMessage(io, socket, data, ack);
    });

    socket.on('typing', async (data) => {
      await handleTyping(io, socket, data);
    });

    socket.on('stop_typing', async (data) => {
      await handleTyping(io, socket, { ...data, isTyping: false });
    });

    socket.on('mark_read', async (data) => {
      await handleMarkRead(io, socket, data);
    });

    socket.on('check_online_status', async (data) => {
      try {
        const targetUserId = data?.targetUserId;
        if (!targetUserId) return;
        const target = await User.findById(targetUserId).select('isOnline lastSeen');
        socket.emit('online_status', {
          userId: toId(targetUserId),
          isOnline: Boolean(target?.isOnline),
          lastSeen: target?.lastSeen || null,
        });
      } catch (error) {
        console.error('check_online_status error:', error);
      }
    });

    socket.on('disconnect', async () => {
      console.log(`User disconnected: ${userId}`);

      await User.findByIdAndUpdate(socket.userId, {
        isOnline: false,
        lastSeen: new Date(),
      });

      socket.broadcast.emit('user_offline', {
        userId,
        isOnline: false,
        lastSeen: new Date(),
      });
    });
  });
};

module.exports = socketHandler;
