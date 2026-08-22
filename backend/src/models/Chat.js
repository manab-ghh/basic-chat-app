const mongoose = require('mongoose');

const chatSchema = new mongoose.Schema(
  {
    participants: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
      },
    ],
    lastMessage: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Message',
      default: null,
    },
    lastMessageAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

// Ensure participants are unique and sorted.
// Mongoose 9 document middleware no longer receives `next`.
chatSchema.pre('save', function () {
  if (this.participants) {
    this.participants = [...new Set(this.participants.map((p) => p.toString()))];
    if (this.participants.length === 2) {
      this.participants.sort();
    }
  }
});

// Indexes
chatSchema.index({ participants: 1 });
chatSchema.index({ updatedAt: -1 });

const Chat = mongoose.model('Chat', chatSchema);

module.exports = Chat;