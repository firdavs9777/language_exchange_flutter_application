import React, { useEffect, useMemo, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { useTranslation } from "react-i18next";
import {
  useGetGatheringsQuery,
  useGetClubsQuery,
  GATHERING_TOPICS,
  Gathering,
  Club,
} from "../../store/slices/gatheringsSlice";
import { useGetLanguagesQuery } from "../../store/slices/communitySlice";
import { languageOptions } from "../community/lib/languageOptions";
import GatheringCard from "./GatheringCard";
import ClubCard from "./ClubCard";
import { topicLabel } from "./lib/gatheringFormat";
import Loader from "../Loader";

const PAGE_SIZE = 30; // the server's default `limit` (controllers/gatherings.js)

type Tab = "gatherings" | "clubs";
type GScope = "mine" | "all" | "me";
type CScope = "mine" | "all" | "member";

const chip = (active: boolean) =>
  `rounded-full px-3 py-1 text-sm font-bold ${
    active ? "bg-brand text-white" : "bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-200"
  }`;

/** Accumulates pages of one list; resets whenever `key` (the filters) changes. */
function usePaged<T extends { _id: string }>(key: string, page: number, data: T[] | undefined): T[] {
  const [items, setItems] = useState<T[]>([]);
  useEffect(() => {
    setItems([]);
  }, [key]);
  useEffect(() => {
    if (!data) return;
    setItems((prev) => {
      if (page === 1) return data;
      const seen = new Set(prev.map((x) => x._id));
      return prev.concat(data.filter((x) => !seen.has(x._id)));
    });
  }, [data, page]);
  return items;
}

const GatheringsHome: React.FC<{ initialTab?: Tab }> = ({ initialTab }) => {
  const { t, i18n } = useTranslation();
  const [params, setParams] = useSearchParams();
  const tab: Tab = params.get("tab") === "clubs" || (!params.get("tab") && initialTab === "clubs") ? "clubs" : "gatherings";
  const setTab = (next: Tab) => {
    const p = new URLSearchParams(params);
    if (next === "clubs") p.set("tab", "clubs");
    else p.delete("tab");
    setParams(p, { replace: true });
  };

  // ---- gatherings filters
  const [scope, setScope] = useState<GScope>("mine");
  const [topic, setTopic] = useState("");
  const [when, setWhen] = useState<"" | "today" | "week">("");
  const [hasSeat, setHasSeat] = useState(false);
  const [language, setLanguage] = useState("");
  const [page, setPage] = useState(1);
  const filterKey = [scope, topic, when, hasSeat, language].join("|");
  useEffect(() => setPage(1), [filterKey]);

  const gq = useGetGatheringsQuery(
    { scope, page, topic, when, hasSeat, language },
    { skip: tab !== "gatherings" }
  );
  const gatherings = usePaged<Gathering>(filterKey, page, gq.data);

  // ---- clubs filters
  const [clubScope, setClubScope] = useState<CScope>("mine");
  const [clubPage, setClubPage] = useState(1);
  useEffect(() => setClubPage(1), [clubScope]);
  const cq = useGetClubsQuery({ scope: clubScope, page: clubPage }, { skip: tab !== "clubs" });
  const clubs = usePaged<Club>(clubScope, clubPage, cq.data);

  const { data: catalog } = useGetLanguagesQuery();
  const langs = useMemo(
    () => languageOptions((catalog && catalog.data) || [], i18n.language),
    [catalog, i18n.language]
  );

  const active = tab === "gatherings" ? gq : cq;
  const lastPageFull = Array.isArray(active.data) && active.data.length >= PAGE_SIZE;

  return (
    <section className="mx-auto max-w-3xl px-4 py-6" data-testid="gatherings-home">
      <div className="flex items-center gap-3">
        <h1 className="text-2xl font-extrabold text-gray-900 dark:text-gray-50">
          {t("gatherings.home.title") || "Gatherings"}
        </h1>
        <div className="ms-auto">
          {tab === "gatherings" ? (
            <Link to="/gatherings/new" data-testid="host-gathering-link" className="rounded-full bg-brand px-4 py-2 text-sm font-extrabold text-white no-underline">
              {t("gatherings.home.host") || "Host a gathering"}
            </Link>
          ) : (
            <Link to="/clubs/new" data-testid="start-club-link" className="rounded-full bg-brand px-4 py-2 text-sm font-extrabold text-white no-underline">
              {t("clubs.home.start") || "Start a club"}
            </Link>
          )}
        </div>
      </div>

      <div role="tablist" className="mt-4 flex gap-2 border-b border-gray-200 dark:border-gray-700">
        <button
          type="button"
          role="tab"
          aria-selected={tab === "gatherings"}
          data-testid="gatherings-tab"
          className={`px-3 py-2 text-sm font-extrabold ${tab === "gatherings" ? "border-b-2 border-brand text-brand-dark" : "text-gray-500"}`}
          onClick={() => setTab("gatherings")}
        >
          {t("gatherings.home.tabGatherings") || "Gatherings"}
        </button>
        <button
          type="button"
          role="tab"
          aria-selected={tab === "clubs"}
          data-testid="clubs-tab"
          className={`px-3 py-2 text-sm font-extrabold ${tab === "clubs" ? "border-b-2 border-brand text-brand-dark" : "text-gray-500"}`}
          onClick={() => setTab("clubs")}
        >
          {t("gatherings.home.tabClubs") || "Clubs"}
        </button>
      </div>

      {tab === "gatherings" ? (
        <>
          <div className="mt-4 flex flex-wrap gap-2">
            {(["mine", "all", "me"] as GScope[]).map((s) => (
              <button key={s} type="button" data-testid={`gatherings-scope-${s}`} className={chip(scope === s)} onClick={() => setScope(s)}>
                {s === "mine"
                  ? t("gatherings.home.scopeMine") || "My languages"
                  : s === "all"
                  ? t("gatherings.home.scopeAll") || "All"
                  : t("gatherings.home.scopeMe") || "My gatherings"}
              </button>
            ))}
          </div>
          <div className="mt-3 flex flex-wrap items-center gap-2 text-sm">
            <select
              data-testid="gatherings-filter-topic"
              aria-label={t("gatherings.home.topic") || "Topic"}
              value={topic}
              onChange={(e) => setTopic(e.target.value)}
              className="rounded-lg border border-gray-300 px-2 py-1 dark:border-gray-600 dark:bg-gray-900"
            >
              <option value="">{t("gatherings.home.anyTopic") || "Any topic"}</option>
              {GATHERING_TOPICS.map((k) => (
                <option key={k} value={k}>
                  {topicLabel(k, t)}
                </option>
              ))}
            </select>
            <select
              data-testid="gatherings-filter-when"
              aria-label={t("gatherings.home.when") || "When"}
              value={when}
              onChange={(e) => setWhen(e.target.value as any)}
              className="rounded-lg border border-gray-300 px-2 py-1 dark:border-gray-600 dark:bg-gray-900"
            >
              <option value="">{t("gatherings.home.anyTime") || "Any time"}</option>
              <option value="today">{t("gatherings.home.today") || "Today"}</option>
              <option value="week">{t("gatherings.home.week") || "This week"}</option>
            </select>
            <select
              data-testid="gatherings-filter-language"
              aria-label={t("gatherings.home.language") || "Language"}
              value={language}
              onChange={(e) => setLanguage(e.target.value)}
              className="rounded-lg border border-gray-300 px-2 py-1 dark:border-gray-600 dark:bg-gray-900"
            >
              <option value="">{t("gatherings.home.anyLanguage") || "My languages"}</option>
              {langs.map((o: { value: string; label: string }) => (
                <option key={o.value} value={o.value}>
                  {o.label}
                </option>
              ))}
            </select>
            <label className="flex items-center gap-1">
              <input type="checkbox" data-testid="gatherings-filter-seat" checked={hasSeat} onChange={() => setHasSeat(!hasSeat)} />
              {t("gatherings.home.hasSeat") || "Has a free seat"}
            </label>
          </div>
        </>
      ) : (
        <div className="mt-4 flex flex-wrap gap-2">
          {(["mine", "all", "member"] as CScope[]).map((s) => (
            <button key={s} type="button" data-testid={`clubs-scope-${s}`} className={chip(clubScope === s)} onClick={() => setClubScope(s)}>
              {s === "mine"
                ? t("clubs.home.scopeMine") || "My languages"
                : s === "all"
                ? t("clubs.home.scopeAll") || "All"
                : t("clubs.home.scopeMember") || "Joined"}
            </button>
          ))}
        </div>
      )}

      <div className="mt-4 grid gap-3">
        {active.isError && (
          <div data-testid="gatherings-error" className="rounded-xl bg-red-50 p-4 text-sm text-red-800">
            {t("gatherings.home.error") || "Couldn't load this list."}{" "}
            <button type="button" className="font-bold underline" onClick={() => active.refetch()}>
              {t("gatherings.home.retry") || "Try again"}
            </button>
          </div>
        )}
        {active.isLoading && <Loader />}

        {tab === "gatherings" &&
          gatherings.map((g) => <GatheringCard key={g._id} gathering={g} />)}
        {tab === "clubs" && clubs.map((c) => <ClubCard key={c._id} club={c} />)}

        {tab === "gatherings" && !gq.isLoading && !gq.isError && gq.data && gatherings.length === 0 && (
          <div data-testid="gatherings-empty" className="rounded-2xl bg-gray-50 p-6 text-center dark:bg-gray-800">
            <p className="font-bold">{t("gatherings.home.empty") || "Nothing scheduled here yet."}</p>
            <Link to="/gatherings/new" data-testid="host-gathering-link" className="mt-3 inline-block font-extrabold text-brand-dark">
              {t("gatherings.home.emptyCta") || "Host the first one"}
            </Link>
          </div>
        )}
        {tab === "clubs" && !cq.isLoading && !cq.isError && cq.data && clubs.length === 0 && (
          <div data-testid="clubs-empty" className="rounded-2xl bg-gray-50 p-6 text-center dark:bg-gray-800">
            <p className="font-bold">{t("clubs.home.empty") || "No clubs here yet."}</p>
          </div>
        )}

        {lastPageFull && !active.isFetching && (
          <button
            type="button"
            data-testid="gatherings-load-more"
            className="rounded-full border-2 border-brand px-4 py-2 text-sm font-extrabold text-brand-dark"
            onClick={() => (tab === "gatherings" ? setPage(page + 1) : setClubPage(clubPage + 1))}
          >
            {t("gatherings.home.loadMore") || "Load more"}
          </button>
        )}
      </div>
    </section>
  );
};

export default GatheringsHome;
