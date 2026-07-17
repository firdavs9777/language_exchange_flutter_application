import React from "react";
import { useParams } from "react-router-dom";
import { Alert } from "react-bootstrap";
import { useTranslation } from "react-i18next";
import CommunityDetail from "../community/CommunityDetail";

// Public, read-only profile route: /profile/:userId
//
// This MUST work for logged-out visitors (no auth wall) so shared
// "banatalk.com/profile/:userId" links resolve for anyone. It is
// intentionally separate from the owner's `/profile` route (Profile.tsx),
// which always renders the logged-in user's own editable profile.
//
// Rather than rebuild profile markup, this reuses the existing
// `CommunityDetail` view — the component the app already uses to render a
// read-only view of another user's profile (it already hides owner-only
// actions like follow/chat when the viewer IS the profile owner). With
// `isPublic`, CommunityDetail fetches via the PUBLIC
// `GET /auth/users/:userId/public` endpoint instead of the protected one, so
// it also owns loading/error/not-found states for this route — no separate
// fetch here.
const PublicProfile: React.FC = () => {
  const { userId } = useParams<{ userId: string }>();
  const { t } = useTranslation();

  if (!userId) {
    return (
      <div className="container py-5 text-center">
        <Alert variant="danger" className="rounded-4 d-inline-block">
          {t("communityDetail.errors.invalidProfileId", "Invalid profile link.")}
        </Alert>
      </div>
    );
  }

  // Reuse the existing read-only profile view. `readOnly` forces owner-only
  // actions (follow, start chat, practice CTA) to stay hidden for every
  // visitor to this public route — logged out or logged in as someone else —
  // regardless of auth state. `hideCommunityChrome` drops the "Back to
  // Community" nav since this is reached via a shared profile link, not the
  // community browse flow. `isPublic` routes the fetch through the
  // unauthenticated endpoint so logged-out visitors don't hit a 401.
  return (
    <CommunityDetail
      userId={userId}
      hideCommunityChrome
      readOnly
      isPublic
    />
  );
};

export default PublicProfile;
