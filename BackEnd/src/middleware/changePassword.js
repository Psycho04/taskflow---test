import { User } from "../../database/models/user.model.js"
import { AppError } from "../utils/AppError.js"
import bcrypt from 'bcrypt'
import { catchError } from "../utils/catchError.js"

export const changePassword = catchError(async (req, res, next) => {
    let user = await User.findOne({ email: req.body.email })

    if (user && bcrypt.compareSync(req.body.oldPassword, user.password)) {
        let updatedUser = await User.findOneAndUpdate({ email: req.body.email }, { password: bcrypt.hashSync(req.body.oldPassword, 8), passwordChangedAt: Date.now() }, { new: true })
        res.json({ message: "password has been changed", updatedUser })
    } else {
        next(new AppError('email or password are not correct', 401))
    }
})