import { User } from "../../database/models/user.model.js";
import { AppError } from "../utils/AppError.js";
import jwt from "jsonwebtoken";
import { catchError } from "../utils/catchError.js";

export const protectedRoute = catchError(async (req, res, next) => {
  // Check both Authorization header and token header
  let token = req.headers.authorization?.split(" ")[1] || req.headers.token;

  if (!token) return next(new AppError("token is unsend", 401));

  let userPayLoad = null;
  try {
    userPayLoad = jwt.verify(token, process.env.SECRET_KEY);
  } catch (err) {
    return next(new AppError("invalid token", 401));
  }

  let user = await User.findById(userPayLoad.userId);
  if (!user) return next(new AppError("user is not found", 401));

  let time = parseInt(user.passwordChangedAt?.getTime() / 1000);
  if (time > userPayLoad.iat) return next(new AppError("unauthorized", 401));

  req.user = user;
  next();
});
