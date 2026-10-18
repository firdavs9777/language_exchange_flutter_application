import React, { useEffect, useMemo, useState } from "react";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { X, Loader2, Users, Link2, Lock } from "lucide-react";
import { RootState } from "../../store";
import { COMMON_LANGUAGES } from "./type";
import { languageOptions, LanguageOption } from "./lib/languageOptions";
import {
  CommunityFilters,
  Me,
  buildCommunityQuery,
  withoutVipOnlyFilters,
} from "./lib/buildCommunityQuery";
import { DEFAULT_FILTERS } from "./lib/filterStorage";
import { countryOptions } from "./lib/countries";
import {
  useGetCommunityCountQuery,
  useGetLanguagesQuery,
  useGetTopicsQuery,
} from "../../store/slices/communitySlice";

const GENDER_OPTIONS: { value: CommunityFilters["gender"]; label: string }[] = [
  { value: undefined, label: "Any" },
  { value: "male", label: "Male" },
  { value: "female", label: "Female" },
  { value: "other", label: "Other" },
];

const CEFR_LEVELS = ["Any", "A1", "A2", "B1", "B2", "C1", "C2"];

const MIN_AGE_BOUND = 18;
const MAX_AGE_BOUND = 100;
const MAX_TOPICS_AT_LEAST = 10;
// The count is a whole extra round trip per edit, and nobody reads it while
// they are still dragging a slider. 400ms is long enough that a drag or a
// typed country produces one request rather than a dozen.
const DEBOUNCE_MS = 400;

interface TopicOption {
  id: string;
  name: string;
  icon?: string;
}

export interface CommunityFilterSheetProps {
  open: boolean;
  value: CommunityFilters;
  onChange: (next: CommunityFilters) => void;
  onApply: (filters: CommunityFilters) => void;
  onClear: () => void;
  onClose: () => void;
  /**
   * Copy a link to the list as it is *applied* — what the page behind this
   * sheet is actually showing. Optional: the button only appears when the page
   * can produce a link at all (the owner of the URL state is MainCommunity,
   * not the sheet).
   */
  onCopyLink?: () => void;
  /**
   * False while the draft on screen differs from the applied filters. A link
   * can only describe a list that exists, so rather than quietly copying
   * something other than what the member is looking at, the button says what
   * to do first.
   */
  canCopyLink?: boolean;
  /**
   * The tab that is holding one of these switches down, if any.
   *
   * On Online and New the list is locked to that condition, and the sheet has
   * to say so: an "Online now" toggle the member can turn off, only for the
   * tab to turn it straight back on after Apply, is a dead control. The
   * matching switch is disabled with a one-line explanation, and the live
   * count is measured with the lock applied so the number matches the list
   * they would get.
   */
  lockedTab?: "online" | "new" | "serious";
  /**
   * Country is a VIP filter (GET /users ignores it for free callers). For a
   * free viewer the picker is disabled behind a VIP badge that calls
   * `onUpgrade`, and the live count is measured without it.
   */
  isVip?: boolean;
  onUpgrade?: () => void;
}

/** Small pill toggle switch (teal when on) — no new CSS, Tailwind only. */
const ToggleSwitch: React.FC<{
  checked: boolean;
  onChange: (checked: boolean) => void;
  label: string;
  disabled?: boolean;
  hint?: string;
  hintTestId?: string;
}> = ({ checked, onChange, label, disabled = false, hint, hintTestId }) => (
  <div className="py-1">
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      disabled={disabled}
      onClick={() => {
        if (!disabled) onChange(!checked);
      }}
      className={`w-full flex items-center justify-between py-2 ${
        disabled ? "cursor-not-allowed opacity-60" : ""
      }`}
    >
      <span className="text-sm text-gray-700">{label}</span>
      <span
        className={`relative inline-flex h-6 w-11 flex-shrink-0 items-center rounded-full transition-colors ${
          checked ? "bg-teal-500" : "bg-gray-300"
        }`}
      >
        <span
          className={`inline-block h-5 w-5 transform rounded-full bg-white shadow transition-transform ${
            checked ? "translate-x-5" : "translate-x-0.5"
          }`}
        />
      </span>
    </button>
    {hint && (
      <p data-testid={hintTestId} className="m-0 pb-2 text-xs text-gray-500">
        {hint}
      </p>
    )}
  </div>
);

