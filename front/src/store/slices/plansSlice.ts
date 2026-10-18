import { apiSlice } from "./apiSlice";
import { VIP_PLANS_URL } from "../../constants";

/** Shape returned by GET /purchases/plans — controllers/iosPurchase.js:131. */
export interface VipPlan {
  id: "monthly" | "quarterly" | "yearly";
  name: string;
  description: string;
  duration: number;
  durationUnit: string;
  features: string[];
  savings: string | null;
  recommended: boolean;
  productId: string;
  price: number;
  currency: string;
  /** Render THIS. Never format `price` yourself — the store owns the formatting. */
  localizedPrice: string;
  originalPrice?: number;
  originalLocalizedPrice?: string;
}

/**
 * Which store's prices to show. Desktop has no store of its own — the desktop
 * VIP CTA opens a modal — so it defaults to iOS. That default is free only
 * while Apple and Google prices are identical, which they are today.
 */
export function inferPlatform(userAgent: string): "ios" | "android" {
  if (/Android/i.test(userAgent)) return "android";
  return "ios";
}

/**
 * Used only when the request fails. Mirrors controllers/iosPurchase.js:20-120.
 *
 * Yes, this is hardcoded pricing — the thing this sub-project exists to remove.
 * The trade is deliberate: a pricing section that renders nothing is worse than
 * one slightly stale. What must never return is a price that was never true.
 * If store pricing changes, update this and the test that pins it.
 *
 * Note: `productId` is empty. The fallback is display-only, and the empty id
 * ensures that if a purchase is attempted while the fallback is in effect, no
 * valid product id reaches the native store flow. That is acceptable — the
 * fallback exists to show a price during an outage, not to guarantee a purchase.
 */
export const FALLBACK_PLANS: VipPlan[] = [
  {
    id: "monthly", name: "Monthly VIP", description: "Full VIP access for 1 month",
    duration: 1, durationUnit: "month", savings: null, recommended: false,
    productId: "", price: 9.99, currency: "USD", localizedPrice: "$9.99",
    features: [
      "Unlimited daily messages", "See who visited your profile",
      "Unlimited profile views", "Priority in nearby users", "Ad-free experience",
    ],
  },
  {
    id: "quarterly", name: "Quarterly VIP", description: "Full VIP access for 3 months",
    duration: 3, durationUnit: "month", savings: "20%", recommended: false,
    productId: "", price: 23.99, currency: "USD", localizedPrice: "$23.99",
    features: [
      "Unlimited daily messages", "See who visited your profile",
      "Unlimited profile views", "Priority in nearby users", "Ad-free experience",
    ],
  },
  {
    id: "yearly", name: "Yearly VIP", description: "Full VIP access for 12 months",
    duration: 12, durationUnit: "month", savings: "40%", recommended: true,
    productId: "", price: 71.99, currency: "USD", localizedPrice: "$71.99",
    features: [
      "Unlimited daily messages", "See who visited your profile",
      "Unlimited profile views", "Priority in nearby users", "Ad-free experience",
    ],
  },
];

export const plansApiSlice = apiSlice.injectEndpoints({
  endpoints: (builder) => ({
    getVipPlans: builder.query<VipPlan[], "ios" | "android">({
      query: (platform) => ({ url: `${VIP_PLANS_URL}?platform=${platform}` }),
      transformResponse: (response: any) => {
        // Real shape: { success, count, data: [...] } — controllers/iosPurchase.js:177.
        return Array.isArray(response?.data) ? response.data : [];
      },
      keepUnusedDataFor: 300,
      // The prerender ships fulfilled entries in the preloaded state: the first
      // render must match that markup, but a mount must still refresh live data.
      // (RTK reads `refetchOnMountOrArgChange` only from the createApi config or
      // a hook option, so `forceRefetch` is the per-endpoint equivalent.)
      forceRefetch: () => true,
    }),
  }),
});

export const { useGetVipPlansQuery } = plansApiSlice;
