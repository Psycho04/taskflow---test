import { model, Schema } from "mongoose";

// Schema for individual messages
const messageSchema = new Schema({
    sender: {
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    receiver: {
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    content: {
        type: String,
        required: true,
        maxlength: 1000
    },
    isRead: {
        type: Boolean,
        default: false
    },
    attachment: {
        type: {
            type: String,
            enum: ['image', 'file', 'document', 'other'],
        },
        url: String,
        filename: String,
        size: Number,
        mimeType: String
    },
    isDeleted: {
        type: Boolean,
        default: false
    },
    deletedBy: {
        type: Schema.Types.ObjectId,
        ref: 'User'
    }
}, {
    timestamps: true
});

// Schema for conversations between users
const conversationSchema = new Schema({
    participants: [{
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true
    }],
    lastMessage: {
        type: Schema.Types.ObjectId,
        ref: 'Message'
    },
    isDeleted: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true,
    versionKey: false
});

// Create indexes for better query performance
messageSchema.index({ sender: 1, receiver: 1 });
messageSchema.index({ createdAt: -1 });
conversationSchema.index({ participants: 1 });

// Static method to find or create a conversation between two users
conversationSchema.statics.findOrCreateConversation = async function(userId1, userId2) {
    // Sort IDs to ensure consistent query regardless of order
    const participants = [userId1, userId2].sort();
    
    // Try to find existing conversation
    let conversation = await this.findOne({
        participants: { $all: participants },
        isDeleted: false
    });
    
    // If no conversation exists, create a new one
    if (!conversation) {
        conversation = await this.create({
            participants,
            lastMessage: null
        });
    }
    
    return conversation;
};

export const Message = model('Message', messageSchema);
export const Conversation = model('Conversation', conversationSchema);
