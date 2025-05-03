import { model, Schema } from "mongoose";

const chatMessageSchema = new Schema({
    role: {
        type: String,
        enum: ['user', 'assistant'],
        required: true
    },
    content: {
        type: String,
        required: true
    },
    timestamp: {
        type: Date,
        default: Date.now
    }
});

const chatbotSchema = new Schema({
    user: {
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },
    name: {
        type: String,
        required: true,
        default: "New Chat"
    },
    chatHistory: [chatMessageSchema],
    lastActive: {
        type: Date,
        default: Date.now
    },
    settings: {
        model: {
            type: String,
            default: 'deepseek/deepseek-r1:free'
        },
        language: {
            type: String,
            default: 'ar'
        }
    }
}, {
    timestamps: true,
    versionKey: false
});

chatbotSchema.index({ user: 1, name: 1 }, { unique: true });

export const Chatbot = model('Chatbot', chatbotSchema); 