import { Router } from "express";
import { 
    getUserChats,
    initializeChatbot, 
    updateChatName,
    deleteChat,
    sendMessage, 
    getChatHistory, 
    clearChatHistory 
} from "./chatbot.controller.js";
import { protectedRoute } from "../../middleware/protectedRoute.js";
import { isAllowedTo } from "../../middleware/isAllowedTo.js";
import { validate } from "../../middleware/validation.js";
import Joi from "joi";

const sendMessageValidation = Joi.object({
    message: Joi.string().required(),
    chatId: Joi.string().required()
});

const initializeChatValidation = Joi.object({
    name: Joi.string().optional()
});

const updateChatNameValidation = Joi.object({
    name: Joi.string().required()
});

export const chatbotRouter = Router();

// Get all user's chats
chatbotRouter.get('/', 
    protectedRoute, 
    isAllowedTo('user', 'admin'), 
    getUserChats
);

// Initialize new chat
chatbotRouter.post('/', 
    protectedRoute, 
    isAllowedTo('user', 'admin'), 
    validate(initializeChatValidation), 
    initializeChatbot
);

// Update chat name
chatbotRouter.patch('/:chatId', 
    protectedRoute, 
    isAllowedTo('user', 'admin'), 
    validate(updateChatNameValidation), 
    updateChatName
);

// Delete chat
chatbotRouter.delete('/:chatId', 
    protectedRoute, 
    isAllowedTo('user', 'admin'), 
    deleteChat
);

// Send message to specific chat
chatbotRouter.post('/:chatId/message', 
    protectedRoute, 
    isAllowedTo('user', 'admin'), 
    validate(sendMessageValidation), 
    sendMessage
);

// Get chat history for specific chat
chatbotRouter.get('/:chatId/history', 
    protectedRoute, 
    isAllowedTo('user', 'admin'), 
    getChatHistory
);

// Clear chat history for specific chat
chatbotRouter.delete('/:chatId/history', 
    protectedRoute, 
    isAllowedTo('user', 'admin'), 
    clearChatHistory
); 