import React from "react";
import {
  createRoutesFromElements,
  Route,
  useParams,
} from "react-router-dom";
import App from "../App";
import Loader from "../components/Loader";
import RouteError from "../components/errors/RouteError";
import { lazyWithRetry } from "./lazyWithRetry";
import MomentLinkRedirect from "./MomentLinkRedirect";
import FlagRoute from "./FlagRoute";
import RequireSignIn from "../components/gatherings/RequireSignIn";

// --- Eager: the prerendered public pages ------------------------------------
//
// Everything in this block is reachable from src/seo/publicRoutes.ts, i.e.
// scripts/prerender.js renders it to static HTML in plain Node. A prerendered
// page must never be lazy -- but note *why*, because it is not a crash: under
// React 18 a suspended component inside a Suspense boundary renders its
// fallback, so making one of these lazy would quietly emit a spinner-only page
// instead of failing the build. What actually catches that is
// src/seo/prerender/renderRoute.test.tsx, which drives every PRERENDER_PATHS
// entry through renderToString and asserts >500 bytes with exactly one <h1>.
// Eager is also the right call for weight: these are exactly the modules a
// first-time visitor needs at first paint.
//
// PRERENDER_PATHS today: / /download /meet /learn-korean
// /moments /privacy-policy /terms-of-use /support /data-deletion /404.
// Add a page to SEO_PAGES and its component belongs here.
import HomeScreen from "../components/home/HomeMain";
import NotFound from "../components/errors/NotFound";
import SignedInOnly from "../components/reels/SignedInOnly";
import MainCommnity from "../components/community/MainCommunity";
import MainMoments from "../components/moments/MainMoments";
import PrivacyPolicy from "../components/navbar/PrivacyPolicy";
import DataDeletion from "../components/navbar/DataDeletion";
import TermsOfUse from "../components/navbar/TermsOfUse";
import SupportPage from "../components/support/SupportMain";
import DownloadApp from "../components/download/DownloadApp";
import MeetLanding from "../components/landing/MeetLanding";
import LearnKoreanLanding from "../components/landing/LearnKoreanLanding";
// Not prerendered, but eager on purpose: /moment/:id is the page every shared
// moment link lands on, and it is built almost entirely out of modules the
// eager /moments feed already pulls in (SingleMoment shares its reaction row,
// share button, media players and translator). Splitting it would buy a few
// hundred bytes and cost a logged-out visitor a round trip.
import MomentDetail from "../components/moments/MomentDetail";

// --- Lazy: everything behind a login ----------------------------------------
//
// None of these routes is prerendered and none of them is on a path a crawler
// or a first-time visitor walks, so their code has no business in the main
// bundle. The import only runs when something renders the element, which also
// keeps this module requirable in plain Node.
//
// Every one of them goes through lazyWithRetry rather than React.lazy: a chunk
// fetch can fail (flaky network, or a tab left open across a deploy asking for
// hashed chunks that no longer exist), and the retry has to wrap the
// *importer*. lazyRoute() below only ever receives an already-created element,
// so this call site is the one place the retry can live. The first argument is
// the sessionStorage key that keeps the one-shot reload to one per chunk.
// Whatever still fails after that lands on the root route's errorElement.

// Auth
const Login = lazyWithRetry("../components/auth/Login", () => import("../components/auth/Login"));
const Register = lazyWithRetry("../components/auth/Register", () => import("../components/auth/Register"));
const ForgetPassword = lazyWithRetry("../components/auth/ForgetPassword", () => import("../components/auth/ForgetPassword"));
const AuthCallback = lazyWithRetry("../components/auth/AuthCallback", () => import("../components/auth/AuthCallback"));

// Profile
// One component for both profile routes: /profile and /profile/:userId. It
// decides whose profile it is from the route param and the signed-in user in
// the store, so the two paths can never drift apart again.
const ProfilePage = lazyWithRetry("../components/profile/ProfilePage", () => import("../components/profile/ProfilePage"));
const EditProfile = lazyWithRetry("../components/profile/EditProfile", () => import("../components/profile/EditProfile"));
// Followers, following and visitors are three tabs of one page. It reads the
// tab off the path, so every route below points at the same component.
const UserListPage = lazyWithRetry("../components/profile/UserListPage", () => import("../components/profile/UserListPage"));
const MyMoments = lazyWithRetry("../components/profile/MyMoments", () => import("../components/profile/MyMoments"));
const EditMyMoment = lazyWithRetry("../components/profile/EditMyMoment", () => import("../components/profile/EditMyMoment"));

