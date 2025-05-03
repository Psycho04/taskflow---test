import { User } from "../../../database/models/user.model.js"
import jwt from 'jsonwebtoken'
import { AppError } from "../../utils/AppError.js"
import bcrypt from 'bcrypt'
import { catchError } from "../../utils/catchError.js"

export const signUp = catchError(async (req, res, next) => {
    let user = User(req.body)
    let token = jwt.sign({ userId: user._id, role: user.role }, process.env.SECRET_KEY)
    await user.save()
    res.json({ message: "added", user, token })
}
)
export const signIn = catchError(async (req, res, next) => {
    let user = await User.findOne({ email: req.body.email })



    if (user && bcrypt.compareSync(req.body.password, user.password)) {
        let token = jwt.sign({ userId: user._id, role: user.role }, process.env.SECRET_KEY)
        console.log(token);
        res.json({ message: "success", user, token })
    } else {
        next(new AppError('email or password is not correct', 404))
    }


})
export const addImage = catchError(async (req, res, next) => {

    console.log(req.file)
    let user = await User.findByIdAndUpdate(req.user._id, { image: req.file.filename }, { new: true })
    res.json({ message: "success", user })
})





