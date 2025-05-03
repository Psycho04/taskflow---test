import { model, Schema } from "mongoose";
import bcrypt from "bcrypt";

const userSchema = new Schema(
  {
    name: {
      type: String,
      required: true,
    },
    email: {
      type: String,
      required: true,
      unique: true,
    },
    password: {
      type: String,
      required: true,
    },
    role: {
      type: String,
      enum: ["admin", "user"],
      default: "user",
    },
    jobTitle: {
      type: String,
      required: true,
      default: "Employee",
    },
    image: String,
    passwordChangedAt: Date,
  },
  {
    timestamps: true,
    versionKey: false,
  }
);
userSchema.pre("save", function () {
  this.password = bcrypt.hashSync(this.password, 8);
});

export const User = model("User", userSchema);