// Moments composer and the saved list (the feed and the detail stay eager)
const CreateMoment = lazyWithRetry("../components/moments/CreateMoment", () => import("../components/moments/CreateMoment"));
const SavedMoments = lazyWithRetry("../components/moments/SavedMoments", () => import("../components/moments/SavedMoments"));

// Full announcement page (login required; opened from "read more" links)
const AnnouncementPage = lazyWithRetry("../components/announcements/AnnouncementPage", () => import("../components/announcements/AnnouncementPage"));

// Chat. The heaviest group: socket plumbing, media galleries, emoji.
const MainChat = lazyWithRetry("../components/chat/MainChat", () => import("../components/chat/MainChat"));
const NewChat = lazyWithRetry("../components/chat/NewChat", () => import("../components/chat/NewChat"));
const MediaGallery = lazyWithRetry("../components/chat/MediaGallery", () => import("../components/chat/MediaGallery"));

// Stories / reels
const MainStories = lazyWithRetry("../components/stories/MainStories", () => import("../components/stories/MainStories"));
const Highlights = lazyWithRetry("../components/stories/Highlights", () => import("../components/stories/Highlights"));
const CreateStory = lazyWithRetry("../components/stories/CreateStory", () => import("../components/stories/CreateStory"));
const StoryViewer = lazyWithRetry("../components/stories/StoryViewer", () => import("../components/stories/StoryViewer"));
const StoryLinkPage = lazyWithRetry("../components/stories/StoryLinkPage", () => import("../components/stories/StoryLinkPage"));
const MyStories = lazyWithRetry("../components/stories/MyStories", () => import("../components/stories/MyStories"));

// Reels (Phase 4). Dark until /app-config says webReelsEnabled AND
// reelsEnabled (FlagRoute); a signed-out visitor is sent to /login.
const ReelsGridPage = lazyWithRetry("../components/reels/ReelsGridPage", () => import("../components/reels/ReelsGridPage"));
const ReelCreatePage = lazyWithRetry("../components/reels/ReelCreatePage", () => import("../components/reels/ReelCreatePage"));

// Settings
const Settings = lazyWithRetry("../components/settings/Settings", () => import("../components/settings/Settings"));
const PrivacySettings = lazyWithRetry("../components/settings/PrivacySettings", () => import("../components/settings/PrivacySettings"));
const NotificationSettings = lazyWithRetry("../components/settings/NotificationSettings", () => import("../components/settings/NotificationSettings"));
const VipSettings = lazyWithRetry("../components/settings/VipSettings", () => import("../components/settings/VipSettings"));
const LanguageSettings = lazyWithRetry("../components/settings/LanguageSettings", () => import("../components/settings/LanguageSettings"));
const BlockedUsers = lazyWithRetry("../components/settings/BlockedUsers", () => import("../components/settings/BlockedUsers"));
const CloseFriends = lazyWithRetry("../components/settings/CloseFriends", () => import("../components/settings/CloseFriends"));
const ChangePassword = lazyWithRetry("../components/settings/ChangePassword", () => import("../components/settings/ChangePassword"));
const LanguageCard = lazyWithRetry("../components/card/LanguageCard", () => import("../components/card/LanguageCard"));

// Community, authenticated. /communities itself (MainCommnity) is members-only
// and no longer prerendered; it guards itself with RequireSignIn and is still
// imported eagerly above because every nav bar links to it.
// There is no CommunityDetail any more: /community/:userId is the profile
// page, declared with the profile group above.
const NearbyUsers = lazyWithRetry("../components/community/NearbyUsers", () => import("../components/community/NearbyUsers"));
const Waves = lazyWithRetry("../components/community/Waves", () => import("../components/community/Waves"));
const Topics = lazyWithRetry("../components/community/Topics", () => import("../components/community/Topics"));