const CommunityFilterSheet: React.FC<CommunityFilterSheetProps> = ({
  open,
  value,
  onChange,
  onApply,
  onClear,
  onClose,
  onCopyLink,
  canCopyLink = true,
  lockedTab,
  isVip = false,
  onUpgrade,
}) => {
  const { t, i18n } = useTranslation();
  // Labels in the reader's language; recomputed only when it changes.
  const uiLocale = (i18n && i18n.language) || "en";
  const countries = useMemo(() => countryOptions(uiLocale), [uiLocale]);
  // The whole catalog (GET /languages, the list the app filters on), labelled
  // in the reader's language. Until it arrives — or if it fails — the ten
  // common languages keep the filter usable rather than empty.
  const { data: languagesResult } = useGetLanguagesQuery(undefined, { skip: !open });
  const catalogLanguages = useMemo<LanguageOption[]>(() => {
    const built = languageOptions(languagesResult && languagesResult.data, uiLocale);
    if (built.length > 0) return built;
    return COMMON_LANGUAGES.map((name) => ({ value: name as string, label: name as string }));
  }, [languagesResult, uiLocale]);

  /** The list, plus a value from an old link or saved filter it no longer has. */
  const languageChoices = (current?: string): LanguageOption[] =>
    current && !catalogLanguages.some((option) => option.value === current)
      ? [{ value: current, label: current }].concat(catalogLanguages)
      : catalogLanguages;

  const me = useSelector(
    (state: RootState) => state.auth.userInfo?.user
  ) as Me | undefined;

  // --- Live debounced match count -------------------------------------------------
  const [debouncedValue, setDebouncedValue] = useState<CommunityFilters>(value);
  useEffect(() => {
    if (!open) return;
    const handle = setTimeout(() => setDebouncedValue(value), DEBOUNCE_MS);
    return () => clearTimeout(handle);
  }, [value, open]);

  /**
   * The draft as the *list* would see it: the tab's lock is part of what is
   * applied, so a count taken without it would promise a number the member
   * cannot get from where they are standing.
   */
  const lockedDraft = useMemo<CommunityFilters>(() => {
    const draft = withoutVipOnlyFilters(debouncedValue, isVip);
    if (lockedTab === "online") return { ...draft, onlineOnly: true };
    if (lockedTab === "new") return { ...draft, newUsersOnly: true };
    if (lockedTab === "serious") return { ...draft, activeWithin: "7d" };
    return draft;
  }, [debouncedValue, lockedTab, isVip]);

  const countQuery = useMemo(
    () => buildCommunityQuery(lockedDraft, me || {}, 1, 1),
    [lockedDraft, me]
  );

  const { data: countResult, isFetching: isCountLoading } = useGetCommunityCountQuery(
    countQuery,
    { skip: !open }
  );
  // `countResult` is destructured from the hook's `.data` (line above), so it
  // is already the response body `{ success, data: { count } }` (this endpoint
  // has no transformResponse). The count therefore lives at `.data.count`.
  const matchCount: number | undefined = countResult?.data?.count;

  /** "Set by the Online tab" -- one line, only where the lock actually is. */
  const lockHint = useMemo(() => {
    if (!lockedTab) return undefined;
    const tabName =
      lockedTab === "online"
        ? t("communityMain.tabs.online") || "Online"
        : t("communityMain.tabs.new") || "New";
    return (
      t("communityMain.filterSheet.lockedByTab", { tab: tabName }) ||
      `Set by the ${tabName} tab`
    );
  }, [lockedTab, t]);

  // --- Topics ----------------------------------------------------------------------
  const { data: topicsResult } = useGetTopicsQuery({}, { skip: !open });
  const topicOptions: TopicOption[] = useMemo(() => {
    const raw = topicsResult?.data;
    if (!Array.isArray(raw)) return [];
    return raw.map((topic: any) => ({
      id: topic._id || topic.id || topic.name,
      name: topic.name,
      icon: topic.icon,
    }));
  }, [topicsResult]);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, onClose]);

  if (!open) return null;

  const set = <K extends keyof CommunityFilters>(key: K, val: CommunityFilters[K]) => {
    onChange({ ...value, [key]: val });
  };

  const toggleTopic = (topicId: string) => {
    const current = value.topics || [];
    const next = current.includes(topicId)
      ? current.filter((topic) => topic !== topicId)
      : [...current, topicId];
    set("topics", next);
  };

  const handleApply = () => {
    onApply(value);
  };

  const handleClearAll = () => {
    onChange({ ...DEFAULT_FILTERS });
    onClear();
  };

  const minAge = value.minAge ?? MIN_AGE_BOUND;
  const maxAge = value.maxAge ?? MAX_AGE_BOUND;

  return (
    <div
      className="fixed inset-0 z-50 flex items-end sm:items-center justify-center"
      role="dialog"
      aria-modal="true"
      aria-label={t("communityMain.filterSheet.title") || "Filters"}
    >
      <div
        className="absolute inset-0 bg-black/40 backdrop-blur-sm"
        onClick={onClose}
      />

      <div className="relative w-full sm:max-w-lg max-h-[90vh] bg-white rounded-t-3xl sm:rounded-3xl shadow-2xl flex flex-col overflow-hidden">
        {/* Header */}
        <div className="bg-gradient-to-r from-teal-500 to-teal-600 text-white px-5 py-4 flex items-center justify-between">
          <div>
            <h2 className="text-lg font-semibold">
              {t("communityMain.filterSheet.title") || "Filters"}
            </h2>
            <div className="flex items-center gap-1.5 text-sm text-teal-50 mt-0.5">
              {isCountLoading ? (
                <Loader2 className="w-3.5 h-3.5 animate-spin" />
              ) : (
                <Users className="w-3.5 h-3.5" />
              )}
              <span>
                {matchCount !== undefined
                  ? (t("communityMain.filterSheet.matchCount", { count: matchCount }) ||
                    `${matchCount} matches`)
                  : t("communityMain.filterSheet.matchCountLoading") || "Counting matches…"}
              </span>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label={t("communityMain.filterSheet.close") || "Close filters"}
            className="p-2 hover:bg-white/10 rounded-full transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto px-5 py-4 space-y-5">
          {/* Age range */}
          <section>
            <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-2">
              {t("communityMain.filterSheet.ageRange") || "Age range"}
            </h3>
            <div className="flex items-center justify-between text-sm text-gray-600 mb-1">
              <span>{minAge}</span>
              <span>{maxAge}</span>
            </div>
            <div className="space-y-2">
              <input
                type="range"
                min={MIN_AGE_BOUND}
                max={MAX_AGE_BOUND}
                value={minAge}
                onChange={(e) => {
                  const next = Math.min(Number(e.target.value), maxAge);
                  set("minAge", next);
                }}
                className="w-full accent-teal-500"
                aria-label={t("communityMain.filterSheet.min") || "Minimum age"}
              />
              <input
                type="range"
                min={MIN_AGE_BOUND}
                max={MAX_AGE_BOUND}
                value={maxAge}
                onChange={(e) => {
                  const next = Math.max(Number(e.target.value), minAge);
                  set("maxAge", next);
                }}
                className="w-full accent-teal-500"
                aria-label={t("communityMain.filterSheet.max") || "Maximum age"}
              />
            </div>
          </section>

          {/* Gender */}
          <section>
            <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-2">
              {t("communityMain.filterSheet.gender") || "Gender"}
            </h3>
            <div className="flex flex-wrap gap-2">
              {GENDER_OPTIONS.map((option) => {
                const active = value.gender === option.value;
                return (
                  <button
                    key={option.label}
                    type="button"
                    onClick={() => set("gender", option.value)}
                    className={`px-4 py-2 rounded-full text-sm font-medium transition-all ${
                      active
                        ? "bg-teal-500 text-white"
                        : "bg-gray-100 text-gray-600 hover:bg-gray-200"
                    }`}
                  >
                    {t(`communityMain.filterSheet.${(option.value || "any")}`) || option.label}
                  </button>
                );
              })}
            </div>
          </section>

          {/* Languages */}
          <section>
            <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-2">
              {t("communityMain.filterSheet.languages") || "Languages"}
            </h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label className="text-xs text-gray-500 mb-1 block">
                  {t("communityMain.filterSheet.partnerNative") || "Partner's native language"}
                </label>
                <select
                  value={value.nativeLanguage || ""}
                  onChange={(e) => set("nativeLanguage", e.target.value || undefined)}
                  className="w-full px-3 py-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-teal-400 focus:border-transparent"
                >
                  <option value="">{t("communityMain.filterSheet.any") || "Any"}</option>
                  {languageChoices(value.nativeLanguage).map((option) => (
                    <option key={option.value} value={option.value}>
                      {option.label}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="text-xs text-gray-500 mb-1 block">
                  {t("communityMain.filterSheet.partnerLearning") || "Partner is learning"}
                </label>
                <select
                  value={value.learningLanguage || ""}
                  onChange={(e) => set("learningLanguage", e.target.value || undefined)}
                  className="w-full px-3 py-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-teal-400 focus:border-transparent"
                >
                  <option value="">{t("communityMain.filterSheet.any") || "Any"}</option>
                  {languageChoices(value.learningLanguage).map((option) => (
                    <option key={option.value} value={option.value}>
                      {option.label}
                    </option>
                  ))}
                </select>
              </div>
            </div>
          </section>

          {/* Country */}
          <section>
            <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-2 flex items-center gap-2">
              {t("communityMain.filterSheet.country") || "Country"}
              {!isVip && (
                <button
                  type="button"
                  data-testid="filter-country-vip"
                  onClick={onUpgrade}
                  aria-label={
                    t("communityMain.filterSheet.countryVipOnly") ||
                    "Country filter is a VIP feature"
                  }
                  className="inline-flex items-center gap-1 normal-case tracking-normal text-[11px] font-bold text-black bg-gradient-to-r from-[#FFD700] to-[#FFA500] rounded-full px-2 py-0.5"
                >
                  <Lock className="w-3 h-3" aria-hidden />
                  VIP
                </button>
              )}
            </h3>
            {!isVip && (
              <p className="text-xs text-gray-500 mb-2">
                {t("communityMain.filterSheet.countryVipOnly") || "Country filter is a VIP feature"}
              </p>
            )}
            {/* A list of real countries, labelled in the reader's language,
                each sending its English name -- what the server stores and
                matches exactly. The text box it replaces was matched by
                substring, so "Korea" found both Koreas. */}
            <select
              data-testid="filter-country"
              disabled={!isVip}
              value={isVip ? value.country || "" : ""}
              onChange={(e) => set("country", e.target.value || undefined)}
              aria-label={t("communityMain.filterSheet.country") || "Country"}
              className="w-full px-3 py-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-teal-400 focus:border-transparent disabled:opacity-60 disabled:cursor-not-allowed"
            >
              <option value="">{t("communityMain.filterSheet.any") || "Any"}</option>
              {value.country &&
                !countries.some((option) => option.value === value.country) && (
                  // Kept from a link or saved filter from the text-box days.
                  <option value={value.country}>{value.country}</option>
                )}
              {countries.map((option) => (
                <option key={option.code} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
          </section>

          {/* CEFR level */}
          <section>
            <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-2">
              {t("communityMain.filterSheet.level") || "Language level"}
            </h3>
            <div className="flex flex-wrap gap-2">
              {CEFR_LEVELS.map((level) => {
                const active = level === "Any" ? !value.languageLevel : value.languageLevel === level;
                return (
                  <button
                    key={level}
                    type="button"
                    onClick={() => set("languageLevel", level === "Any" ? undefined : level)}
                    className={`px-4 py-2 rounded-full text-sm font-medium transition-all ${
                      active
                        ? "bg-teal-500 text-white"
                        : "bg-gray-100 text-gray-600 hover:bg-gray-200"
                    }`}
                  >
                    {level}
                  </button>
                );
              })}
            </div>
          </section>

          {/* Topics */}
          {topicOptions.length > 0 && (
            <section>
              <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-2">
                {t("communityMain.filterSheet.topics") || "Topics"}
              </h3>
              <div className="flex flex-wrap gap-2">
                {topicOptions.map((topic) => {
                  const active = (value.topics || []).includes(topic.id);
                  return (
                    <button
                      key={topic.id}
                      type="button"
                      onClick={() => toggleTopic(topic.id)}
                      className={`px-3 py-2 rounded-full text-sm font-medium transition-all ${
                        active
                          ? "bg-teal-500 text-white"
                          : "bg-gray-100 text-gray-600 hover:bg-gray-200"
                      }`}
                    >
                      {topic.icon ? `${topic.icon} ` : ""}
                      {topic.name}
                    </button>
                  );
                })}
              </div>
            </section>
          )}

          {/* Mutual interests slider */}
          <section>
            <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-2">
              {t("communityMain.filterSheet.mutualInterests") || "Mutual interests (at least)"}
            </h3>
            <div className="flex items-center gap-3">
              <input
                type="range"
                min={0}
                max={MAX_TOPICS_AT_LEAST}
                value={value.topicsAtLeast ?? 0}
                onChange={(e) => set("topicsAtLeast", Number(e.target.value) || undefined)}
                className="w-full accent-teal-500"
                aria-label={t("communityMain.filterSheet.mutualInterests") || "Mutual interests"}
              />
              <span className="text-sm font-medium text-gray-600 w-6 text-right">
                {value.topicsAtLeast ?? 0}
              </span>
            </div>
          </section>

          {/* Toggles. One of them may belong to the tab rather than to the
              member -- see `lockedTab`. */}
          <section className="divide-y divide-gray-100">
            <ToggleSwitch
              checked={lockedTab === "online" ? true : !!value.onlineOnly}
              onChange={(checked) => set("onlineOnly", checked || undefined)}
              label={t("communityMain.filterSheet.onlineNow") || "Online now"}
              disabled={lockedTab === "online"}
              hint={lockedTab === "online" ? lockHint : undefined}
              hintTestId="filter-sheet-online-locked"
            />
            <ToggleSwitch
              checked={lockedTab === "new" ? true : !!value.newUsersOnly}
              onChange={(checked) => set("newUsersOnly", checked || undefined)}
              label={t("communityMain.filterSheet.newUsersOnly") || "New users only"}
              disabled={lockedTab === "new"}
              hint={lockedTab === "new" ? lockHint : undefined}
              hintTestId="filter-sheet-new-locked"
            />
            <ToggleSwitch
              checked={!!value.reciprocal}
              onChange={(checked) => set("reciprocal", checked || undefined)}
              label={t("communityMain.filterSheet.reciprocal") || "Perfect partners only"}
              hint={
                t("communityMain.filterSheet.reciprocalHint") ||
                "They speak what you learn and learn what you speak"
              }
              hintTestId="filter-sheet-reciprocal-hint"
            />
          </section>
        </div>

        {/* Footer */}
        <div className="px-5 py-4 border-t border-gray-100 space-y-3">
          {onCopyLink && (
            <button
              type="button"
              onClick={onCopyLink}
              disabled={!canCopyLink}
              title={
                canCopyLink
                  ? undefined
                  : t("communityMain.filterSheet.applyFirst") || "Apply filters first"
              }
              className="w-full flex items-center justify-center gap-2 py-2.5 rounded-xl font-medium text-teal-700 bg-teal-50 hover:bg-teal-100 transition-colors disabled:opacity-60 disabled:cursor-not-allowed disabled:hover:bg-teal-50"
            >
              <Link2 className="w-4 h-4" />
              {canCopyLink
                ? t("communityMain.filterSheet.copyLink") || "Copy link"
                : t("communityMain.filterSheet.applyFirst") || "Apply filters first"}
            </button>
          )}
          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={handleClearAll}
              className="flex-1 py-3 rounded-xl font-medium text-gray-600 bg-gray-100 hover:bg-gray-200 transition-colors"
            >
              {t("communityMain.filterSheet.clearAll") || "Clear all"}
            </button>
            <button
              type="button"
              onClick={handleApply}
              className="flex-1 py-3 rounded-xl font-medium text-white bg-gradient-to-r from-teal-500 to-teal-600 hover:from-teal-600 hover:to-teal-700 transition-colors shadow-md"
            >
              {t("communityMain.filterSheet.apply") || "Apply"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CommunityFilterSheet;
