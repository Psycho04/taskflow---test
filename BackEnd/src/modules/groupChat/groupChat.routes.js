import express from "express";
import {
  getGroupChat,
  sendMessage,
  updateMessage,
  deleteMessage,
  togglePinMessage,
  toggleMessagePermission,
} from "./groupChat.controller.js";
import { protectedRoute } from "../../middleware/protectedRoute.js";
import { upload } from "../../utils/multer.js";
import {
  validateMessage,
  validateMessageUpdate,
} from "./groupChat.validation.js";

const router = express.Router();

// Apply authentication middleware to all routes
router.use(protectedRoute);

// Get the group chat
router.get("/", getGroupChat);

// Message routes
router.post(
  "/messages",
  upload.single("attachment"),
  validateMessage,
  sendMessage
);

router.patch("/messages/:messageId", validateMessageUpdate, updateMessage);

router.delete("/messages/:messageId", deleteMessage);

// Admin only routes
router.patch("/messages/:messageId/pin", togglePinMessage);
router.patch("/toggle-messages", toggleMessagePermission);

export default router;
