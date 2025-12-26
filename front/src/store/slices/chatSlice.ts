import { apiSlice } from "./apiSlice";
import { MESSAGES_URL } from "../../constants"; // Adjust to your constants

// Interfaces
export interface MessageData {
  sender: string;
  receiver: string;
  message: string;
}

export const chatApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder: any) => ({
    // Fetch all messages
    createChatRoom: builder.mutation({
      query: (userId: string) => ({
        url: `${MESSAGES_URL}/conversations`,
        method: "POST",
        body: {userId}
      }),
        providesTags: ["Messages"],
    }),
    getMessages: builder.query({
      query: () => ({
        url: `${MESSAGES_URL}`,
        method: "GET",
      }),
      providesTags: ["Messages"],
    }),

    // Fetch messages for a specific user
    getUserMessages: builder.query({
      query: (userId: string) => ({
        url: `${MESSAGES_URL}/user/${userId}`,
        method: "GET",
      }),
      providesTags: ["UserMessages"],
    }),

    // Fetch conversation between two users
    getConversation: builder.query({
      query: ({
        senderId,
        receiverId,
      }: {
        senderId: string;
        receiverId: string;
      }) => ({
        url: `${MESSAGES_URL}/conversation/${senderId}/${receiverId}`,
        method: "GET",
      }),
      providesTags: ["Conversation"],
    }),

    // Create a new message
    createMessage: builder.mutation({
      query: (newMessage: MessageData) => ({
        url: `${MESSAGES_URL}`,
        method: "POST",
        body: newMessage,
        headers: {
          "Content-Type": "application/json",
        },
      }),
      invalidatesTags: ["Messages", "Conversation"],
    }),
  }),
});

export const {
  useGetMessagesQuery,
  useGetUserMessagesQuery,
  useGetConversationQuery,
  useCreateMessageMutation,
  useCreateChatRoomMutation
} = chatApiSlice;

export default chatApiSlice.reducer;
