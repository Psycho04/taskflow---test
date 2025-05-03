import mongoose from "mongoose";
import { AppError } from "../src/utils/AppError.js";

export const dbConnection = () => {
    mongoose.connect('mongodb://localhost:27017/TaskManagement')
        .then(() => console.log('Database is connected successfully'))
        .catch((err) => {
            console.error('Database connection error:', err);
            process.exit(1); // Exit the process if database connection fails
        });

    // Handle database connection errors
    mongoose.connection.on('error', (err) => {
        console.error('MongoDB connection error:', err);
    });

    // Handle database disconnection
    mongoose.connection.on('disconnected', () => {
        console.log('MongoDB disconnected. Attempting to reconnect...');
    });
}
