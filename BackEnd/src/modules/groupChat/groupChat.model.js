import mongoose from "mongoose";

const messageSchema = new mongoose.Schema({
  content: {
    type: String,
    maxlength: 1000,
  },
  sender: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  attachment: {
    type: String,
  },
  isPinned: {
    type: Boolean,
    default: false,
  },
  isDeleted: {
    type: Boolean,
    default: false,
  },
  deletedAt: {
    type: Date,
  },
  deletedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },
});

const groupChatSchema = new mongoose.Schema({
  messages: [messageSchema],
  isMessagesEnabled: {
    type: Boolean,
    default: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },
});

// Update the updatedAt field before saving
groupChatSchema.pre("save", function (next) {
  this.updatedAt = Date.now();
  next();
});

export const GroupChat = mongoose.model("GroupChat", groupChatSchema); 