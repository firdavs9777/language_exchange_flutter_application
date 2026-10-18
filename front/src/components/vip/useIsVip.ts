import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { useGetVipStatusQuery } from "../../store/slices/usersSlice";
import { isVipUser } from "./vipStatus";

/** Whether the signed-in viewer currently has VIP (server tier wins). */
export function useIsVip(): boolean {
  const user = useSelector(
    (state: RootState) => state.auth.userInfo?.user || state.auth.userInfo?.data
  );
  const userId: string | undefined = user?._id;
  // Re-read on tab return: a VIP bought in the app unlocks the web without a
  // reload. One request per focus, shared by every caller (same cache key).
  const { data } = useGetVipStatusQuery(userId || "", { skip: !userId, refetchOnFocus: true });
  return isVipUser(user, data);
}
