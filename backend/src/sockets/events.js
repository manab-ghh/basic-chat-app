const Message = require('../models/Message');
const Chat = require('../models/Chat');

const toPlain = (doc) => {
  if (!doc) return doc;
  if (typeof doc.toJSON === 'function') return doc.toJSON();
  if (typeof doc.toObject === 'function') return doc.toObject();
  return doc;
};

const toId = (value) => (value == null ? value : value.toString());

const handleSendMessage = async (io, socket, data, ack) => {
  try {
    const { chatId, message, messageType = 'text' } = data || {};
    const receiverId = data?.receiverId || data?.receiver;

    if (!message || !String(message).trim()) {
      const errorPayload = { success: false, message: 'Message content is required' };
      if (typeof ack === 'function') ack(errorPayload);
      socket.emit('error', errorPayload);
      return;
    }

    if (!receiverId) {
      const errorPayload = { success: false, message: 'Receiver ID is required' };
      if (typeof ack === 'function') ack(errorPayload);
      socket.emit('error', errorPayload);
      return;
    }

    let chat = chatId ? await Chat.findById(chatId) : null;
    if (!chat) {
      chat = await Chat.create({
        participants: [socket.userId, receiverId],
      });
    }

    const newMessage = await Message.create({
      chatId: chat._id,
      sender: socket.userId,
      receiver: receiverId,
      message: String(message).trim(),
      messageType,
      isRead: false,
      delivered: false,
    });

    const populatedMessage = await Message.findById(newMessage._id)
      .populate('sender', 'name email avatar isOnline')
      .populate('receiver', 'name email avatar isOnline');

    chat.lastMessage = newMessage._id;
    chat.lastMessageAt = new Date();
    await chat.save();

    const plainMessage = toPlain(populatedMessage);
    const successPayload = {
      success: true,
      data: plainMessage,
      chatId: toId(chat._id),
    };

    if (typeof ack === 'function') {
      ack(successPayload);
    }

    socket.emit('message_sent', successPayload);

    io.to(`user_${toId(receiverId)}`).emit('receive_message', successPayload);
    io.to(toId(chat._id)).emit('receive_message', successPayload);
  } catch (error) {
    console.error('Send message error:', error);
    const errorPayload = { success: false, message: 'Failed to send message' };
    if (typeof ack === 'function') ack(errorPayload);
    socket.emit('error', errorPayload);
  }
};

const handleTyping = async (io, socket, data) => {
  try {
    const receiverId = data?.receiverId || data?.receiver;
    const isTyping = data?.isTyping !== false;
    const chatId = data?.chatId;

    if (!receiverId) {
      return;
    }

    const payload = {
      userId: toId(socket.userId),
      isTyping,
      chatId: chatId ? toId(chatId) : chatId,
    };

    io.to(`user_${toId(receiverId)}`).emit('typing', payload);
    if (!isTyping) {
      io.to(`user_${toId(receiverId)}`).emit('stop_typing', payload);
    }
  } catch (error) {
    console.error('Typing indicator error:', error);
  }
};

const handleMarkRead = async (io, socket, data) => {
  try {
    const { chatId } = data || {};

    if (!chatId) {
      return;
    }

    const updateResult = await Message.updateMany(
      {
        chatId,
        receiver: socket.userId,
        isRead: false,
      },
      {
        isRead: true,
        readAt: new Date(),
      }
    );

    if (updateResult.modifiedCount > 0) {
      const payload = {
        chatId: toId(chatId),
        readBy: toId(socket.userId),
        userId: toId(socket.userId),
        readAt: new Date(),
      };
      io.to(toId(chatId)).emit('message_read', payload);
      io.to(toId(chatId)).emit('messages_read', payload);
    }
  } catch (error) {
    console.error('Mark read error:', error);
  }
};

module.exports = {
  handleSendMessage,
  handleTyping,
  handleMarkRead,
};
