import { Router } from "express";
import { checkEmail } from "../../middleware/checkEmail.js";
import * as authCruds from "./authentication.controller.js";
import * as authValidation from "./authentication.validation.js";
import { validate } from "../../middleware/validation.js";
import { uploadSingleFile } from "../../middleware/fileUpload.js";
import { protectedRoute } from "../../middleware/protectedRoute.js";
import { changePassword } from "../../middleware/changePassword.js";

export const authRouter = Router();


authRouter.route('/signup').post(validate(authValidation.signUpValidation), checkEmail, authCruds.signUp);
authRouter.route('/signin').post(validate(authValidation.signInValidation), authCruds.signIn);
authRouter.route('/changePassword').patch(changePassword);
authRouter.route('/profilePhoto').put(protectedRoute, uploadSingleFile('image'), authCruds.addImage);



