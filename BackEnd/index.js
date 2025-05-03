process.on("uncaughtException", (err) => console.log(err.message));
import express from "express";
import { dbConnection } from "./database/dbConnection.js";
import { globalError } from "./src/utils/globalError.js";
import dotenv from "dotenv";
import { bootstrap } from "./src/bootstrap.js";
import cors from "cors";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();

// Enable CORS
app.use(
  cors({
    origin: "http://localhost:3000",
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);

app.use(express.json());

// Serve static files from the uploads directory
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

dotenv.config();
const port = 5000;
process.on("unhandledRejection", (err) => console.log(err.message));
dbConnection();
bootstrap(app);

app.use(globalError);
app.get("/", (req, res) => res.send("Hello World!"));
app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