// Phase 4 — rooms (dark until webVoiceRoomsEnabled / webLanguageRoomsEnabled).
// Every element is wrapped in FlagRoute, so with the flag off these paths are
// the 404 page. Voice rooms pull in LiveKit only after Join (lib/livekit).
const VoiceRoomsPage = lazyWithRetry("../components/voiceRooms/VoiceRoomsPage", () => import("../components/voiceRooms/VoiceRoomsPage"));
const VoiceRoomPage = lazyWithRetry("../components/voiceRooms/VoiceRoomPage", () => import("../components/voiceRooms/VoiceRoomPage"));
const LanguageRoomsPage = lazyWithRetry("../components/languageRooms/LanguageRoomsPage", () => import("../components/languageRooms/LanguageRoomsPage"));
const LanguageRoomPage = lazyWithRetry("../components/languageRooms/LanguageRoomPage", () => import("../components/languageRooms/LanguageRoomPage"));
// Profile Boost (dark until boostsEnabled), members only.
const BoostPage = lazyWithRetry("../components/boost/BoostPage", () => import("../components/boost/BoostPage"));
const CityPage = lazyWithRetry("../components/community/cityGenders/CityPage", () => import("../components/community/cityGenders/CityPage"));
const GendersPage = lazyWithRetry("../components/community/cityGenders/GendersPage", () => import("../components/community/cityGenders/GendersPage"));

// Invite landing (/i/:code). Public, never prerendered (the code is dynamic):
// it falls back to the SPA shell like /profile/:userId. Lazy for the same
// reason as the profile page -- nothing in the eager graph shares its code.
const InvitePage = lazyWithRetry("../components/invite/InvitePage", () => import("../components/invite/InvitePage"));

// Courses
const CoursesMain = lazyWithRetry("../components/courses/CoursesMain", () => import("../components/courses/CoursesMain"));

// Gatherings & clubs (Phase 4). Dark until webGatheringsEnabled (and the
// global GATHERINGS_ENABLED) -- FlagRoute renders NotFound until then, so
// none of these chunks is ever requested while the feature is off.
const GatheringsHome = lazyWithRetry("../components/gatherings/GatheringsHome", () => import("../components/gatherings/GatheringsHome"));
const GatheringDetail = lazyWithRetry("../components/gatherings/GatheringDetail", () => import("../components/gatherings/GatheringDetail"));
const GatheringForm = lazyWithRetry("../components/gatherings/GatheringForm", () => import("../components/gatherings/GatheringForm"));
const ClubDetail = lazyWithRetry("../components/gatherings/ClubDetail", () => import("../components/gatherings/ClubDetail"));
const ClubForm = lazyWithRetry("../components/gatherings/ClubForm", () => import("../components/gatherings/ClubForm"));

// Admin console. Lazy on purpose, and lazy is load-bearing twice over: this
// module is required by scripts/prerender.js in plain Node, and the console
// pulls in charts, tables and the whole admin slice that no visitor of a
// public page should download. React.lazy defers the import until a route
// actually renders, so /admin costs nothing to anyone who never opens it.
const AdminLayout = lazyWithRetry("../components/admin/AdminLayout", () => import("../components/admin/AdminLayout"));
const AdminOverview = lazyWithRetry("../components/admin/pages/AdminOverview", () => import("../components/admin/pages/AdminOverview"));
const AdminReach = lazyWithRetry("../components/admin/pages/AdminReach", () => import("../components/admin/pages/AdminReach"));
const AdminUsers = lazyWithRetry("../components/admin/pages/AdminUsers", () => import("../components/admin/pages/AdminUsers"));
const AdminContent = lazyWithRetry("../components/admin/pages/AdminContent", () => import("../components/admin/pages/AdminContent"));
const AdminAiUsage = lazyWithRetry("../components/admin/pages/AdminAiUsage", () => import("../components/admin/pages/AdminAiUsage"));
const AdminAudit = lazyWithRetry("../components/admin/pages/AdminAudit", () => import("../components/admin/pages/AdminAudit"));
const AdminAnnouncements = lazyWithRetry("../components/admin/pages/AdminAnnouncements", () => import("../components/admin/pages/AdminAnnouncements"));
const AdminAnnouncementEditor = lazyWithRetry("../components/admin/pages/AdminAnnouncementEditor", () => import("../components/admin/pages/AdminAnnouncementEditor"));

