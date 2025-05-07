import { Router } from "express";
import {
    getInboxSenders,
    getUserInbox,
    sendMessage,
    deleteMessages,
    deleteAllUserMessages
} from "./inbox.controller.js";
import { protectedRoute } from "../../middleware/protectedRoute.js";
import { isAllowedTo } from "../../middleware/isAllowedTo.js";
import { validate } from "../../middleware/validation.js";
import { 
    sendMessageValidation, 
    deleteMessagesValidation,
    getUserInboxValidation
} from "./inbox.validation.js";

export const inboxRouter = Router();

// Apply authentication middleware to all routes
inboxRouter.use(protectedRoute);

// Get all users who have sent messages to the current user
inboxRouter.get(
    "/senders",
    isAllowedTo("user", "admin"),
    getInboxSenders
);

// Get all messages between current user and another user
inboxRouter.get(
    "/user/:id",
    isAllowedTo("user", "admin"),
    validate(getUserInboxValidation, 'params'),
    getUserInbox
);

// Send a new message
inboxRouter.post(
    "/",
    isAllowedTo("user", "admin"),
    validate(sendMessageValidation),
    sendMessage
);

// Delete specific messages
inboxRouter.delete(
    "/",
    isAllowedTo("user", "admin"),
    validate(deleteMessagesValidation),
    deleteMessages
);

// Delete all messages for a user
inboxRouter.delete(
    "/all/:id",
    isAllowedTo("user", "admin"),
    deleteAllUserMessages
);
