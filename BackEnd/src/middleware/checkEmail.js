import { User } from "../../database/models/user.model.js"
import { AppError } from "../utils/AppError.js"
import { catchError } from "../utils/catchError.js"

export const checkEmail = catchError(async (req, res, next) => {
    let user = await User.findOne({ email: req.body.email })
    if (user) return next(new AppError('this email is already exist', 404))
    next()
})