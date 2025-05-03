import { Chatbot } from "../../../database/models/chatbot.model.js";
import { Task } from "../../../database/models/task.model.js";
import { catchError } from "../../utils/catchError.js";
import { AppError } from "../../utils/AppError.js";
import axios from "axios";

const OPENROUTER_API_KEY = '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';

// Helper function to get user's tasks
const getUserTasks = async (userId) => {
    const tasks = await Task.find({ 
        assignedTo: userId,
        status: { $ne: 'completed' }
    }).sort({ dueDate: 1 });
    
    return tasks.map(task => ({
        title: task.title,
        description: task.description,
        dueDate: task.dueDate,
        priority: task.priority,
        status: task.status
    }));
};

// Get all chats for a user
export const getUserChats = catchError(async (req, res, next) => {
    const userId = req.user._id;
    
    const chats = await Chatbot.find({ user: userId })
        .sort({ lastActive: -1 });
    
    res.json({ message: "success", chats });
});

// Initialize a new chat
export const initializeChatbot = catchError(async (req, res, next) => {
    const userId = req.user._id;
    const { name } = req.body;
    
    const chatbot = await Chatbot.create({
        user: userId,
        name: name || "New Chat",
        chatHistory: []
    });
    
    res.status(201).json({ message: "success", chatbot });
});

// Update chat name
export const updateChatName = catchError(async (req, res, next) => {
    const { chatId } = req.params;
    const { name } = req.body;
    const userId = req.user._id;

    if (!name) {
        return next(new AppError('Chat name is required', 400));
    }

    const chatbot = await Chatbot.findOne({ _id: chatId, user: userId });
    if (!chatbot) {
        return next(new AppError('Chat not found', 404));
    }

    chatbot.name = name;
    await chatbot.save();

    res.json({ message: "success", chatbot });
});

// Delete a chat
export const deleteChat = catchError(async (req, res, next) => {
    const { chatId } = req.params;
    const userId = req.user._id;

    const chatbot = await Chatbot.findOne({ _id: chatId, user: userId });
    if (!chatbot) {
        return next(new AppError('Chat not found', 404));
    }

    await Chatbot.findByIdAndDelete(chatId);

    res.json({ message: "Chat deleted successfully" });
});

// Modified sendMessage to work with specific chat
export const sendMessage = catchError(async (req, res, next) => {
    const { message, chatId } = req.body;
    const userId = req.user._id;

    if (!message) {
        return next(new AppError('Message is required', 400));
    }

    let chatbot = await Chatbot.findOne({ _id: chatId, user: userId });
    if (!chatbot) {
        return next(new AppError('Chat not found', 404));
    }

    // Get user's tasks
    const userTasks = await getUserTasks(userId);
    
    // Add user message to chat history with timestamp
    const userMessage = {
        role: 'user',
        content: message,
        timestamp: new Date()
    };
    chatbot.chatHistory.push(userMessage);

    // Call OpenRouter API with task context
    try {
        const systemMessage = {
            role: 'system',
            content: `You are a helpful task management assistant. The user has the following tasks:
${userTasks.map(task => `
- ${task.title}
  Description: ${task.description}
  Due Date: ${task.dueDate}
  Priority: ${task.priority}
  Status: ${task.status}
`).join('\n')}

Please help the user manage their tasks effectively.`
        };

        const response = await axios.post('https://openrouter.ai/api/v1/chat/completions', {
            model: chatbot.settings.model,
            messages: [
                systemMessage,
                ...chatbot.chatHistory.map(msg => ({
                    role: msg.role,
                    content: msg.content
                }))
            ]
        }, {
            headers: {
                'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
                'X-Title': 'TaskMate',
                'Content-Type': 'application/json'
            }
        });

        const assistantMessage = response.data.choices[0].message.content;

        // Add assistant message to chat history with timestamp
        const assistantResponse = {
            role: 'assistant',
            content: assistantMessage,
            timestamp: new Date()
        };
        chatbot.chatHistory.push(assistantResponse);

        // Update last active time and save
        chatbot.lastActive = new Date();
        await chatbot.save();

        res.json({ 
            message: "success", 
            response: assistantMessage,
            chatHistory: chatbot.chatHistory
        });
    } catch (error) {
        // Remove the user message if API call fails
        chatbot.chatHistory.pop();
        await chatbot.save();
        return next(new AppError('Error communicating with chatbot', 500));
    }
});

// Modified getChatHistory to work with specific chat
export const getChatHistory = catchError(async (req, res, next) => {
    const { chatId } = req.params;
    const userId = req.user._id;
    
    const chatbot = await Chatbot.findOne({ _id: chatId, user: userId });
    if (!chatbot) {
        return next(new AppError('Chat not found', 404));
    }
    
    res.json({ 
        message: "success", 
        chatHistory: chatbot.chatHistory 
    });
});

// Modified clearChatHistory to work with specific chat
export const clearChatHistory = catchError(async (req, res, next) => {
    const { chatId } = req.params;
    const userId = req.user._id;
    
    const chatbot = await Chatbot.findOne({ _id: chatId, user: userId });
    if (!chatbot) {
        return next(new AppError('Chat not found', 404));
    }
    
    chatbot.chatHistory = [];
    await chatbot.save();
    
    res.json({ message: "Chat history cleared successfully" });
}); 