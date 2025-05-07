import Joi from "joi";

export const addNotifyValidation = Joi.object({
    assignedTo: Joi.array().items(Joi.string().hex().length(24)).required(),
    message: Joi.string().max(100).min(2).required(),
    type: Joi.string().valid('task_created', 'task_updated', 'task_due', 'task_trashed', 'task_restored', 'task_deleted', 'general', 'message_received'),
    relatedTask: Joi.string().hex().length(24),
    relatedMessage: Joi.string().hex().length(24)
})

export const getUserNotificationValidation = Joi.object({
    id: Joi.string().hex().length(24).required(),
})

export const getSingleNotificationValidation = Joi.object({
    id: Joi.string().required()
});