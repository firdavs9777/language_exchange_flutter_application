import { createSlice, PayloadAction } from "@reduxjs/toolkit";

// Define the type for the state
export interface UserType {
  _id: string;
  name: string;
  email: string;
  password: string;
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

// Helper to normalize userInfo structure (always use { user, token, refreshToken? })
export const normalizeUserInfo = (stored: any) => {
  if (!stored) return null;

  // If it has 'user' key, it's already normalized — but preserve refreshToken
  // if it travels alongside (otherwise the apiSlice can't auto-refresh on 401).
  if (stored.user) {
    return {
      ...stored,
      refreshToken: stored.refreshToken,
    };
  }

  // If it has 'data' key (old format from API response), normalize it
  if (stored.data) {
    return {
      user: stored.data,
      token: stored.token,
      refreshToken: stored.refreshToken,
    };
  }

  return stored;
};

/**
 * Read and normalize the stored session, rewriting localStorage when the old
 * `{ data }` shape had to be migrated. Returns null when there is no browser,
 * nothing stored, or the stored value is unreadable.
 */
export function readStoredUserInfo() {
  // No storage without a browser (prerender, node tests): start logged out.
  if (typeof window === "undefined") return null;
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
}

/**
 * The initial session for a freshly created store.
 *
 * Prerendered pages are rendered logged out (the prerender's store is built in
 * Node, where there is no localStorage), so a signed-in visitor whose first
 * client render restored the session would hydrate a logged-in navbar over
 * logged-out markup — React #418, and a full client re-render of the page. On
 * such a page we start logged out and App restores the session from storage
 * right after the first commit (src/utils/hydrationAuth.ts).
 *
 * Client-rendered pages have nothing to match, so they keep today's behaviour
 * and get the session synchronously.
 */
const getInitialUserInfo = () => {
  const prerendered =
    typeof document !== "undefined" && !!document.getElementById("root")?.hasChildNodes();
  if (prerendered) return null;

  return readStoredUserInfo();
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

/**
 * The single source of truth for "is this an admin" in the web client.
 *
 * `role` is the backend's own field (`authorize('admin')` reads it server-side),
 * so this selector and the API agree by construction. It gates the navbar entry
 * and the `/admin` route guard — both cosmetic: every admin route is protected
 * server-side, and a forged `userInfo` in localStorage buys nothing but an
 * empty console full of 403s.
 */
export const selectIsAdmin = (state: { auth: { userInfo?: any } }) =>
  state.auth.userInfo?.user?.role === "admin";
export default authSlice.reducer;
