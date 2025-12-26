// src/components/Chat/types.ts
export interface User {
  _id: string;
  name: string;
  image?: string;
}

export interface Message {
  _id: string;
  message: string;
  sender: User;
  receiver: User;
  createdAt: string;
}

export interface Conversation {
  _id: string;
  name: string;
  image?: string;
  native_language: string;
  language_to_learn: string;
  recentMessage?: Message;
}
