import Joi from "joi";

export const sendMessageValidation = Joi.object({
    receiverId: Joi.string().hex().length(24).required(),
    content: Joi.string().required().max(1000)
});

export const deleteMessagesValidation = Joi.object({
    messageIds: Joi.array().items(Joi.string().hex().length(24)).required()
});

export const getUserInboxValidation = Joi.object({
    id: Joi.string().hex().length(24).required()
});