// The one fallback every lazy group shares: the app's existing spinner in a
// block tall enough that the footer does not jump up and then back down while
// a chunk is in flight. Neutral on purpose -- a skeleton would have to guess
// at seven different layouts.
const RouteFallback = () => (
  <div
    className="route-chunk-loading"
    style={{ minHeight: "60vh", display: "flex", alignItems: "center", justifyContent: "center" }}
    aria-busy="true"
    aria-live="polite"
  >
    <Loader />
  </div>
);

// One boundary per lazy group. Only one element of a group is ever mounted at
// a time, so a boundary around each element is the same thing as a boundary
// around the group without the extra layout route in between.
const lazyRoute = (node: React.ReactNode) => (
  <React.Suspense fallback={<RouteFallback />}>{node}</React.Suspense>
);

// The admin console nests a lazy layout around a lazy page: two boundaries
// resolve in sequence there, and a spinner that flashes twice reads worse
// than nothing at all.
const lazyAdminRoute = (node: React.ReactNode) => (
  <React.Suspense fallback={null}>{node}</React.Suspense>
);

// A Phase 4 gatherings page: flag first (a 404 while off, for everyone),
// then sign-in, then the lazy chunk.
const gatheringsRoute = (node: React.ReactNode) => (
  <FlagRoute flag="webGatheringsEnabled">
    <RequireSignIn>{lazyRoute(node)}</RequireSignIn>
  </FlagRoute>
);

const MainChatWrapper = () => {
  const { userId } = useParams();
  return <MainChat key={userId || "no-user"} />;
};

