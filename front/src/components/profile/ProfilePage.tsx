import React, { useState } from "react";
import { Link, Navigate, useNavigate, useParams, useSearchParams } from "react-router-dom";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { RefreshCw, UserX } from "lucide-react";
import PageMeta from "../../seo/PageMeta";
import SurfaceCard from "../../design/SurfaceCard";
import AdUnit from "../ads/AdUnit";
import { AD_SLOTS } from "../ads/adsenseConfig";
import { useGetUserProfileQuery } from "../../store/slices/usersSlice";
import useProfileData from "./useProfileData";
import routeId from "../../utils/routeId";
import useRecordProfileVisit from "./useRecordProfileVisit";
import ProfileHeader from "./parts/ProfileHeader";
import ProfileStats from "./parts/ProfileStats";
import ProfileActions from "./parts/ProfileActions";
import ProfileLanguages, { hasLanguages } from "./parts/ProfileLanguages";
import ProfileAbout, { hasAbout } from "./parts/ProfileAbout";
import ProfileLearning, { hasLearning } from "./parts/ProfileLearning";
import ProfileMoments from "./parts/ProfileMoments";
import ProfilePhotos from "./parts/ProfilePhotos";
import LanguageMatchCard from "./parts/LanguageMatchCard";
import EngagementStats from "./parts/EngagementStats";
import MutualInterests, { hasMutualInterests } from "./parts/MutualInterests";
import ConversationStarters from "./parts/ConversationStarters";
import SuggestedMembers from "./parts/SuggestedMembers";
import HighlightsRail from "../stories/HighlightsRail";

/**
 * How many moment tiles the profile shows before "See all" takes over. Three
 * rows of the widest grid, so the section never pushes the rest of the page
 * off the screen on a heavy account (`GET /moments/user/:id` is unpaginated).
 */
const MOMENTS_ON_PROFILE = 9;

/** Where a blocked person's profile sends the viewer. */
const AFTER_BLOCK = "/communities";

/**
 * The two panels the phone layout switches between, as the app's member page
 * does (single_community_screen.dart:568). `moments` is the default because
 * it is what the tab bar opens on there, and because the About material is
 * one scroll away rather than hidden.
 */
type ProfileTab = "moments" | "about";

/** Tab order, which is also the arrow-key order. */
// About first, because it is the tab the page opens on: landing on the
// SECOND tab reads as though something went wrong, and Home would jump away
// from where you started.
const TABS: ProfileTab[] = ["about", "moments"];
const tabId = (name: ProfileTab): string => `profile-tab-${name}`;
const panelId = (name: ProfileTab): string => `profile-panel-${name}`;

const TAB_BASE =
  "flex-1 rounded-chip px-3 py-2 text-sm font-semibold transition-colors";
const TAB_ON = "bg-surface text-ink-900 shadow-card dark:bg-cardbg-dark dark:text-ink-50";
const TAB_OFF = "text-ink-500 hover:text-ink-700 dark:text-ink-400 dark:hover:text-ink-200";

const PAGE = "min-h-screen bg-canvas dark:bg-canvas-dark";
const COLUMN = "mx-auto w-full max-w-5xl px-3 pb-16 pt-4 sm:px-4 sm:pt-6";

/** RTK Query surfaces the HTTP status as `status`, or `originalStatus` for a non-JSON body. */
function statusOf(error: any): number {
  if (!error) return 0;
  if (typeof error.status === "number") return error.status;
  if (typeof error.originalStatus === "number") return error.originalStatus;
  return 0;
}

