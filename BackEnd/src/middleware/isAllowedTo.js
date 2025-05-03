import { AppError } from "../utils/AppError.js";

export const isAllowedTo = (...role) => {
  return (req, res, next) => {
    if (role[0] == req.user.role || role[1] == req.user.role) {
      next();
    } else {
      next(new AppError(`unauthorizedd`, 401));
    }
  };
};
