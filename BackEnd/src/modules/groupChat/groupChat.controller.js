import { GroupChat } from "../../../database/models/groupChat.model.js";
import { catchError } from "../../utils/catchError.js";
import { AppError } from "../../utils/AppError.js";

// Get the group chat
export const getGroupChat = catchError(async (req, res, next) => {
  const groupChat = await GroupChat.getOrCreateGroupChat();

  // Populate the messages after getting the group chat
  await groupChat.populate("messages.sender", "name email image");
  await groupChat.populate("messages.readBy", "name email image");

  // Filter out deleted messages for non-admin users
  if (req.user.role !== "admin") {
    groupChat.messages = groupChat.messages.filter(
      (message) => !message.isDeleted
    );
  }

  res.status(200).json({
    status: "success",
    data: groupChat,
  });
});

// Send a message
export const sendMessage = catchError(async (req, res, next) => {
  const { content } = req.body;
  const groupChat = await GroupChat.getOrCreateGroupChat();

  // Check if messaging is allowed or if user is admin
  if (!groupChat.isMessageAllowed && req.user.role !== "admin") {
    return next(
      new AppError("Messaging is currently disabled in this group chat", 403)
    );
  }

  const message = {
    sender: req.user._id,
    content,
    timestamp: new Date(),
  };

  // Handle file attachment if present
  if (req.file) {
    message.attachment = {
      type: req.file.mimetype.startsWith("image/") ? "image" : "file",
      url: req.file.path,
      filename: req.file.originalname,
      size: req.file.size,
      mimeType: req.file.mimetype,
    };
  }

  groupChat.messages.push(message);
  await groupChat.save();

  res.status(201).json({
    status: "success",
    data: {
      message,
    },
  });
});

// Update a message
export const updateMessage = catchError(async (req, res, next) => {
  const { messageId } = req.params;
  const { content } = req.body;
  const userId = req.user._id;

  const groupChat = await GroupChat.getOrCreateGroupChat();
  const message = groupChat.messages.id(messageId);

  if (!message) {
    return next(new AppError("Message not found", 404));
  }

  // Check if user can update the message
  if (
    message.sender.toString() !== userId.toString() &&
    req.user.role !== "admin"
  ) {
    return next(new AppError("You can only update your own messages", 403));
  }

  message.content = content;
  message.lastEdited = new Date();
  await groupChat.save();

  res.status(200).json({
    status: "success",
    data: message,
  });
});

// Delete a message
export const deleteMessage = catchError(async (req, res, next) => {
  const { messageId } = req.params;
  const userId = req.user._id;

  const groupChat = await GroupChat.getOrCreateGroupChat();
  const messageIndex = groupChat.messages.findIndex(
    (msg) => msg._id.toString() === messageId
  );

  if (messageIndex === -1) {
    return next(new AppError("Message not found", 404));
  }

  const message = groupChat.messages[messageIndex];

  // Check if user can delete the message
  if (
    message.sender.toString() !== userId.toString() &&
    req.user.role !== "admin"
  ) {
    return next(new AppError("You can only delete your own messages", 403));
  }

  // Remove the message from the array
  groupChat.messages.splice(messageIndex, 1);
  await groupChat.save();

  res.status(200).json({
    status: "success",
    message: "Message deleted successfully",
  });
});

// Pin/Unpin a message (admin only)
export const togglePinMessage = catchError(async (req, res, next) => {
  const { messageId } = req.params;

  if (req.user.role !== "admin") {
    return next(new AppError("Only admins can pin messages", 403));
  }

  const groupChat = await GroupChat.getOrCreateGroupChat();
  const message = groupChat.messages.id(messageId);

  if (!message) {
    return next(new AppError("Message not found", 404));
  }

  // Toggle the pin status
  message.isPinned = !message.isPinned;
  await groupChat.save();

  res.status(200).json({
    status: "success",
    message: `Message ${message.isPinned ? "pinned" : "unpinned"} successfully`,
    data: {
      message,
    },
  });
});

// Toggle message sending permission (admin only)
export const toggleMessagePermission = catchError(async (req, res, next) => {
  if (req.user.role !== "admin") {
    return next(
      new AppError("Only admins can control message permissions", 403)
    );
  }

  const groupChat = await GroupChat.getOrCreateGroupChat();
  groupChat.isMessageAllowed = !groupChat.isMessageAllowed;
  await groupChat.save();

  res.status(200).json({
    status: "success",
    message: `Messaging is now ${
      groupChat.isMessageAllowed ? "allowed" : "disabled"
    }`,
    data: {
      isMessageAllowed: groupChat.isMessageAllowed,
    },
  });
});
