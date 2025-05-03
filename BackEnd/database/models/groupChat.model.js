import { model, Schema } from "mongoose";
import { User } from "./user.model.js";

const groupChatSchema = new Schema(
  {
    isMessageAllowed: {
      type: Boolean,
      default: true
    },
    messages: [{
      sender: {
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true
      },
      content: {
        type: String,
        required: function() {
          return !this.attachment; // Content is required if there's no attachment
        }
      },
      attachment: {
        type: {
          type: String, // 'file', 'image', 'document', etc.
          enum: ['file', 'image', 'document', 'other']
        },
        url: String,
        filename: String,
        size: Number,
        mimeType: String
      },
      readBy: [{
        type: Schema.Types.ObjectId,
        ref: 'User'
      }],
      isPinned: {
        type: Boolean,
        default: false
      }
    }]
  },
  {
    timestamps: true,
    versionKey: false
  }
);

// Create a single group chat if it doesn't exist
groupChatSchema.statics.getOrCreateGroupChat = async function() {
  let groupChat = await this.findOne();
  if (!groupChat) {
    groupChat = await this.create({});
  }
  return groupChat;
};

export const GroupChat = model("GroupChat", groupChatSchema);