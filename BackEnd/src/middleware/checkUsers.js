import { User } from "../../database/models/user.model.js"
import { AppError } from "../utils/AppError.js"

export const checkUsers = async (req, res, next) => {
    let users = await Promise.all(
        req.body.assignedTo.map(id => User.findById(id))
    )
    let userFilter = users.find((element) => element == null)

    if (userFilter !== undefined) return next(new AppError('one of the users is not exist', 404))
        
    next()
  
}