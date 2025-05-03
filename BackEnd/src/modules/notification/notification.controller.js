import { Notifications } from "../../../database/models/notification.model.js";
import { catchError } from "../../utils/catchError.js";
import { Task } from "../../../database/models/task.model.js"
import { AppError } from "../../utils/AppError.js";


export const addNotification = catchError(async (req, res, next) => {
    req.body.createdBy = req.user._id
    let task = await Task.findById(req.body.relatedTask)
    if (!task) return next(new AppError('task not found', 500))
    let notification = await Notifications.create(req.body)
    res.json({ message: "success", notification })
})

export const getUserNotification = catchError(async (req, res, next) => {
    let userNotification = await Notifications.find({ assignedTo: req.params.id })
        .populate('relatedTask')
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
    // Find the notification, update its isRead status to true, and populate the related task
    const notification = await Notifications.findByIdAndUpdate(
        id, 
        { isRead: true }, 
        { new: true }
    ).populate('relatedTask')
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