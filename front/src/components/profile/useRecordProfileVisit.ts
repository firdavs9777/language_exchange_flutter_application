import { useEffect, useRef } from "react";
import { useSelector } from "react-redux";
import { useRecordProfileVisitMutation } from "../../store/slices/usersSlice";

/**
 * Tell the server that this viewer looked at this profile.
 *
 * `POST /auth/users/:userId/profile-visit` and the whole visitors feature
 * built on it — the list, the stat tiles, the "someone viewed your profile"
 * notification — existed on the server and in `usersSlice` from the start. The
 * mutation's hook was generated and exported, and nothing ever called it. So
 * every visit from the web went unrecorded: an app user's visitors list could
 * only ever contain other app users, `profileStats` undercounted by the whole
 * of the web's traffic, and the web's own `/visitors` page showed a list it
 * could never contribute to.
 *
 * Mirrors `single_community_screen.dart:146`: fire on open, source `direct`,
 * errors swallowed. The server dedups within five minutes and caps the
 * notification at three a day, so an eager caller costs nothing — but a
 * remount is not a new visit, hence the ref.
 *
 * Signed-in viewers only. `/profile/:userId` is public, the endpoint is behind
 * `protect`, and an anonymous visit has nobody to attribute it to.
 */
export default function useRecordProfileVisit(
  profileId: string,
  isOwn: boolean
): void {
  const viewerId = useSelector(
    (state: any) => state.auth.userInfo?.user?._id || state.auth.userInfo?._id
  );
  const [recordProfileVisit] = useRecordProfileVisitMutation();

  // Which profile this viewer has already been recorded against. Keyed by id
  // rather than a plain boolean because `/community/:a` -> `/community/:b`
  // changes a route param without unmounting the page: a "have I fired yet"
  // flag would record the first person and silently skip everyone after.
  const recorded = useRef<string | null>(null);

  useEffect(() => {
    if (!profileId || !viewerId || isOwn) return;
    if (recorded.current === profileId) return;
    recorded.current = profileId;
    // Fire and forget. Nobody asked for this request, so nothing it does may
    // reach the page — not a toast, not a retry, not an unhandled rejection.
    recordProfileVisit(profileId)
      .unwrap()
      .catch(() => {});
  }, [profileId, viewerId, isOwn, recordProfileVisit]);
}
