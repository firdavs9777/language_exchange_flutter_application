import { apiSlice } from "./apiSlice";

/** Profile Boost, routes/boosts.js (behind BOOSTS_ENABLED). Same calls as the app. */
export const BOOSTS_URL = "/api/v1/boosts";
export const COIN_BALANCE_URL = "/api/v1/coins/balance";

export interface Boost {
  _id: string;
  kind?: string;
  startsAt?: string;
  endsAt?: string;
  impressions?: number;
  impressionsBySource?: { partners?: number; matches?: number; moments?: number };
  coinsSpent?: number;
  status?: string;
}

const tagged = apiSlice.enhanceEndpoints({ addTagTypes: ["Boost", "CoinBalance"] });

export const boostsApiSlice = tagged.injectEndpoints({
  endpoints: (builder: any) => ({
    getActiveBoost: builder.query({
      query: () => ({ url: `${BOOSTS_URL}/active` }),
      transformResponse: (r: any): Boost | null => (r && r.data && r.data.boost) || null,
      providesTags: ["Boost"],
    }),
    getBoostHistory: builder.query({
      query: () => ({ url: `${BOOSTS_URL}/history` }),
      transformResponse: (r: any): Boost[] => (r && r.data && Array.isArray(r.data.boosts) ? r.data.boosts : []),
      providesTags: ["Boost"],
    }),
    purchaseProfileBoost: builder.mutation({
      query: () => ({ url: BOOSTS_URL, method: "POST", body: { kind: "profile" } }),
      transformResponse: (r: any): Boost | null => (r && r.data && r.data.boost) || null,
      invalidatesTags: ["Boost", "CoinBalance"],
    }),
    /** The member's coin balance (coins are bought in the app; the website only reads it). */
    getCoinBalance: builder.query({
      query: () => ({ url: COIN_BALANCE_URL }),
      transformResponse: (r: any): number => (r && typeof r.balance === "number" ? r.balance : 0),
      providesTags: ["CoinBalance"],
    }),
  }),
});

export const {
  useGetActiveBoostQuery,
  useGetBoostHistoryQuery,
  usePurchaseProfileBoostMutation,
  useGetCoinBalanceQuery,
} = boostsApiSlice as any;
