import { Task } from "../../../database/models/task.model.js";
import { AppError } from "../../utils/AppError.js";
import { catchError } from "../../utils/catchError.js";
import { Notifications } from "../../../database/models/notification.model.js";

export const addTask = catchError(async (req, res, next) => {
  req.body.createdBy = req.user._id;
  let task = await Task.insertMany(req.body);

  // Create notifications for each assigned user
  const notifications = req.body.assignedTo.map((userId) => ({
    assignedTo: [userId],
    message: `New task assigned: ${req.body.title}`,
    type: "task_created",
    relatedTask: task[0]._id,
    createdBy: req.user._id,
  }));

  await Notifications.insertMany(notifications);

  res.json({ message: "added", task });
});

export const getTask = catchError(async (req, res, next) => {
  const { id } = req.params;
  let task = await Task.findById(id)
    .populate("assignedTo", "name email image")
    .populate("createdBy", "name email image");

  if (!task) {
    return next(new AppError("Task not found", 404));
  }

  // Check if task is deleted
  if (task.isDeleted) {
    return next(new AppError("This task has been deleted", 404));
  }

  // Check if the user is authorized to view this task
  const isAdmin = req.user.role === "admin";
  const isAssigned = task.assignedTo.some(
    (user) => user._id.toString() === req.user._id.toString()
  );
  const isCreator = task.createdBy._id.toString() === req.user._id.toString();

  if (!isAdmin && !isAssigned && !isCreator) {
    return next(new AppError("You are not authorized to view this task", 403));
  }

  res.json({ message: "success", task });
});

export const getUserTasks = catchError(async (req, res, next) => {
  const { id } = req.params;

  let tasks = await Task.find({
    assignedTo: id,
    isDeleted: false, // Exclude deleted tasks
  })
    .populate("assignedTo", "name email image")
    .populate("createdBy", "name email image");
  if (!tasks) return next(new AppError("no tasks for that user", 404));
  res.json({ message: "success", tasks });
});

export const getTasks = catchError(async (req, res, next) => {
  if (req.body.assignedTo) {
    req.body.assignedTo = { $all: req.body.assignedTo };
  }

  let tasks = await Task.find({
    ...req.body,
    isDeleted: false, // Exclude deleted tasks
  })
    .populate("assignedTo", "name email image")
    .populate("createdBy", "name email image");

  if (!tasks) return next(new AppError("no tasks available", 404));
  {
    tasks.length == 0
      ? res.json({ message: "no tasks available" })
      : res.json({ message: "success", tasks });
  }
});

export const moveToTrash = catchError(async (req, res, next) => {
  const { id } = req.params;
  const task = await Task.findById(id);

  if (!task) {
    return next(new AppError("Task not found", 404));
  }

  // Create notifications for each assigned user about moving to trash
  const notifications = task.assignedTo.map((userId) => ({
    assignedTo: [userId],
    message: `Task moved to trash: ${task.title}`,
    type: "task_trashed",
    relatedTask: task._id,
    createdBy: req.user._id,
  }));

  await Notifications.insertMany(notifications);

  // Move task to trash instead of deleting
  task.isDeleted = true;
  task.deletedAt = new Date();
  await task.save();

  res.json({ message: "Task moved to trash successfully" });
});

export const restoreTask = catchError(async (req, res, next) => {
  const { id } = req.params;
  const task = await Task.findById(id);

  if (!task) {
    return next(new AppError("Task not found", 404));
  }

  if (!task.isDeleted) {
    return next(new AppError("Task is not in trash", 400));
  }

  // Create notifications for each assigned user about restoration
  const notifications = task.assignedTo.map((userId) => ({
    assignedTo: [userId],
    message: `Task restored from trash: ${task.title}`,
    type: "task_restored",
    relatedTask: task._id,
    createdBy: req.user._id,
  }));

  await Notifications.insertMany(notifications);

  // Restore the task
  task.isDeleted = false;
  task.deletedAt = null;
  await task.save();

  res.json({ message: "Task restored successfully" });
});

export const getTrash = catchError(async (req, res, next) => {
  let tasks = await Task.find({
    isDeleted: true,
    createdBy: req.user._id, // Only show trash items created by the current user
  })
    .populate("assignedTo", "name email image")
    .populate("createdBy", "name email image");

  res.json({ message: "success", tasks });
});

export const deleteFromTrash = catchError(async (req, res, next) => {
  const { id } = req.params;
  const task = await Task.findById(id);

  if (!task) {
    return next(new AppError("Task not found", 404));
  }

  if (!task.isDeleted) {
    return next(new AppError("Task is not in trash", 400));
  }
  // Permanently delete the task
  await Task.findByIdAndDelete(id);

  res.json({ message: "Task permanently deleted successfully" });
});

export const emptyTrash = catchError(async (req, res, next) => {
  // Find all tasks in trash created by the current user
  const tasks = await Task.find({
    isDeleted: true,
    createdBy: req.user._id,
  });

  // Create notifications for all affected users
  const notifications = tasks.flatMap((task) =>
    task.assignedTo.map((userId) => ({
      assignedTo: [userId],
      message: `Task permanently deleted: ${task.title}`,
      type: "task_deleted",
      relatedTask: task._id,
      createdBy: req.user._id,
    }))
  );

  await Notifications.insertMany(notifications);

  // Permanently delete all tasks in trash
  await Task.deleteMany({
    isDeleted: true,
    createdBy: req.user._id,
  });

  res.json({ message: "Trash emptied successfully" });
});

export const updateTask = catchError(async (req, res, next) => {
  const { id } = req.params;
  let task = await Task.findByIdAndUpdate(id, req.body, { new: true });
  if (!task) return next(new AppError("task is not found", 500));

  // Create notifications for each assigned user about the update
  const notifications = task.assignedTo.map((userId) => ({
    assignedTo: [userId],
    message: `Task updated: ${task.title}`,
    type: "task_updated",
    relatedTask: task._id,
    createdBy: req.user._id,
  }));

  await Notifications.insertMany(notifications);

  res.json({ message: "updated", task });
});

export const updateTaskStatus = catchError(async (req, res, next) => {
  const { id } = req.params;
  const { status } = req.body;

  // Find the task
  const task = await Task.findById(id);
  if (!task) {
    return next(new AppError("Task not found", 404));
  }

  // Check if the user is assigned to this task
  const isAssigned = task.assignedTo.some(
    (userId) => userId.toString() === req.user._id.toString()
  );
  if (!isAssigned && req.user.role !== "admin") {
    return next(new AppError("You are not assigned to this task", 403));
  }

  // Update only the status
  task.status = status;
  await task.save();

  // Create notification for the task creator
  const notification = {
    assignedTo: [task.createdBy],
    message: `Task status updated to ${status}: ${task.title}`,
    type: "task_updated",
    relatedTask: task._id,
    createdBy: req.user._id,
  };

  await Notifications.create(notification);

  res.json({ message: "status updated", task });
});
