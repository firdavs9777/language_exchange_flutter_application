import { createSlice, PayloadAction } from "@reduxjs/toolkit";

// Define the type for the state
export interface UserType {
  _id: string;
  name: string;
  email: string;
  password: string;
  isAdmin?: boolean;
  __v?: number;
  createdAt?: string;
  updatedAt?: string;
  matchPassword?: (arg1: string) => Promise<boolean>;
  save: () => Promise<UserType>;
}
export interface Response {
  name?: string;
  data?: UserType;
  token: string;
  message: string;
}

// Helper to normalize userInfo structure (always use { user, token })
const normalizeUserInfo = (stored: any) => {
  if (!stored) return null;

  // If it has 'user' key, it's already normalized
  if (stored.user) return stored;

  // If it has 'data' key (old format from API response), normalize it
  if (stored.data) {
    return {
      user: stored.data,
      token: stored.token,
    };
  }

  return stored;
};

// Get and normalize stored userInfo, then update localStorage if needed
const getInitialUserInfo = () => {
  const storedRaw = localStorage.getItem("userInfo");
  if (!storedRaw) return null;

  try {
    const stored = JSON.parse(storedRaw);
    const normalized = normalizeUserInfo(stored);

    // If we normalized (structure changed), update localStorage
    if (normalized && stored.data && !stored.user) {
      localStorage.setItem("userInfo", JSON.stringify(normalized));
    }

    return normalized;
  } catch {
    return null;
  }
};

// Get the initial state from localStorage or use a default value
const initialState = {
  userInfo: getInitialUserInfo(),
};

const authSlice = createSlice({
  name: "auth",
  initialState,
  reducers: {
    setCredentials: (state: any, action: PayloadAction<any>) => {
      // Normalize the structure to always use { user, token, message }
      const normalized = normalizeUserInfo(action.payload);
      state.userInfo = normalized;
      localStorage.setItem("userInfo", JSON.stringify(normalized));
    },
    logout: (state: any, action: any) => {
      state.userInfo = null;
      // NOTE: here we need to also remove the cart from storage so the next
      // logged in user doesn't inherit the previous users cart and shipping
      localStorage.clear();
    },
  },
});

export const { setCredentials, logout } = authSlice.actions;
export default authSlice.reducer;
