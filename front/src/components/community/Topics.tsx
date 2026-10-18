import React, { useCallback, useEffect, useMemo, useState } from "react";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { ArrowLeft, Check, Hash, Pencil, Radio, Search, Users, X } from "lucide-react";

import { RootState } from "../../store";
import { setCredentials } from "../../store/slices/authSlice";
import {
  useGetTopicsQuery,
  useGetUsersByTopicQuery,
  useUpdateMyTopicsMutation,
} from "../../store/slices/communitySlice";
import SurfaceCard from "../../design/SurfaceCard";
import notify from "../../design/notify";
import MemberCard, { CommunityMemberCard } from "./MemberCard";
import WaveSheet from "./WaveSheet";
import topicIcon from "./lib/topicIcons";
import "./tandem/tandem-community.scss";

/**
 * /topics — browse the community by interest.
 *
 * Three things the page has to get right, and the shape below follows from
 * them:
 *
 * 1. It is the SAME product as /communities. Same canvas, same card, same
 *    brand teal, same member row. The previous version opened with a purple
 *    indigo gradient that appears nowhere else in the app and rendered the
 *    backend's emoji strings as its icons, so a K-Pop tile was a Korean flag
 *    and a list of 99 topics was a single 99-row column of oversized cards.
 * 2. "Edit" has to say what it edits. It lives inside **your** topics, next to
 *    the chips it changes, and it turns the grid below into a multi-select —
 *    rather than sitting in the page header where it reads as "edit the page".
 * 3. A topic is only interesting because of the people in it, so opening one
 *    shows them: a right-hand panel on a desktop, a full-width section under
 *    the grid on a phone, and `?topic=<id>` in the URL either way so the view
 *    can be linked, refreshed and gone back from.
 */

/** How many people one page of a topic holds. Matches the community list. */
const PEOPLE_LIMIT = 20;

/** The backend caps a member at ten topics (controllers/community.js). */
const MAX_TOPICS = 10;

/** Placeholder tiles while the topic list is in flight. */
const TILE_SKELETONS = 12;

/** Placeholder rows while a topic's people are in flight. */
const PEOPLE_SKELETONS = 4;

/**
 * A topic as `GET /api/v1/community/topics` answers it.
 *
 * The controller renames `topicId` to `id` on the way out, but `_id` still
 * arrives from other callers (and from the Flutter model's fallback), so the
 * identity is read through `topicKey` rather than assumed.
 */
export interface TopicSummary {
  id?: string;
  _id?: string;
  name: string;
  icon?: string;
  category?: string;
  userCount?: number;
}

const topicKey = (topic: TopicSummary): string =>
  String(topic.id || topic._id || topic.name || "");

/**
 * A person in a topic, as `GET /topics/:id/users` answers it.
 *
 * That endpoint has no `transformResponse` of its own: it selects `images`
 * and `level`, where the community list hands out `imageUrls` and
 * `languageLevel`. MemberCard is the shared row and reads the latter, so the
 * translation happens here instead of forking the card.
 */
const toMemberCard = (raw: any): CommunityMemberCard => ({
  ...raw,
  _id: raw?._id,
  name: raw?.name,
  imageUrls: raw?.imageUrls || raw?.images || [],
  languageLevel: raw?.languageLevel || raw?.level,
  isVIP: !!(raw?.isVIP || raw?.vipSubscription?.isActive),
});

/** One tile-shaped placeholder. Same footprint as a real tile, so no reflow. */
const TileSkeleton: React.FC = () => (
  <SurfaceCard padding="sm">
    <div className="flex items-center gap-2.5">
      <span className="h-9 w-9 shrink-0 animate-pulse rounded-chip bg-ink-100" />
      <span className="min-w-0 flex-1">
        <span className="block h-3 w-3/4 animate-pulse rounded bg-ink-100" />
        <span className="mt-2 block h-2.5 w-1/2 animate-pulse rounded bg-ink-100" />
      </span>
    </div>
  </SurfaceCard>
);