/** Grey blocks in the shape of the loaded page, so nothing jumps when it arrives. */
const ProfileSkeleton: React.FC = () => (
  <div data-testid="profile-skeleton" aria-busy="true" className="animate-pulse space-y-4">
    <div className="overflow-hidden rounded-card bg-surface shadow-card dark:bg-cardbg-dark dark:shadow-none">
      <div className="h-28 bg-ink-100 dark:bg-ink-800 sm:h-32" />
      <div className="px-4 pb-5 sm:px-6">
        <div className="-mt-10 h-20 w-20 rounded-full border-4 border-surface bg-ink-100 dark:border-cardbg-dark dark:bg-ink-800" />
        <div className="mt-3 h-5 w-40 rounded-chip bg-ink-100 dark:bg-ink-800" />
        <div className="mt-2 h-4 w-24 rounded-chip bg-ink-100 dark:bg-ink-800" />
        <div className="mt-3 h-6 w-56 rounded-chip bg-ink-100 dark:bg-ink-800" />
      </div>
    </div>

    <div className="grid grid-cols-3 gap-2">
      {[0, 1, 2].map((tile) => (
        <div
          key={tile}
          className="h-20 rounded-card bg-surface shadow-card dark:bg-cardbg-dark dark:shadow-none"
        />
      ))}
    </div>

    <div className="h-10 rounded-chip bg-ink-100 dark:bg-ink-800" />

    <div className="grid gap-4 lg:grid-cols-2 lg:items-start">
      <div className="space-y-4">
        <div className="h-36 rounded-card bg-surface shadow-card dark:bg-cardbg-dark dark:shadow-none" />
        <div className="h-48 rounded-card bg-surface shadow-card dark:bg-cardbg-dark dark:shadow-none" />
      </div>
      <div className="h-72 rounded-card bg-surface shadow-card dark:bg-cardbg-dark dark:shadow-none" />
    </div>
  </div>
);

/**
 * One profile page for both routes.
 *
 * `/profile` and `/profile/:userId` render this same component; whose profile
 * it is comes from `useProfileData`, which compares the route param with the
 * signed-in user in the store — so the two routes cannot drift apart the way
 * `Profile.tsx` and `CommunityDetail.tsx` did (inventory §2).
 *
 * The layout is two columns from 1024px up, with the personal facts on the
 * left and the moments grid on the right; the header, the stat tiles and the
 * action row always span the full width. Below that the same two columns
 * become the app's Moments / About tabs, kept in `?tab=`.
 *
 * On someone else's profile it also carries the app's match-aware blocks:
 * the language match card and the engagement strip under the action row,
 * mutual interests in the About panel, conversation starters above the
 * moments, and the suggestion strip the old /community/:id page had.
 */
