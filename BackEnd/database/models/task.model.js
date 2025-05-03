import { model, Schema, Types } from "mongoose";

const taskSchema = new Schema(
    {
        title: {
            type: String,
            required: true,
        },
        description: {
            type: String,
            required: true,
        },
        dueDate: {
            type: Date,
            required: true,
        },
        priority: {
            type: String,
            default: "medium",
            enum: ["high", "medium", "low"],
        },
        status: {
            type: String,
            enum: ['to do', 'in progress', 'completed'],
            default: 'to do',
        },
        assignedTo: {
            type: [Types.ObjectId],
            ref: 'User',
            required: true, // Only admins can assign tasks to users
        },
        createdBy: {
            type: Types.ObjectId,
            ref: 'User',
            required: true, // This is the admin who created the task
        },
        isDeleted: {
            type: Boolean,
            default: false,
        },
        deletedAt: {
            type: Date,
            default: null,
        },
    },
    {
        timestamps: true, versionKey: false
    }
);



//Model
export const Task = model("Task", taskSchema) 