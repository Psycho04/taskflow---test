import { Message, Conversation } from "../../../database/models/inbox.model.js";
import { User } from "../../../database/models/user.model.js";
import { Notifications } from "../../../database/models/notification.model.js";
import { catchError } from "../../utils/catchError.js";
import { AppError } from "../../utils/AppError.js";

// Get all users who have sent messages to the current user
export const getInboxSenders = catchError(async (req, res, next) => {
    const userId = req.user._id;

    // Find all messages where the current user is the receiver
    const messages = await Message.find({
        receiver: userId,
        isDeleted: false
    })
    .sort({ createdAt: -1 })
    .populate('sender', 'name email image jobTitle');

    // Extract unique senders
    const senders = {};
    messages.forEach(message => {
        const senderId = message.sender._id.toString();
        if (!senders[senderId]) {
            senders[senderId] = {
                _id: senderId,
                name: message.sender.name,
                email: message.sender.email,
                image: message.sender.image,
                jobTitle: message.sender.jobTitle,
                lastMessage: {
                    content: message.content,
                    createdAt: message.createdAt,
                    isRead: message.isRead
                }
            };
        }
    });

    res.json({
        message: "success",
        senders: Object.values(senders)
    });
});

// Get user inbox (all messages between current user and another user)
export const getUserInbox = catchError(async (req, res, next) => {
    const currentUserId = req.user._id;
    const otherUserId = req.params.id;

    // Validate other user exists
    const otherUser = await User.findById(otherUserId);
    if (!otherUser) {
        return next(new AppError('User not found', 404));
    }

    // Find all messages between the two users
    const messages = await Message.find({
        $or: [
            { sender: currentUserId, receiver: otherUserId, isDeleted: false },
            { sender: otherUserId, receiver: currentUserId, isDeleted: false }
        ]
    })
    .sort({ createdAt: 1 })
    .populate('sender', 'name email image')
    .populate('receiver', 'name email image');

    // Mark all unread messages as read
    await Message.updateMany(
        {
            sender: otherUserId,
            receiver: currentUserId,
            isRead: false
        },
        { isRead: true }
    );

    res.json({
        message: "success",
        messages,
        otherUser: {
            _id: otherUser._id,
            name: otherUser.name,
            email: otherUser.email,
            image: otherUser.image,
            jobTitle: otherUser.jobTitle
        }
    });
});

// Send a new message
export const sendMessage = catchError(async (req, res, next) => {
    const senderId = req.user._id;
    const { receiverId, content } = req.body;

    // Validate receiver exists
    const receiver = await User.findById(receiverId);
    if (!receiver) {
        return next(new AppError('Receiver not found', 404));
    }

    // Create the message
    const message = await Message.create({
        sender: senderId,
        receiver: receiverId,
        content
    });

    // Find or create conversation
    const conversation = await Conversation.findOrCreateConversation(senderId, receiverId);

    // Update last message in conversation
    conversation.lastMessage = message._id;
    await conversation.save();

    // Populate sender and receiver info
    await message.populate('sender', 'name email image');
    await message.populate('receiver', 'name email image');

    // Create a notification for the receiver (both admin and regular users)
    const notification = {
        assignedTo: [receiverId],
        message: `New message from ${message.sender.name}`,
        type: 'message_received',
        relatedMessage: message._id,
        createdBy: senderId
    };

    await Notifications.create(notification);

    res.status(201).json({
        message: "Message sent successfully",
        data: message
    });
});

// Delete specific messages
export const deleteMessages = catchError(async (req, res, next) => {
    const userId = req.user._id;
    const { messageIds } = req.body;

    if (!messageIds || !Array.isArray(messageIds) || messageIds.length === 0) {
        return next(new AppError('Please provide message IDs to delete', 400));
    }

    // Mark messages as deleted
    const result = await Message.updateMany(
        {
            _id: { $in: messageIds },
            $or: [{ sender: userId }, { receiver: userId }]
        },
        {
            isDeleted: true,
            deletedBy: userId
        }
    );

    if (result.modifiedCount === 0) {
        return next(new AppError('No messages were deleted', 404));
    }

    res.json({
        message: "Messages deleted successfully",
        count: result.modifiedCount
    });
});

// Delete all messages for a user
export const deleteAllUserMessages = catchError(async (req, res, next) => {
    const userId = req.user._id;

    // Mark all messages as deleted where user is sender or receiver
    const result = await Message.updateMany(
        {
            $or: [{ sender: userId }, { receiver: userId }],
            isDeleted: false
        },
        {
            isDeleted: true,
            deletedBy: userId
        }
    );

    res.json({
        message: "All messages deleted successfully",
        count: result.modifiedCount
    });
});