// One route tree, two consumers: AppRouter.tsx wraps it in createBrowserRouter
// for the browser; scripts/prerender.js feeds it to createStaticHandler. Keep
// this module free of anything that touches window at import time.
export const routes = createRoutesFromElements(
  // errorElement on the root route, so a rejected chunk import (or any other
  // render error below it) shows RouteError's reload prompt instead of
  // react-router's default stack-trace screen. RouteError touches no browser
  // global at import time or during render, so this stays prerender-safe --
  // and it is never rendered during a prerender anyway, since nothing throws
  // on the happy path.
  <Route path="/" element={<App />} errorElement={<RouteError />}>
    <Route index element={<HomeScreen />} />
    <Route path="login" element={lazyRoute(<Login />)} />
    <Route path="auth/callback" element={lazyRoute(<AuthCallback />)} />

    <Route path="data-deletion/" element={<DataDeletion />} />
    <Route path="register" element={lazyRoute(<Register />)} />
    <Route path="forgot-password" element={lazyRoute(<ForgetPassword />)} />
    <Route path="communities" element={<MainCommnity />} />
    {/* The member page. It is the profile page -- the same component, the
        same param name, the same chunk -- because the two pages had drifted
        into two different answers to "who is this person". Every existing
        /community/<id> link still resolves; only the component behind it
        changed. */}
    <Route path="community/:userId" element={lazyRoute(<ProfilePage />)} />
    {/* Public, like the profile it is built from: a card is opened from a link,
        usually by someone with no account yet. */}
    <Route path="card/:userId" element={lazyRoute(<LanguageCard />)} />
    <Route path="moments" element={<MainMoments />} />
    <Route path="moment/:id" element={<MomentDetail />} />
    <Route path="announcement/:id" element={lazyRoute(<AnnouncementPage />)} />
    <Route path="add-moment" element={lazyRoute(<CreateMoment />)} />
    <Route path="edit-moment/:id" element={lazyRoute(<EditMyMoment />)} />
    <Route path="my-moments" element={lazyRoute(<MyMoments />)} />
    <Route path="profile" element={lazyRoute(<ProfilePage />)} />
    <Route path="profile/edit" element={lazyRoute(<EditProfile />)} />
    {/* Another person's profile, and the target of every shared profile
        link. Must stay public (no auth guard) so logged-out visitors can open
        it; react-router v6 ranks the static "profile/edit" segment above this
        dynamic "profile/:userId" segment regardless of declaration order, so
        there's no conflict between the two.

        Lazy, unlike the equally-public /moment/:id above, and the difference
        is what it costs to make it eager: the profile page pulls in the whole
        profile group and shares almost nothing with the eager pages, so
        keeping it in main.js taxes every marketing visitor for a page few of
        them open. MomentDetail is the opposite -- it is built out of modules
        /moments already ships. A shared profile link pays one round trip; a
        shared moment link would have paid it for nothing. */}
    <Route path="profile/:userId" element={lazyRoute(<ProfilePage />)} />
    {/* The three own-list paths predate the list page and are kept verbatim:
        every link already pointing at them still works, and each one selects
        its own tab. The two per-user paths are what the profile's stat tiles
        link to. */}
    <Route path="followersList" element={lazyRoute(<UserListPage />)} />
    <Route path="followingsList" element={lazyRoute(<UserListPage />)} />
    <Route path="visitors" element={lazyRoute(<UserListPage />)} />
    <Route path="visited" element={lazyRoute(<UserListPage />)} />
    <Route path="profile/:userId/followers" element={lazyRoute(<UserListPage />)} />
    <Route path="profile/:userId/following" element={lazyRoute(<UserListPage />)} />
    <Route path="chat/new" element={lazyRoute(<NewChat />)} />
    {/* Every /chat route is keyed by the OTHER USER's id, not a conversation
        id: that is what /chat/:userId carries and what the media gallery
        queries with. (The old /chat/:id/settings screen is gone — the "⋯"
        info panel in the chat header replaced it.) */}
    <Route path="chat/:userId/media" element={lazyRoute(<MediaGallery />)} />
    <Route path="chat/:userId?" element={lazyRoute(<MainChatWrapper />)} />
    <Route path="courses" element={lazyRoute(<CoursesMain />)} />
    <Route path="support/" element={<SupportPage />} />
    <Route path="stories/" element={lazyRoute(<MainStories />)} />
    <Route path="create-story" element={lazyRoute(<CreateStory />)} />
    {/* Declared next to the viewer, and the static segment wins: react-router
        v6 ranks "stories/mine" above "stories/:userId" regardless of order, so
        the author's own archive can never be read as a user id. */}
    <Route path="stories/mine" element={lazyRoute(<MyStories />)} />
    <Route path="stories/:userId" element={lazyRoute(<StoryViewer />)} />
    {/* Story share links: /story/<storyId> (a STORY id; the viewer above is
        keyed by the author). Public: signed-out visitors get a sign-in /
        open-in-app card. Not claimed by the AASA until 2.7.0 dominates. */}
    <Route path="story/:id" element={lazyRoute(<StoryLinkPage />)} />
    <Route path="highlights" element={lazyRoute(<Highlights />)} />
    {/* Reels (Phase 4, flag webReelsEnabled). "reels/new" is static and
        outranks any future "reels/:id". */}
    <Route
      path="reels"
      element={<FlagRoute flag="webReelsEnabled"><SignedInOnly>{lazyRoute(<ReelsGridPage />)}</SignedInOnly></FlagRoute>}
    />
    <Route
      path="reels/new"
      element={<FlagRoute flag="webReelsEnabled"><SignedInOnly>{lazyRoute(<ReelCreatePage />)}</SignedInOnly></FlagRoute>}
    />
    <Route path="privacy-policy/" element={<PrivacyPolicy />} />
    <Route path="terms-of-use/" element={<TermsOfUse />} />
    <Route path="download" element={<DownloadApp />} />
    <Route path="meet" element={<MeetLanding />} />
    <Route path="learn-korean" element={<LearnKoreanLanding />} />
    {/* Public invite link target; no auth guard. */}
    <Route path="i/:code" element={lazyRoute(<InvitePage />)} />

    {/* Settings */}
    <Route path="settings" element={lazyRoute(<Settings />)} />
    <Route path="settings/privacy" element={lazyRoute(<PrivacySettings />)} />
    <Route path="settings/password" element={lazyRoute(<ChangePassword />)} />
    <Route path="settings/notifications" element={lazyRoute(<NotificationSettings />)} />
    <Route path="settings/vip" element={lazyRoute(<VipSettings />)} />
    <Route path="settings/language" element={lazyRoute(<LanguageSettings />)} />
    <Route path="settings/blocked" element={lazyRoute(<BlockedUsers />)} />
    <Route path="settings/close-friends" element={lazyRoute(<CloseFriends />)} />

    {/* Community */}
    <Route path="community/nearby" element={lazyRoute(<NearbyUsers />)} />
    <Route path="waves" element={lazyRoute(<Waves />)} />
    <Route path="topics" element={lazyRoute(<Topics />)} />
    {/* Phase 4 — rooms. Dark until their flags are on (FlagRoute → 404). */}
    <Route path="voice-rooms" element={lazyRoute(<FlagRoute flag="webVoiceRoomsEnabled"><VoiceRoomsPage /></FlagRoute>)} />
    <Route path="voice-rooms/:id" element={lazyRoute(<FlagRoute flag="webVoiceRoomsEnabled"><VoiceRoomPage /></FlagRoute>)} />
    <Route path="rooms" element={lazyRoute(<FlagRoute flag="webLanguageRoomsEnabled"><LanguageRoomsPage /></FlagRoute>)} />
    <Route path="rooms/:id" element={lazyRoute(<FlagRoute flag="webLanguageRoomsEnabled"><LanguageRoomPage /></FlagRoute>)} />
    <Route path="boost" element={lazyRoute(<FlagRoute flag="boostsEnabled"><RequireSignIn><BoostPage /></RequireSignIn></FlagRoute>)} />
    <Route path="community/city" element={lazyRoute(<FlagRoute flag="webLanguageRoomsEnabled"><CityPage /></FlagRoute>)} />
    <Route path="community/genders" element={lazyRoute(<FlagRoute flag="webLanguageRoomsEnabled"><GendersPage /></FlagRoute>)} />

    {/* Moments */}
    <Route path="moments/saved" element={lazyRoute(<SavedMoments />)} />
    {/* Old shared links: /moments/<id> -> /moment/<id>. "saved" above is static, so it outranks this. */}
    <Route path="moments/:id" element={<MomentLinkRedirect />} />

    {/* Gatherings & clubs (Phase 4, dark behind webGatheringsEnabled).
        Static "new" segments outrank ":id" in react-router v6. */}
    <Route path="gatherings" element={gatheringsRoute(<GatheringsHome />)} />
    <Route path="gatherings/new" element={gatheringsRoute(<GatheringForm mode="create" />)} />
    <Route path="gatherings/:id" element={gatheringsRoute(<GatheringDetail />)} />
    <Route path="gatherings/:id/edit" element={gatheringsRoute(<GatheringForm mode="edit" />)} />
    <Route path="clubs" element={gatheringsRoute(<GatheringsHome initialTab="clubs" />)} />
    <Route path="clubs/new" element={gatheringsRoute(<ClubForm mode="create" />)} />
    <Route path="clubs/:id" element={gatheringsRoute(<ClubDetail />)} />
    <Route path="clubs/:id/edit" element={gatheringsRoute(<ClubForm mode="edit" />)} />

    {/* Admin console. Guarded inside AdminLayout (RequireAdmin) and noindex
        by default — RouteMeta marks every path outside SEO_PAGES. */}
    <Route path="admin" element={lazyAdminRoute(<AdminLayout />)}>
      <Route index element={lazyAdminRoute(<AdminOverview />)} />
      <Route path="reach" element={lazyAdminRoute(<AdminReach />)} />
      <Route path="users" element={lazyAdminRoute(<AdminUsers />)} />
      <Route path="content" element={lazyAdminRoute(<AdminContent />)} />
      <Route path="ai-usage" element={lazyAdminRoute(<AdminAiUsage />)} />
      <Route path="audit" element={lazyAdminRoute(<AdminAudit />)} />
      <Route path="announcements" element={lazyAdminRoute(<AdminAnnouncements />)} />
      <Route path="announcements/:id" element={lazyAdminRoute(<AdminAnnouncementEditor />)} />
    </Route>

    {/* Catch-all. Must stay last. */}
    <Route path="*" element={<NotFound />} />
  </Route>
);
