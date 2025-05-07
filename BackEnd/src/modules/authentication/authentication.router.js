import { Router } from 'express';
import { signIn, signUp, addImage, updateProfilePhoto } from './authentication.controller.js';
import { protectedRoute } from '../../middleware/protectedRoute.js';
import { upload } from '../../utils/multer.js';

const router = Router();

// Add the new endpoint before the file upload endpoint
router.post('/profilePhoto', protectedRoute, updateProfilePhoto, addImage);

// Other routes...

export default router;