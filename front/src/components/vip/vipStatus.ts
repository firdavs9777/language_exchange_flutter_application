/**
 * VIP helpers shared by every paywalled surface on web.
 *
 * The server decides what a user can do via lib/tier.js `tierOf` and exposes
 * it as `data.tier` on GET /auth/users/:id/vip/status. Until that query
 * answers, the cached user document decides (the same rule as the ads gate).
 */
import { isVipUser as userDocIsVip } from "../ads/adsGate";

/** Router path of the VIP page (src/router/routes.tsx "settings/vip"). */
export const VIP_PATH = "/settings/vip";

export function isVipUser(user: any, vipStatus?: any): boolean {
  const status = vipStatus && vipStatus.data;
  if (status && typeof status.tier === "string") return status.tier === "vip";
  if (status && status.isVIP === true) return true;
  return userDocIsVip(user);
}
