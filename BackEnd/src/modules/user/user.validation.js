import Joi from "joi";

export const addUserValidation = Joi.object({
    name: Joi.string().max(20).min(2).required(),
    email: Joi.string().email().required(),
    password: Joi.string().required(),
    rePassword: Joi.string().valid(Joi.ref('password')).required(),
    role: Joi.string().valid('user', 'admin')
})
export const getAndDeleteUserValidation = Joi.object({
    id: Joi.string().hex().length(24).required()


})
export const getUsersValidation = Joi.object({
    role: Joi.string()

})

export const updateUserValidation = Joi.object({
    name: Joi.string().min(3).max(50).optional(),
    jobTitle: Joi.string().min(2).max(50).optional()
});