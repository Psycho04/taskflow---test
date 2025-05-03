import { AppError } from "../utils/AppError.js";

export const validate = (schema, location = 'body') => {
    return (req, res, next) => {
        let dataToValidate = req[location]; // dynamic: req.body, req.params, req.query
        let { error } = schema.validate(dataToValidate);
        if (!error) return next();
        next(new AppError(error.message, 400));
    }
}
