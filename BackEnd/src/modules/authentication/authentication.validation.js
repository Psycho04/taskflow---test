import Joi from "joi";

export const signUpValidation = Joi.object({
    name: Joi.string().max(20).min(2).required(),
    email: Joi.string().email().required(),
    password: Joi.string().required(),
    rePassword: Joi.string().valid(Joi.ref('password')).required(),
    jobTitle: Joi.string(),
})
export const signInValidation = Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().required(),

})
export const changePasswordValidation = Joi.object({
    email: Joi.string().email().required(),
    oldPassword: Joi.string().required(),
    newPassword: Joi.string().required(),

})