const ProfilePage: React.FC = () => {
  const { userId: rawUserId } = useParams<{ userId: string }>();
  // Shared links arrive with text glued on; the id at the front is still good.
  const userId = rawUserId ? routeId(rawUserId) : undefined;
  const { t } = useTranslation();
  const navigate = useNavigate();

  const viewerId = useSelector(
    (state: any) => state.auth.userInfo?.user?._id || state.auth.userInfo?._id
  );

  const { isOwn, user, stats, isFollowing, loading, error, refetch } = useProfileData(userId);

  // The viewer's own document, for the blocks that compare two people. On an
  // own profile this is the very request `useProfileData` already made (same
  // endpoint, same `{}` argument, so RTK Query serves both subscriptions from
  // one cache entry); on someone else's it is the one extra request the match
  // card, the mutual interests and the starters all share.
  const viewerProfile: any = useGetUserProfileQuery({}, { skip: !viewerId });
  const viewerData = viewerProfile.data;
  const viewer = isOwn
    ? user
    : (viewerData && (viewerData.data || viewerData.user)) || undefined;

  // Which half of the page a phone is looking at. The URL owns it -- never
  // component state alone -- so Back works and a link can point at either
  // tab; `useSearchParams` rather than `window.location`, because nothing
  // here may touch a browser global during render.
  const [searchParams, setSearchParams] = useSearchParams();
  // About, not Moments. On a phone the tabs are the whole navigation, and
  // landing on someone's posts before knowing who they are is the wrong first
  // screen. `?tab=moments` still works, so existing links are unaffected, and
  // desktop is untouched -- both panels are `lg:block` regardless of this.
  const selectTab = (next: ProfileTab): void => {
    const params = new URLSearchParams(searchParams);
    params.set("tab", next);
    setSearchParams(params, { replace: true });
  };

  // Arrow keys move between tabs, Home/End jump to the ends -- the ARIA tabs
  // pattern, which a roving tabIndex is only half of. Focus follows the
  // selection, so the keyboard user lands on the tab they just chose; the
  // lookup runs in a handler, never during render.
  const handleTabKeys = (event: React.KeyboardEvent<HTMLDivElement>): void => {
    const at = TABS.indexOf(tab);
    let next: ProfileTab | null = null;
    if (event.key === "ArrowRight") next = TABS[(at + 1) % TABS.length];
    else if (event.key === "ArrowLeft") next = TABS[(at - 1 + TABS.length) % TABS.length];
    else if (event.key === "Home") next = TABS[0];
    else if (event.key === "End") next = TABS[TABS.length - 1];
    if (!next) return;
    event.preventDefault();
    selectTab(next);
    const button = document.getElementById(tabId(next));
    if (button) button.focus();
  };

  // /profile is the signed-in user's own page, and routes.tsx guards nothing
  // itself (there is no RequireAuth in this app). With no session there is no
  // "me" to fetch, and the not-found card is the wrong answer to "you are
  // signed out" -- /profile/:userId stays public, so only the own route
  // redirects.
  const signedOut = !userId && !viewerId;

  const name = (user && (user.name || user.username)) || "";
  const displayName = name || t("profile.page.title") || "Profile";
  // The moments section and the hook must ask for the same id, or RTK Query
  // keys them separately and the one request becomes two.
  const profileId = userId || (user && user._id) || "";

  // Someone looked at this profile. Fires once the id is known, for a
  // signed-in viewer on somebody else's page, and never blocks the render.
  useRecordProfileVisit(profileId, isOwn);

  const images = (user && user.imageUrls) || [];

  // Tapping the profile picture opens the photo viewer on it. The avatar IS
  // the first photo (`images[0]` below), so this is index 0 rather than a
  // second copy of the image.
  const [avatarOpenAt, setAvatarOpenAt] = useState<number | null>(null);

  // What the About panel would actually contain. Photos sit above the tabs, so
  // they are not part of it -- but they are worth landing next to, which is why
  // they count towards "About has something to show".
  const aboutHasSomething =
    hasLanguages(user) ||
    hasAbout(user) ||
    hasLearning(user) ||
    (!isOwn && hasMutualInterests(viewer, user)) ||
    images.length > 0;

  // About, not Moments: on a phone the tabs are the whole navigation, and
  // landing on someone's posts before knowing who they are is the wrong first
  // screen. But landing on an EMPTY panel is worse than either, so a profile
  // with nothing to say falls back to Moments. An explicit ?tab= always wins,
  // and desktop is untouched -- both panels are `lg:block` regardless of this.
  const requested = searchParams.get("tab");
  const tab: ProfileTab =
    requested === "moments"
      ? "moments"
      : requested === "about"
      ? "about"
      : aboutHasSomething
      ? "about"
      : "moments";
  const notFound = !loading && (statusOf(error) === 404 || (!error && !user));
  const failed = !loading && !notFound && Boolean(error);

  const meta = <PageMeta noindex title={`${displayName} · BananaTalk`} />;

  if (signedOut) return <Navigate to="/login" replace />;

  if (loading) {
    return (
      <div className={PAGE}>
        {meta}
        <div className={COLUMN}>
          <ProfileSkeleton />
        </div>
      </div>
    );
  }

  if (notFound) {
    return (
      <div className={PAGE}>
        {meta}
        <div className={COLUMN}>
          <SurfaceCard padding="md">
            <div data-testid="profile-not-found" className="py-6 text-center">
              <UserX className="mx-auto h-8 w-8 text-ink-400" aria-hidden />
              <h1 className="pt-3 font-display text-lg text-ink-900 dark:text-ink-50">
                {t("profile.page.not_found_title") || "Profile not found"}
              </h1>
              <p className="pt-1 text-sm text-ink-500 dark:text-ink-400">
                {t("profile.page.not_found_body") ||
                  "This profile doesn't exist any more, or it was never here."}
              </p>
              <Link
                to={AFTER_BLOCK}
                data-testid="profile-back-to-community"
                className="mt-4 inline-flex items-center justify-center rounded-chip bg-brand-deep px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-brand-dark"
              >
                {t("profile.page.back_to_community") || "Browse the community"}
              </Link>
            </div>
          </SurfaceCard>
        </div>
      </div>
    );
  }

  // A block either way (backend P1-PRIV-3): the server sends a minimal card
  // with isBlocked. Rendering it as a profile showed a Message and a Follow
  // button that could only fail, and empty stats that read as "nobody
  // follows them". The page says what is going on instead, without saying
  // who blocked whom.
  if (!isOwn && user && user.isBlocked === true) {
    return (
      <div className={PAGE}>
        {meta}
        <div className={COLUMN}>
          <div className="space-y-3">
            <ProfileHeader name={displayName} username={user.username} avatarUrl={images[0]} />
            <SurfaceCard padding="md">
              <div data-testid="profile-blocked" className="py-4 text-center">
                <UserX className="mx-auto h-8 w-8 text-ink-400" aria-hidden />
                <h2 className="pt-3 font-display text-lg text-ink-900 dark:text-ink-50">
                  {t("profile.blocked.title") || "This profile isn't available"}
                </h2>
                <p className="pt-1 text-sm text-ink-500 dark:text-ink-400">
                  {t("profile.blocked.body") ||
                    "One of you has blocked the other, so you can't message, follow or see each other's posts."}
                </p>
                <Link
                  to="/settings/blocked"
                  data-testid="profile-blocked-manage"
                  className="mt-4 inline-flex items-center justify-center rounded-chip border border-line px-4 py-2 text-sm font-semibold text-ink-700 transition-colors hover:bg-ink-100 dark:border-line-dark dark:text-ink-200 dark:hover:bg-ink-800"
                >
                  {t("profile.blocked.manage") || "Manage blocked people"}
                </Link>
              </div>
            </SurfaceCard>
          </div>
        </div>
      </div>
    );
  }
  if (failed) {
    return (
      <div className={PAGE}>
        {meta}
        <div className={COLUMN}>
          <SurfaceCard padding="md">
            <div data-testid="profile-error" role="alert" className="py-6 text-center">
              <h1 className="font-display text-lg text-ink-900 dark:text-ink-50">
                {t("profile.page.error_title") || "We couldn't load this profile"}
              </h1>
              <p className="pt-1 text-sm text-ink-500 dark:text-ink-400">
                {t("profile.page.error_body") || "Check your connection and try again."}
              </p>
              <button
                type="button"
                data-testid="profile-retry"
                onClick={refetch}
                className="mt-4 inline-flex items-center justify-center gap-1.5 rounded-chip bg-brand-deep px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-brand-dark"
              >
                <RefreshCw className="h-4 w-4" aria-hidden />
                {t("profile.page.retry") || "Try again"}
              </button>
            </div>
          </SurfaceCard>
        </div>
      </div>
    );
  }

  // Someone else's story ring (getUserPublic hasActiveStory, P1-PRIV-2). The
  // story viewer reads protected endpoints, so a signed-out visitor is sent
  // to log in first.
  const hasStory = !isOwn && Boolean(user && user.hasActiveStory);
  const handleAvatarClick = (): void => {
    if (!hasStory) {
      setAvatarOpenAt(0);
      return;
    }
    navigate(viewerId ? `/stories/${profileId}` : "/login");
  };

  return (
    <div className={PAGE}>
      {meta}
      <div className={COLUMN}>
        <div data-testid="profile-body" className="space-y-3">
          <ProfileHeader
            name={displayName}
            username={user.username}
            avatarUrl={images[0]}
            onAvatarClick={handleAvatarClick}
            hasStory={hasStory}
            isOnline={user.isOnline}
            birthYear={user.birth_year}
            birthMonth={user.birth_month}
            birthDay={user.birth_day}
            location={user.location}
            userMode={user.userMode}
            isEmailVerified={user.isEmailVerified}
            createdAt={user.createdAt}
            lastActive={user.lastActive}
          />

          <ProfileStats
            userId={profileId}
            isOwn={isOwn}
            followers={stats.followers}
            following={stats.following}
            moments={stats.moments}
          />

          <ProfileActions
            userId={profileId}
            isOwn={isOwn}
            name={name}
            isFollowing={isFollowing}
            onBlocked={() => navigate(AFTER_BLOCK)}
          />

          {/* The match-aware blocks, for someone else's profile only: there
              is no language match, no reply rate and no opener to offer on
              your own page. */}
          {!isOwn && <LanguageMatchCard viewer={viewer} user={user} />}
          {!isOwn && <EngagementStats user={user} />}

          {/* The photo set is the fastest read of who someone is, and it
              renders nothing at all when the account has no photos — so an
              empty profile shows no empty card.
              On a phone it sits ABOVE the tabs rather than inside one: it is
              worth seeing on either tab, and behind a tab it cost a tap to
              reach. On a desktop it belongs to the right-hand column, where
              the left would otherwise carry the info against a near-empty
              half. A grid child cannot move between columns with CSS, so it
              is declared twice and exactly one is ever displayed —
              `display:none` keeps the other out of the accessibility tree as
              well as off the screen, and the images come from cache. */}
          <div data-testid="profile-photos-phone" className="lg:hidden">
            <ProfilePhotos
              images={images}
              isOwn={isOwn}
              name={name}
              openAt={avatarOpenAt}
              onOpenHandled={() => setAvatarOpenAt(null)}
            />
          </div>

          {/* Below 1024px the two columns become two tabs, as on the app's
              member page. Both panels stay mounted and the inactive one is
              hidden with a class, so switching costs no refetch and the
              desktop layout needs no second render path. */}
          <div
            role="tablist"
            data-testid="profile-tabs"
            aria-label={t("profile.tabs.label") || "Profile sections"}
            onKeyDown={handleTabKeys}
            className="flex gap-1 rounded-chip bg-ink-100 p-1 dark:bg-ink-800 lg:hidden"
          >
            {TABS.map((name) => (
              <button
                key={name}
                type="button"
                role="tab"
                id={tabId(name)}
                data-testid={tabId(name)}
                aria-selected={tab === name}
                aria-controls={panelId(name)}
                // Roving tabIndex: one stop for the whole tablist, then the
                // arrow keys move within it.
                tabIndex={tab === name ? 0 : -1}
                onClick={() => selectTab(name)}
                className={`${TAB_BASE} ${tab === name ? TAB_ON : TAB_OFF}`}
              >
                {name === "moments"
                  ? t("profile.tabs.moments") || "Moments"
                  : t("profile.tabs.about") || "About"}
              </button>
            ))}
          </div>

          <div className="grid gap-4 lg:grid-cols-2 lg:items-start">
            {/* Both panels are labelled by their tab. From 1024px up the
                tablist is display:none and the two panels simply become the
                two columns, which is the one place this pattern bends: a
                tabpanel with no visible tab still reads as a labelled region,
                which is exactly what those columns are. */}
            <div
              role="tabpanel"
              id={panelId("about")}
              aria-labelledby={tabId("about")}
              data-testid="profile-about-panel"
              className={`space-y-3 lg:block ${tab === "about" ? "" : "hidden"}`}
            >
              {/* One card, four sections. Four separate cards is what pushed
                  everything below the fold on a phone, and the four read as
                  unrelated boxes rather than one account.
                  The page has to ask each section whether it has anything
                  BEFORE drawing the card, because a parent cannot see that a
                  child returned null — hence the predicates, each exported by
                  the component that owns the rule so the two cannot drift.
                  The testid rides a wrapper div: SurfaceCard is a shared design
                  component that sets its own and forwards nothing, and it is
                  not worth changing for one caller. */}
              {(hasLanguages(user) ||
                hasAbout(user) ||
                hasLearning(user) ||
                (!isOwn && hasMutualInterests(viewer, user))) && (
                <div data-testid="profile-info-card">
                  <SurfaceCard padding="md">
                    <div className="space-y-4">
                      <ProfileLanguages user={user} bare />
                      <ProfileAbout user={user} bare />
                      <ProfileLearning user={user} bare />
                      {!isOwn && <MutualInterests viewer={viewer} user={user} bare />}
                    </div>
                  </SurfaceCard>
                </div>
              )}
              {isOwn && <AdUnit slot={AD_SLOTS.profile} className="pt-1" />}
            </div>

            <div
              role="tabpanel"
              id={panelId("moments")}
              aria-labelledby={tabId("moments")}
              data-testid="profile-moments-panel"
              className={`space-y-3 lg:block ${tab === "moments" ? "" : "hidden"}`}
            >
              {/* The desktop half of the pair declared in the About panel. */}
              <div data-testid="profile-photos-desktop" className="hidden lg:block">
                <ProfilePhotos
              images={images}
              isOwn={isOwn}
              name={name}
              openAt={avatarOpenAt}
              onOpenHandled={() => setAvatarOpenAt(null)}
            />
              </div>
              {!isOwn && (
                <ConversationStarters
                  userId={profileId}
                  viewer={viewer}
                  user={user}
                  name={name}
                />
              )}
              {/* Story highlights sit above the moments, as on the app's
                  member page. Mount-then-decide: the rail asks for the
                  person's highlights itself and renders nothing when there
                  are none, so an empty profile gains no empty card. Own
                  profiles manage theirs on /highlights instead. It rides the
                  lazy profile chunk -- the eager /moments path never loads
                  it. */}
              {!isOwn && <HighlightsRail userId={profileId} name={name} />}
              <ProfileMoments userId={profileId} isOwn={isOwn} limit={MOMENTS_ON_PROFILE} />
            </div>
          </div>

          {!isOwn && (
            <SuggestedMembers
              targetUserId={profileId}
              viewerId={viewerId}
              language={user.native_language}
              name={name}
            />
          )}
        </div>
      </div>
    </div>
  );
};

export default ProfilePage;
