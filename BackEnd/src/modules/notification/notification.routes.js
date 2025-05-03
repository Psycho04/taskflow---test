import { Router } from "express";
import { addNotification, getUserNotification, deleteNotification, getSingleNotification } from "./notification.controller.js";
import { protectedRoute } from "../../middleware/protectedRoute.js";
import { isAllowedTo } from "../../middleware/isAllowedTo.js";
import { checkUsers } from "../../middleware/checkUsers.js";
import { validate } from "../../middleware/validation.js";
import { addNotifyValidation, getUserNotificationValidation, getSingleNotificationValidation } from "./notification.validation.js";

export const notificationRouter = Router()

// Route for adding notifications (admin only)
notificationRouter.route('/')
    .post(protectedRoute, isAllowedTo('admin'), validate(addNotifyValidation), checkUsers, addNotification)

// Route for getting a single notification by its ID and marking it as read
notificationRouter.route('/single/:id')
    .get(
        protectedRoute,
        isAllowedTo('user', 'admin'),
        validate(getSingleNotificationValidation, 'params'),
        getSingleNotification
    )

// Route for user-specific operations (get all user notifications, delete a notification)
notificationRouter.route('/:id')
    .get(
        protectedRoute,
        isAllowedTo('user', 'admin'),
        validate(getUserNotificationValidation, 'params'), // tell it to validate `params`
        getUserNotification
    )

    .delete(protectedRoute, isAllowedTo('user', 'admin'), deleteNotification)