/** A member-row-shaped placeholder for the people panel. */
const PersonSkeleton: React.FC = () => (
  <div className="flex items-center gap-4 rounded-2xl border border-white/30 bg-white/80 p-4">
    <span className="h-[72px] w-[72px] shrink-0 animate-pulse rounded-[22px] bg-ink-100" />
    <span className="min-w-0 flex-1">
      <span className="block h-3.5 w-2/5 animate-pulse rounded bg-ink-100" />
      <span className="mt-2.5 block h-3 w-3/5 animate-pulse rounded bg-ink-100" />
      <span className="mt-2 block h-2.5 w-1/3 animate-pulse rounded bg-ink-100" />
    </span>
  </div>
);

const Topics: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();

  const userInfo = useSelector((state: RootState) => state.auth.userInfo);
  const signedIn = !!userInfo;
  /**
   * The viewer's own topics live on `user.topics` — the field
   * `PUT /community/topics/my` writes and EditProfile edits. (The old page
   * read `user.interests`, which no endpoint has ever written.)
   */
  const myTopics: string[] = useMemo(() => {
    const raw = (userInfo as any)?.user?.topics;
    return Array.isArray(raw) ? raw.map((x: any) => String(x)) : [];
  }, [userInfo]);

  const dispatch = useDispatch();

  const [search, setSearch] = useState("");
  const [editMode, setEditMode] = useState(false);
  /**
   * What the page believes the viewer's topics are.
   *
   * Seeded from the session and re-seeded whenever it changes, but advanced
   * locally on a successful save as well: `PUT /topics/my` answers with the
   * saved list and nothing refetches the profile, so without this the chips
   * would snap back to the old set the moment edit mode closed.
   */
  const [savedTopics, setSavedTopics] = useState<string[]>(myTopics);
  const [draft, setDraft] = useState<string[]>(myTopics);
  const [waveTarget, setWaveTarget] = useState<CommunityMemberCard | null>(null);

  const { data: topicsData, isLoading: isLoadingTopics } = useGetTopicsQuery({});
  const [updateMyTopics, { isLoading: isSaving }] = useUpdateMyTopicsMutation();

  const topics: TopicSummary[] = useMemo(() => {
    const raw = topicsData && (topicsData as any).data;
    return Array.isArray(raw) ? raw : [];
  }, [topicsData]);

  /** The session is the source of truth whenever it changes underneath us. */
  useEffect(() => {
    setSavedTopics(myTopics);
  }, [myTopics]);

  useEffect(() => {
    if (!editMode) setDraft(savedTopics);
  }, [savedTopics, editMode]);

  const filteredTopics = useMemo(() => {
    const needle = search.trim().toLowerCase();
    if (!needle) return topics;
    return topics.filter((topic) => {
      const name = String(topic.name || "").toLowerCase();
      const key = topicKey(topic).toLowerCase();
      const category = String(topic.category || "").toLowerCase();
      return (
        name.indexOf(needle) >= 0 ||
        key.indexOf(needle) >= 0 ||
        category.indexOf(needle) >= 0
      );
    });
  }, [topics, search]);

  /** The viewer's topics, resolved to real rows where the list knows them. */
  const myTopicRows = useMemo<TopicSummary[]>(() => {
    const byKey: { [key: string]: TopicSummary } = {};
    topics.forEach((topic) => {
      byKey[topicKey(topic)] = topic;
    });
    return savedTopics.map((id) => byKey[id] || { id, name: id });
  }, [topics, savedTopics]);

  // ---------------------------------------------------------------------
  // The open topic, and its people
  // ---------------------------------------------------------------------

  const activeTopicId = searchParams.get("topic") || "";
  const activeTopic = useMemo<TopicSummary | null>(() => {
    if (!activeTopicId) return null;
    const found = topics.filter((topic) => topicKey(topic) === activeTopicId)[0];
    return found || { id: activeTopicId, name: activeTopicId };
  }, [topics, activeTopicId]);

  const [onlineOnly, setOnlineOnly] = useState(false);

  /**
   * "Which list am I looking at" — the topic plus the online switch.
   *
   * Paging and the accumulated rows are both keyed by it and DERIVED rather
   * than reset in an effect: an effect would leave one render (and therefore
   * one request) in which page 2 of the old list is asked for under the new
   * filter.
   */
  const listKey = `${activeTopicId}|${onlineOnly ? "1" : "0"}`;

  const [paging, setPaging] = useState<{ key: string; page: number }>({
    key: listKey,
    page: 1,
  });
  const page = paging.key === listKey ? paging.page : 1;

  const [accumulated, setAccumulated] = useState<{
    key: string;
    users: CommunityMemberCard[];
  }>({ key: "", users: [] });

  const {
    data: usersData,
    isFetching: isFetchingPeople,
    originalArgs: peopleArgs,
  } = useGetUsersByTopicQuery(
    { topicId: activeTopicId, page, limit: PEOPLE_LIMIT, onlineOnly },
    { skip: !activeTopicId }
  );

  useEffect(() => {
    const rows = usersData && (usersData as any).data;
    if (!Array.isArray(rows)) return;
    const args: any = peopleArgs;
    if (!args) return;
    const argKey = `${args.topicId}|${args.onlineOnly ? "1" : "0"}`;
    if (argKey !== listKey) return;

    setAccumulated((prev) => {
      const base = prev.key === listKey ? prev.users : [];
      const seen: { [id: string]: boolean } = {};
      base.forEach((user) => {
        seen[user._id] = true;
      });
      const added = rows
        .filter((raw: any) => raw && raw._id && !seen[raw._id])
        .map(toMemberCard);
      if (prev.key === listKey && added.length === 0) return prev;
      return { key: listKey, users: base.concat(added) };
    });
  }, [usersData, peopleArgs, listKey]);

  const people = accumulated.key === listKey ? accumulated.users : [];
  const peopleLoaded = accumulated.key === listKey;
  const hasMorePeople = !!(
    usersData &&
    (usersData as any).pagination &&
    (usersData as any).pagination.hasMore
  );

  const openTopic = useCallback(
    (id: string) => {
      const next = new URLSearchParams(searchParams);
      next.set("topic", id);
      setSearchParams(next);
    },
    [searchParams, setSearchParams]
  );

  const closeTopic = useCallback(() => {
    const next = new URLSearchParams(searchParams);
    next.delete("topic");
    setSearchParams(next);
  }, [searchParams, setSearchParams]);

  const loadMorePeople = useCallback(() => {
    setPaging({ key: listKey, page: page + 1 });
  }, [listKey, page]);

  const toggleOnlineOnly = useCallback(() => {
    setOnlineOnly((prev) => !prev);
  }, []);

  const handleOpenMember = useCallback(
    (user: CommunityMemberCard) => {
      navigate(`/community/${user._id}`);
    },
    [navigate]
  );

  const handleWaveMember = useCallback((user: CommunityMemberCard) => {
    setWaveTarget(user);
  }, []);

  // ---------------------------------------------------------------------
  // Editing the viewer's own topics
  // ---------------------------------------------------------------------

  const startEditing = useCallback(() => {
    setDraft(savedTopics);
    setEditMode(true);
  }, [savedTopics]);

  const cancelEditing = useCallback(() => {
    setDraft(savedTopics);
    setEditMode(false);
  }, [savedTopics]);

  const toggleDraft = useCallback((id: string) => {
    setDraft((prev) => {
      if (prev.indexOf(id) >= 0) return prev.filter((x) => x !== id);
      if (prev.length >= MAX_TOPICS) return prev;
      return prev.concat([id]);
    });
  }, []);

  const saveTopics = useCallback(() => {
    const chosen = draft.slice(0, MAX_TOPICS);
    updateMyTopics(chosen)
      .unwrap()
      .then(
        () => {
          setSavedTopics(chosen);
          setEditMode(false);
          // Keep the rest of the app (profile, filters) on the new list
          // rather than only this page: nothing else refetches the session.
          if (userInfo) {
            dispatch(
              setCredentials({
                ...(userInfo as any),
                user: { ...(userInfo as any).user, topics: chosen },
              })
            );
          }
          notify.success(t("topics.saved") || "Your topics are up to date");
        },
        () => {
          notify.error(t("topics.saveError") || "We couldn't save your topics");
        }
      );
  }, [updateMyTopics, draft, t, dispatch, userInfo]);

  const handleTileClick = useCallback(
    (id: string) => {
      if (editMode) toggleDraft(id);
      else openTopic(id);
    },
    [editMode, toggleDraft, openTopic]
  );

  // ---------------------------------------------------------------------
  // Render
  // ---------------------------------------------------------------------

  const ActiveTopicIcon = activeTopic
    ? topicIcon(topicKey(activeTopic), activeTopic.name)
    : Hash;

  const memberCountLabel = (count: number) =>
    t("topics.memberCount", { count }) || `${count} members`;

  const renderTile = (topic: TopicSummary) => {
    const id = topicKey(topic);
    const Icon = topicIcon(id, topic.name);
    const selected = editMode
      ? draft.indexOf(id) >= 0
      : savedTopics.indexOf(id) >= 0;
    const locked = editMode && !selected && draft.length >= MAX_TOPICS;

    return (
      <button
        key={id}
        type="button"
        data-testid={`topic-tile-${id}`}
        aria-pressed={editMode ? selected : undefined}
        disabled={locked}
        onClick={() => handleTileClick(id)}
        className={`block w-full rounded-card text-left transition-transform focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-deep focus-visible:ring-offset-2 ${
          locked ? "cursor-not-allowed opacity-40" : "hover:-translate-y-0.5"
        }`}
      >
        <SurfaceCard
          padding="sm"
          className={`h-full border ${
            selected
              ? "border-brand bg-brand/5 shadow-raised"
              : "border-line hover:shadow-raised"
          }`}
        >
          <div className="flex items-center gap-2.5">
            <span
              className={`grid h-9 w-9 shrink-0 place-items-center rounded-chip ${
                selected ? "bg-brand-deep text-white" : "bg-brand/10 text-brand-deep"
              }`}
            >
              <Icon size={18} aria-hidden />
            </span>
            <span className="min-w-0 flex-1">
              <span className="block truncate font-display text-sm font-semibold text-ink-900">
                {topic.name}
              </span>
              <span className="mt-0.5 block truncate text-xs text-ink-500">
                {memberCountLabel(Number(topic.userCount) || 0)}
              </span>
            </span>
            {editMode && (
              <span
                aria-hidden
                className={`grid h-5 w-5 shrink-0 place-items-center rounded-full border ${
                  selected
                    ? "border-brand-deep bg-brand-deep text-white"
                    : "border-ink-300 text-transparent"
                }`}
              >
                <Check size={12} />
              </span>
            )}
          </div>
        </SurfaceCard>
      </button>
    );
  };

  return (
    <div className="community-page" data-testid="topics-page">
      <div className="community-page__container">
        {/* ---- Page header: same chrome as the community list ---- */}
        <header className="pt-6 pb-4">
          <Link
            to="/communities"
            className="mb-3 inline-flex items-center gap-1.5 text-sm font-semibold text-ink-500 no-underline hover:text-brand-deep"
          >
            <ArrowLeft size={16} aria-hidden />
            {t("topics.backToCommunity") || "Community"}
          </Link>
          <h1 className="flex items-center gap-2 font-display text-2xl font-bold text-ink-900">
            <span className="grid h-9 w-9 place-items-center rounded-chip bg-brand/10 text-brand-deep">
              <Hash size={20} aria-hidden />
            </span>
            {t("topics.title") || "Topics"}
          </h1>
          <p className="mt-1.5 max-w-[52ch] text-sm text-ink-500">
            {t("topics.subtitle") ||
              "Find partners who are into what you're into."}
          </p>

          <div className="relative mt-4 max-w-md">
            <Search
              size={16}
              aria-hidden
              className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-ink-400"
            />
            <input
              type="text"
              data-testid="topics-search"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              aria-label={t("topics.searchPlaceholder") || "Search topics"}
              placeholder={t("topics.searchPlaceholder") || "Search topics"}
              className="w-full rounded-full border border-line bg-surface py-2.5 pl-10 pr-10 text-sm text-ink-900 placeholder:text-ink-400 focus:border-brand focus:outline-none"
            />
            {search && (
              <button
                type="button"
                onClick={() => setSearch("")}
                aria-label={t("topics.clearSearch") || "Clear search"}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-ink-400 hover:text-ink-600"
              >
                <X size={16} aria-hidden />
              </button>
            )}
          </div>
        </header>

        <div className="lg:flex lg:items-start lg:gap-6">
          {/* ---- Left: your topics + the grid ---- */}
          <div className="min-w-0 lg:flex-1">
            {signedIn && (
              <section data-testid="topics-my-section" className="mb-7">
                <div className="mb-3 flex flex-wrap items-center justify-between gap-2">
                  <h2 className="font-display text-base font-bold text-ink-900">
                    {t("topics.myTopics") || "My Topics"}
                  </h2>
                  {editMode ? (
                    <div className="flex items-center gap-2">
                      <button
                        type="button"
                        data-testid="topics-cancel-button"
                        onClick={cancelEditing}
                        className="rounded-full border border-line bg-surface px-3.5 py-1.5 text-sm font-semibold text-ink-600 hover:bg-ink-50"
                      >
                        {t("topics.cancel") || "Cancel"}
                      </button>
                      <button
                        type="button"
                        data-testid="topics-save-button"
                        onClick={saveTopics}
                        disabled={isSaving}
                        className="rounded-full bg-brand-deep px-3.5 py-1.5 text-sm font-semibold text-white hover:bg-brand-deepest disabled:opacity-60"
                      >
                        {isSaving
                          ? t("topics.saving") || "Saving..."
                          : `${t("topics.save") || "Save"} (${draft.length})`}
                      </button>
                    </div>
                  ) : (
                    <button
                      type="button"
                      data-testid="topics-edit-button"
                      onClick={startEditing}
                      className="inline-flex items-center gap-1.5 rounded-full border border-line bg-surface px-3.5 py-1.5 text-sm font-semibold text-ink-700 hover:border-brand hover:text-brand-deep"
                    >
                      <Pencil size={14} aria-hidden />
                      {t("topics.edit") || "Edit"}
                    </button>
                  )}
                </div>

                {editMode ? (
                  <p data-testid="topics-edit-hint" className="text-sm text-ink-500">
                    {t("topics.editHint", { max: MAX_TOPICS }) ||
                      `Tap the tiles below to pick up to ${MAX_TOPICS} topics, then save.`}
                  </p>
                ) : myTopicRows.length === 0 ? (
                  <p className="text-sm text-ink-500">
                    {t("topics.myTopicsEmpty") ||
                      "You haven't picked any topics yet. Edit to choose a few."}
                  </p>
                ) : (
                  <div className="flex flex-wrap gap-2">
                    {myTopicRows.map((topic) => {
                      const id = topicKey(topic);
                      const Icon = topicIcon(id, topic.name);
                      const active = id === activeTopicId;
                      return (
                        <button
                          key={id}
                          type="button"
                          data-testid={`topics-my-chip-${id}`}
                          onClick={() => openTopic(id)}
                          className={`inline-flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-sm font-semibold transition-colors ${
                            active
                              ? "border-brand-deep bg-brand-deep text-white"
                              : "border-brand/40 bg-brand/10 text-brand-deep hover:bg-brand/20"
                          }`}
                        >
                          <Icon size={14} aria-hidden />
                          {topic.name}
                        </button>
                      );
                    })}
                  </div>
                )}
              </section>
            )}

            <section>
              <h2 className="mb-3 font-display text-base font-bold text-ink-900">
                {editMode
                  ? t("topics.selectTopics") || "Choose your topics"
                  : t("topics.browseTopics") || "Browse Topics"}
              </h2>

              {isLoadingTopics ? (
                <div
                  data-testid="topics-skeletons"
                  aria-busy="true"
                  className="grid grid-cols-2 gap-3 md:grid-cols-3 lg:grid-cols-4"
                >
                  {Array.from({ length: TILE_SKELETONS }, (_unused, i) => (
                    <TileSkeleton key={i} />
                  ))}
                </div>
              ) : filteredTopics.length === 0 ? (
                <div data-testid="topics-empty" className="community-empty">
                  <Hash className="community-empty__icon" aria-hidden />
                  <h3>{t("topics.emptyTitle") || "No topics match that"}</h3>
                  <p>
                    {t("topics.emptyMessage") ||
                      "Try a different word, or clear the search to see them all."}
                  </p>
                  {search && (
                    <button
                      type="button"
                      className="community-empty__action"
                      onClick={() => setSearch("")}
                    >
                      {t("topics.clearSearch") || "Clear search"}
                    </button>
                  )}
                </div>
              ) : (
                <div
                  data-testid="topics-grid"
                  className="grid grid-cols-2 gap-3 md:grid-cols-3 lg:grid-cols-4"
                >
                  {filteredTopics.map(renderTile)}
                </div>
              )}
            </section>
          </div>

          {/* ---- Right (desktop) / below the grid (phone): the people ----
              One node, not two: the flex container only turns into a row at
              lg, so the same markup is a side panel on a desktop and a
              full-width section under the grid everywhere else. */}
          {activeTopic && (
            <aside
              data-testid="topic-people"
              className="mt-7 lg:mt-0 lg:sticky lg:top-4 lg:w-[360px] lg:shrink-0"
            >
              <SurfaceCard padding="md" className="border border-line">
                <button
                  type="button"
                  data-testid="topic-people-back"
                  onClick={closeTopic}
                  className="mb-3 inline-flex items-center gap-1.5 text-sm font-semibold text-ink-500 hover:text-brand-deep"
                >
                  <ArrowLeft size={16} aria-hidden />
                  {t("topics.backToTopics") || "All topics"}
                </button>

                <div className="flex items-center gap-2.5">
                  <span className="grid h-10 w-10 shrink-0 place-items-center rounded-chip bg-brand/10 text-brand-deep">
                    <ActiveTopicIcon size={20} aria-hidden />
                  </span>
                  <div className="min-w-0">
                    <h2 className="truncate font-display text-lg font-bold text-ink-900">
                      {activeTopic.name}
                    </h2>
                    <p className="text-xs text-ink-500">
                      {memberCountLabel(Number(activeTopic.userCount) || 0)}
                    </p>
                  </div>
                </div>

                <button
                  type="button"
                  data-testid="topic-people-online-toggle"
                  aria-pressed={onlineOnly}
                  onClick={toggleOnlineOnly}
                  className={`mt-3 inline-flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-sm font-semibold transition-colors ${
                    onlineOnly
                      ? "border-brand-deep bg-brand-deep text-white"
                      : "border-line bg-surface text-ink-600 hover:border-brand"
                  }`}
                >
                  <Radio size={14} aria-hidden />
                  {t("topics.onlineOnly") || "Online only"}
                </button>

                <div className="mt-4 flex flex-col gap-3">
                  {!peopleLoaded && isFetchingPeople ? (
                    <div data-testid="topic-people-skeletons" aria-busy="true">
                      <span className="sr-only">
                        {t("topics.loadingPeople") || "Loading people..."}
                      </span>
                      <div className="flex flex-col gap-3">
                        {Array.from({ length: PEOPLE_SKELETONS }, (_unused, i) => (
                          <PersonSkeleton key={i} />
                        ))}
                      </div>
                    </div>
                  ) : people.length === 0 ? (
                    <div data-testid="topic-people-empty" className="py-8 text-center">
                      <Users size={32} aria-hidden className="mx-auto mb-3 text-ink-300" />
                      <p className="font-display text-sm font-bold text-ink-900">
                        {onlineOnly
                          ? t("topics.noOneOnlineTitle") || "Nobody here is online"
                          : t("topics.noOneTitle") || "Nobody here yet"}
                      </p>
                      <p className="mx-auto mt-1 max-w-[34ch] text-xs text-ink-500">
                        {onlineOnly
                          ? t("topics.noOneOnlineMessage") ||
                            "Turn the online filter off to see everyone in this topic."
                          : t("topics.noOneMessage") ||
                            "Be the first — add this topic to your profile."}
                      </p>
                    </div>
                  ) : (
                    <>
                      {people.map((person) => (
                        <MemberCard
                          key={person._id}
                          user={person}
                          onOpen={handleOpenMember}
                          onWave={handleWaveMember}
                        />
                      ))}
                      {hasMorePeople && (
                        <button
                          type="button"
                          data-testid="topic-people-loadmore"
                          onClick={loadMorePeople}
                          disabled={isFetchingPeople}
                          className="mx-auto mt-1 rounded-full border border-line bg-surface px-6 py-2.5 text-sm font-semibold text-ink-700 hover:border-brand hover:text-brand-deep disabled:opacity-60"
                        >
                          {isFetchingPeople
                            ? t("communityMain.loadMore.loading") || "Loading..."
                            : t("communityMain.loadMore.button") || "Load more"}
                        </button>
                      )}
                    </>
                  )}
                </div>
              </SurfaceCard>
            </aside>
          )}
        </div>
      </div>

      <WaveSheet
        open={!!waveTarget}
        targetUser={waveTarget}
        onClose={() => setWaveTarget(null)}
      />
    </div>
  );
};

export default Topics;
