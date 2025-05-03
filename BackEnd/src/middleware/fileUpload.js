import multer from 'multer';
import { v4 as uuidv4 } from 'uuid';

const fileUpload = () => {
    const storage = multer.diskStorage({
        destination: function (req, file, cb) {
            cb(null, 'uploads')
        },
        filename: function (req, file, cb) {
            cb(null, uuidv4() + '_' + file.originalname);
        }
    });

    const fileFilter = (req, file, cb) => {
        const allowedMimeTypes = [
            'image/jpeg',
            'image/png',
            'image/gif',
            'application/pdf',
            'application/msword',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'application/vnd.ms-excel',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'text/plain'
        ];

        if (allowedMimeTypes.includes(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new Error('Invalid file type. Only images, documents, and text files are allowed.'), false);
        }
    };

    const upload = multer({ 
        storage, 
        fileFilter,
        limits: {
            fileSize: 5 * 1024 * 1024 // 5MB limit
        }
    });

    return upload;
};

export const uploadSingleFile = (fieldname) => fileUpload().single(fieldname);
export const uploadmixOfFiles = (arrayOfFields) => fileUpload().fields(arrayOfFields);
export const upload = fileUpload();