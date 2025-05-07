import { Notifications } from "../../../database/models/notification.model.js";
import { catchError } from "../../utils/catchError.js";
import { Task } from "../../../database/models/task.model.js";
import { Message } from "../../../database/models/inbox.model.js";
import { AppError } from "../../utils/AppError.js";


export const addNotification = catchError(async (req, res, next) => {
    req.body.createdBy = req.user._id

    // Check if this is a task-related or message-related notification
    if (req.body.relatedTask) {
        let task = await Task.findById(req.body.relatedTask)
        if (!task) return next(new AppError('task not found', 500))
    } else if (req.body.relatedMessage) {
        let message = await Message.findById(req.body.relatedMessage)
        if (!message) return next(new AppError('message not found', 500))
    }

    let notification = await Notifications.create(req.body)
    res.json({ message: "success", notification })
})

export const getUserNotification = catchError(async (req, res, next) => {
    let userNotification = await Notifications.find({ assignedTo: req.params.id })
        .populate('relatedTask')
        .populate('relatedMessage')
        .populate('createdBy', 'name email image')
        .sort({ createdAt: -1 });

    // Return empty array if no notifications found
    res.json({ message: "success", userNotification: userNotification || [] })
})

export const deleteNotification = catchError(async (req, res, next) => {
    const { id } = req.params;
    const notification = await Notifications.findByIdAndDelete(id);

    if (!notification) {
        return next(new AppError('Notification not found', 404));
    }

    res.json({ message: "Notification deleted successfully" });
})

export const getSingleNotification = catchError(async (req, res, next) => {
    const { id } = req.params;
    // Find the notification, update its isRead status to true, and populate the related task/message
    const notification = await Notifications.findByIdAndUpdate(
        id,
        { isRead: true },
        { new: true }
    ).populate('relatedTask')
     .populate('relatedMessage')
     .populate('createdBy', 'name email image');

    if (!notification) {
        return next(new AppError('Notification not found', 404));
    }

    // Ensure the user requesting is assigned to this notification (optional security check)
    // if (!notification.assignedTo.includes(req.user._id) && req.user.role !== 'admin') {
    //     return next(new AppError('Not authorized to view this notification', 403));
    // }

    res.json({ message: "success", notification });
})

export const deleteAllUserNotifications = catchError(async (req, res, next) => {
    const { userId } = req.params;

    // Ensure the user can only delete their own notifications
    if (userId !== req.user._id.toString() && req.user.role !== 'admin') {
        return next(new AppError('You are not authorized to delete these notifications', 403));
    }

    // Delete all notifications assigned to this user
    const result = await Notifications.deleteMany({ assignedTo: userId });

    res.json({
        message: "All notifications deleted successfully",
        count: result.deletedCount
    });
})