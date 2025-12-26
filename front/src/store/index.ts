import { configureStore } from "@reduxjs/toolkit";
import { apiSlice } from "./slices/apiSlice";
import momentSliceReducer from "./slices/momentsSlice";
import authSliceReducer from "./slices/authSlice";
import commentsSliceReducer from "./slices/comments";
import chatApiSliceReducer from "./slices/chatSlice";
import storiesApiSliceReducer from "./slices/storiesSlice";
const rootReducer = configureStore({
  reducer: {
    [apiSlice.reducerPath]: apiSlice.reducer,
    moments: momentSliceReducer,
    auth: authSliceReducer,
    comments: commentsSliceReducer,
    chats: chatApiSliceReducer,
    stories: storiesApiSliceReducer,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware().concat(apiSlice.middleware),
  devTools: true,
});
export type RootState = ReturnType<typeof rootReducer.getState>;

export default rootReducer;
