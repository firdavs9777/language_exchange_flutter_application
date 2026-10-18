import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { useGetUserProfileQuery } from "../../store/slices/usersSlice";
import { isVipUser } from "./vipStatus";

/**
 * Whether the signed-in viewer has VIP, from the account as it is NOW
 * (GET /auth/me: `userMode` / `vipSubscription`), falling back to the login
 * snapshot until that arrives. Same cache entry ({}) the community page
 * already reads, so this costs no extra request there. Re-read on tab return,
 * so a VIP bought in the app unlocks the web without a reload.
 */
export function useIsVip(): boolean {
  const cached = useSelector((state: RootState) => {
    const info: any = state.auth.userInfo;
    return info ? info.user || info.data : undefined;
  });
  const { data } = useGetUserProfileQuery({}, { skip: !cached, refetchOnFocus: true });
  const fresh: any = (data as any)?.data || (data as any)?.user;
  const current = fresh && typeof fresh === "object" && fresh._id ? fresh : undefined;
  return isVipUser(current || cached);
}
