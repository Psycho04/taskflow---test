import { AppError } from "../../utils/AppError.js";

export const validateMessage = (req, res, next) => {
    const { content } = req.body;
    
    // Check if either content or file is present
    if (!content && !req.file) {
        return next(new AppError("Message must have either content or file attachment", 400));
    }

    // Validate content length if present
    if (content && content.length > 1000) {
        return next(new AppError("Message content cannot exceed 1000 characters", 400));
    }

    // Validate file if present
    if (req.file) {
        const maxFileSize = 5 * 1024 * 1024; // 5MB
        if (req.file.size > maxFileSize) {
            return next(new AppError("File size cannot exceed 5MB", 400));
        }

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

        if (!allowedMimeTypes.includes(req.file.mimetype)) {
            return next(new AppError("Invalid file type. Only images, documents, and text files are allowed.", 400));
        }
    }

    next();
};

export const validateMessageUpdate = (req, res, next) => {
    const { content } = req.body;
    
    if (!content) {
        return next(new AppError("Message content is required for update", 400));
    }

    if (content.length > 1000) {
        return next(new AppError("Message content cannot exceed 1000 characters", 400));
    }

    next();
};