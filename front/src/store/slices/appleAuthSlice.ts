import { apiSlice } from "./apiSlice";
import { APPLE_WEB_LOGIN_URL } from "../../constants";

export interface AppleWebLoginArgs {
  identityToken: string;
  nonce: string;
  /** Apple sends it only on the first consent: { name: { firstName, lastName }, email }. */
  user?: { name?: { firstName?: string; lastName?: string }; email?: string };
}

export const appleAuthApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder: any) => ({
    // POST /api/v1/auth/apple/web -> { success, token, refreshToken?, user },
    // the same answer as every other login (be controllers/auth.js:460).
    appleWebLogin: builder.mutation({
      query: (args: AppleWebLoginArgs) => {
        const body: any = { identityToken: args.identityToken, nonce: args.nonce };
        if (args.user) body.user = args.user;
        return { url: APPLE_WEB_LOGIN_URL, method: "POST", body };
      },
    }),
  }),
});

export const { useAppleWebLoginMutation } = appleAuthApiSlice as any;
