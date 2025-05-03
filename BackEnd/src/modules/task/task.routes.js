import { Router } from "express";
import * as taskCruds from "./task.controller.js";
import { protectedRoute } from "../../middleware/protectedRoute.js";
import { isAllowedTo } from "../../middleware/isAllowedTo.js";
import { validate } from "../../middleware/validation.js";
import * as taskValidation from "./taskValidation.js";
import { checkUsers } from "../../middleware/checkUsers.js";

export const taskRouter = Router();

// Get all tasks (admin only)
taskRouter.get("/", protectedRoute, isAllowedTo("admin"), taskCruds.getTasks);

// Get tasks for a specific user
taskRouter.get("/userTasks/:id", protectedRoute, taskCruds.getUserTasks);

// Create new task (admin only)
taskRouter.post(
  "/",
  protectedRoute,
  isAllowedTo("admin"),
  validate(taskValidation.addTaskValidation),
  checkUsers,
  taskCruds.addTask
);

// ✅ Move static /trash routes above /:id
taskRouter.get("/trash", protectedRoute, taskCruds.getTrash);
taskRouter.patch(
  "/:id/restore",
  protectedRoute,
  isAllowedTo("admin"),
  taskCruds.restoreTask
);
taskRouter.delete(
  "/:id/trash",
  protectedRoute,
  isAllowedTo("admin"),
  taskCruds.deleteFromTrash
);
taskRouter.delete(
  "/trash/empty",
  protectedRoute,
  isAllowedTo("admin"),
  taskCruds.emptyTrash
);

// Dynamic :id route (keep at bottom)
taskRouter
  .route("/:id")
  .get(protectedRoute, isAllowedTo("user", "admin"), taskCruds.getTask)
  .put(
    protectedRoute,
    isAllowedTo("admin"),
    validate(taskValidation.updateTaskValidation),
    taskCruds.updateTask
  )
  .delete(protectedRoute, isAllowedTo("admin"), taskCruds.moveToTrash);

// Add new route for users to update task status
taskRouter.patch(
  "/:id/status",
  protectedRoute,
  isAllowedTo("user", "admin"),
  taskCruds.updateTaskStatus
);
