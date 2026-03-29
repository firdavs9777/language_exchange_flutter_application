import { apiSlice } from "./apiSlice";
import { MESSAGES_URL } from "../../constants";

// Interfaces
export interface MessageData {
  sender: string;
  receiver: string;
  message: string;
  type?: 'text' | 'image' | 'voice' | 'video' | 'file';
  replyTo?: string;
}

export const chatApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder: any) => ({
    // Conversations
    getConversations: builder.query({
      query: ({ page = 1, limit = 20 } = {}) => ({
        url: `${MESSAGES_URL}/conversations?page=${page}&limit=${limit}`,
      }),
      providesTags: ["Conversations"],
    }),
    createChatRoom: builder.mutation({
      query: (userId: string) => ({
        url: `${MESSAGES_URL}/conversations`,
        method: "POST",
        body: { userId },
      }),
      invalidatesTags: ["Conversations"],
    }),
    deleteConversation: builder.mutation({
      query: (conversationId: string) => ({
        url: `${MESSAGES_URL}/conversations/${conversationId}`,
        method: "DELETE",
      }),
      invalidatesTags: ["Conversations"],
    }),
    markConversationRead: builder.mutation({
      query: (conversationId: string) => ({
        url: `${MESSAGES_URL}/conversations/${conversationId}/read`,
        method: "PUT",
      }),
      invalidatesTags: ["Conversations"],
    }),
    muteConversation: builder.mutation({
      query: ({ conversationId, duration }: { conversationId: string; duration?: number }) => ({
        url: `${MESSAGES_URL}/conversations/${conversationId}/mute`,
        method: "PUT",
        body: { duration },
      }),
      invalidatesTags: ["Conversations"],
    }),
    unmuteConversation: builder.mutation({
      query: (conversationId: string) => ({
        url: `${MESSAGES_URL}/conversations/${conversationId}/mute`,
        method: "DELETE",
      }),
      invalidatesTags: ["Conversations"],
    }),

    // Messages
    getMessages: builder.query({
      query: () => ({
        url: `${MESSAGES_URL}`,
      }),
      providesTags: ["Messages"],
    }),
    getUserMessages: builder.query({
      query: (userId: string) => ({
        url: `${MESSAGES_URL}/user/${userId}`,
      }),
      providesTags: ["UserMessages"],
    }),
    getConversation: builder.query({
      query: ({
        senderId,
        receiverId,
        page = 1,
        limit = 50,
      }: {
        senderId: string;
        receiverId: string;
        page?: number;
        limit?: number;
      }) => ({
        url: `${MESSAGES_URL}/conversation/${senderId}/${receiverId}?page=${page}&limit=${limit}`,
      }),
      providesTags: ["Conversation"],
    }),
    createMessage: builder.mutation({
      query: (newMessage: MessageData) => ({
        url: `${MESSAGES_URL}`,
        method: "POST",
        body: newMessage,
      }),
      invalidatesTags: ["Messages", "Conversation", "Conversations"],
    }),
    editMessage: builder.mutation({
      query: ({ messageId, content }: { messageId: string; content: string }) => ({
        url: `${MESSAGES_URL}/${messageId}`,
        method: "PUT",
        body: { content },
      }),
      invalidatesTags: ["Conversation"],
    }),
    deleteMessage: builder.mutation({
      query: ({ messageId, forEveryone = false }: { messageId: string; forEveryone?: boolean }) => ({
        url: `${MESSAGES_URL}/${messageId}?forEveryone=${forEveryone}`,
        method: "DELETE",
      }),
      invalidatesTags: ["Conversation"],
    }),

    // Message Reactions
    addReaction: builder.mutation({
      query: ({ messageId, emoji }: { messageId: string; emoji: string }) => ({
        url: `${MESSAGES_URL}/${messageId}/reactions`,
        method: "POST",
        body: { emoji },
      }),
      invalidatesTags: ["Conversation"],
    }),
    removeReaction: builder.mutation({
      query: ({ messageId, emoji }: { messageId: string; emoji: string }) => ({
        url: `${MESSAGES_URL}/${messageId}/reactions/${encodeURIComponent(emoji)}`,
        method: "DELETE",
      }),
      invalidatesTags: ["Conversation"],
    }),

    // Voice Messages - POST /api/v1/messages/voice with FormData (field: voice)
    sendVoiceMessage: builder.mutation({
      query: (formData: FormData) => ({
        url: `${MESSAGES_URL}/voice`,
        method: "POST",
        body: formData,
      }),
      invalidatesTags: ["Conversation", "Conversations"],
    }),

    // Media Messages - POST /api/v1/messages with FormData (field: attachment)
    sendMediaMessage: builder.mutation({
      query: (formData: FormData) => ({
        url: `${MESSAGES_URL}`,
        method: "POST",
        body: formData,
      }),
      invalidatesTags: ["Conversation", "Conversations"],
    }),

    // Video Messages - POST /api/v1/messages/video with FormData (field: video)
    sendVideoMessage: builder.mutation({
      query: (formData: FormData) => ({
        url: `${MESSAGES_URL}/video`,
        method: "POST",
        body: formData,
      }),
      invalidatesTags: ["Conversation", "Conversations"],
    }),

    // Read Receipts
    markMessageRead: builder.mutation({
      query: (messageId: string) => ({
        url: `${MESSAGES_URL}/${messageId}/read`,
        method: "PUT",
      }),
    }),
    getReadReceipts: builder.query({
      query: (messageId: string) => ({
        url: `${MESSAGES_URL}/${messageId}/read-receipts`,
      }),
    }),

    // Search
    searchMessages: builder.query({
      query: ({ query, conversationId, page = 1, limit = 20 }: {
        query: string;
        conversationId?: string;
        page?: number;
        limit?: number;
      }) => ({
        url: `${MESSAGES_URL}/search?q=${encodeURIComponent(query)}${conversationId ? `&conversationId=${conversationId}` : ''}&page=${page}&limit=${limit}`,
      }),
    }),

    // Translation
    translateMessage: builder.mutation({
      query: ({ messageId, targetLanguage }: { messageId: string; targetLanguage: string }) => ({
        url: `${MESSAGES_URL}/${messageId}/translate`,
        method: "POST",
        body: { targetLanguage },
      }),
    }),

    // Unread Count
    getUnreadCount: builder.query({
      query: () => ({
        url: `${MESSAGES_URL}/unread-count`,
      }),
      providesTags: ["Conversations"],
    }),
  }),
});

export const {
  // Conversations
  useGetConversationsQuery,
  useCreateChatRoomMutation,
  useDeleteConversationMutation,
  useMarkConversationReadMutation,
  useMuteConversationMutation,
  useUnmuteConversationMutation,
  // Messages
  useGetMessagesQuery,
  useGetUserMessagesQuery,
  useGetConversationQuery,
  useCreateMessageMutation,
  useEditMessageMutation,
  useDeleteMessageMutation,
  // Reactions
  useAddReactionMutation,
  useRemoveReactionMutation,
  // Voice
  useSendVoiceMessageMutation,
  // Media
  useSendMediaMessageMutation,
  // Video
  useSendVideoMessageMutation,
  // Read Receipts
  useMarkMessageReadMutation,
  useGetReadReceiptsQuery,
  // Search
  useSearchMessagesQuery,
  // Translation
  useTranslateMessageMutation,
  // Unread
  useGetUnreadCountQuery,
} = chatApiSlice;

export default chatApiSlice.reducer;
