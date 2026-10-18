import { AdminAnnouncement, AnnouncementDisplayStyle, AnnouncementInput, AnnouncementPlatform } from "../../../store/slices/adminSlice";

/**
 * The announcement editor's form model. Every rule here mirrors
 * models/Announcement.js in the backend, so an admin learns about a too-long
 * title before the round trip, not after it.
 */

/** lib/normalizeLocale.js SUPPORTED_LOCALES, in the order the editor shows them. */
export const ANNOUNCEMENT_LOCALES = [
  "en", "ko", "ja", "zh", "zh_TW", "es", "fr", "de", "pt", "ru",
  "ar", "hi", "id", "it", "th", "tl", "tr", "vi", "tg",
];

export const LOCALE_LABELS: { [code: string]: string } = {
  en: "English", ko: "Korean", ja: "Japanese", zh: "Chinese (Simplified)", zh_TW: "Chinese (Traditional)",
  es: "Spanish", fr: "French", de: "German", pt: "Portuguese", ru: "Russian", ar: "Arabic", hi: "Hindi",
  id: "Indonesian", it: "Italian", th: "Thai", tl: "Tagalog", tr: "Turkish", vi: "Vietnamese", tg: "Tajik",
};

export const ANNOUNCEMENT_LIMITS = { title: 100, body: 1000, buttonLabel: 40, buttonUrl: 500, emoji: 16 };

export const BUTTON_URL_RE = /^(https?:\/\/[^\s/?#]+\S*|bananatalk:\/\/\S+)$/;

export interface TranslationDraft {
  title: string;
  body: string;
  buttonLabel: string;
}

export interface AnnouncementForm {
  translations: { [locale: string]: TranslationDraft };
  defaultLocale: string;
  emoji: string;
  imageUrl: string;
  buttonUrl: string;
  platforms: AnnouncementPlatform[];
  displayStyle: AnnouncementDisplayStyle;
  languages: string[];
  /** `<input type="datetime-local">` values, in the admin's local time. */
  startsAt: string;
  endsAt: string;
  priority: string;
  showInApp: boolean;
  notify: boolean;
}

export type FormErrors = { [field: string]: string };

export const blankTranslation = (): TranslationDraft => ({ title: "", body: "", buttonLabel: "" });

export const emptyForm = (): AnnouncementForm => ({
  translations: { en: blankTranslation() },
  defaultLocale: "en",
  emoji: "📢",
  imageUrl: "",
  buttonUrl: "",
  platforms: ["all"],
  displayStyle: "popup",
  languages: [],
  startsAt: "",
  endsAt: "",
  priority: "0",
  showInApp: true,
  notify: false,
});

const two = (n: number) => ("0" + n).slice(-2);

export const toLocalInput = (iso: string | null | undefined): string => {
  if (!iso) return "";
  const d = new Date(iso);
  if (isNaN(d.getTime())) return "";
  return `${d.getFullYear()}-${two(d.getMonth() + 1)}-${two(d.getDate())}T${two(d.getHours())}:${two(d.getMinutes())}`;
};

export const fromLocalInput = (value: string): string | null => {
  if (!value) return null;
  const d = new Date(value);
  return isNaN(d.getTime()) ? null : d.toISOString();
};

export const fromAnnouncement = (a: AdminAnnouncement): AnnouncementForm => {
  const translations: { [locale: string]: TranslationDraft } = {};
  Object.keys(a.translations || {}).forEach((locale) => {
    const t = a.translations[locale];
    translations[locale] = { title: t.title || "", body: t.body || "", buttonLabel: t.buttonLabel || "" };
  });
  return {
    translations,
    defaultLocale: a.defaultLocale || "en",
    emoji: a.emoji || "",
    imageUrl: a.imageUrl || "",
    buttonUrl: a.buttonUrl || "",
    platforms: a.platforms && a.platforms.length ? a.platforms : ["all"],
    displayStyle: a.displayStyle === "banner" ? "banner" : "popup",
    languages: a.languages || [],
    startsAt: toLocalInput(a.startsAt),
    endsAt: toLocalInput(a.endsAt),
    priority: String(a.priority || 0),
    showInApp: a.showInApp !== false,
    notify: !!a.notify,
  };
};

/** Same rule as backend lib/announcementReach.js: only these may notify or reach the app. */
export const reachesApp = (f: Pick<AnnouncementForm, "platforms" | "displayStyle">): boolean =>
  f.displayStyle !== "banner" &&
  (f.platforms.length === 0 || f.platforms.some((p) => p === "all" || p === "ios" || p === "android"));

const hasText = (t: TranslationDraft | undefined) =>
  !!t && (t.title.trim() !== "" || t.body.trim() !== "" || t.buttonLabel.trim() !== "");

/** `liveOnly`: a live announcement may change only text, end time and priority. */
export const toInput = (form: AnnouncementForm, liveOnly = false): AnnouncementInput => {
  const translations: { [locale: string]: TranslationDraft } = {};
  Object.keys(form.translations).forEach((locale) => {
    const t = form.translations[locale];
    if (locale === form.defaultLocale || hasText(t)) {
      translations[locale] = { title: t.title.trim(), body: t.body.trim(), buttonLabel: t.buttonLabel.trim() };
    }
  });
  const priority = parseInt(form.priority, 10) || 0;
  if (liveOnly) {
    return { translations, endsAt: fromLocalInput(form.endsAt), priority };
  }
  return {
    translations,
    defaultLocale: form.defaultLocale,
    emoji: form.emoji.trim(),
    imageUrl: form.imageUrl || null,
    buttonUrl: form.buttonUrl.trim() || null,
    platforms: form.platforms.indexOf("all") >= 0 ? ["all"] : form.platforms,
    displayStyle: form.displayStyle,
    languages: form.languages,
    startsAt: fromLocalInput(form.startsAt),
    endsAt: fromLocalInput(form.endsAt),
    showInApp: form.showInApp,
    notify: form.notify && reachesApp(form),
    priority,
  };
};

export interface ValidateOptions {
  /** Scheduling requires a start time in the future. */
  schedule?: boolean;
  /** Publishing right now: the effective start is now, so an end at or before now is an error. */
  publish?: boolean;
  now?: Date;
}

export const validateForm = (form: AnnouncementForm, opts: ValidateOptions = {}): FormErrors => {
  const errors: FormErrors = {};
  const L = ANNOUNCEMENT_LIMITS;
  const def = form.translations[form.defaultLocale];
  const key = (locale: string, field: string) => `translations.${locale}.${field}`;

  if (!def || !def.title.trim()) errors[key(form.defaultLocale, "title")] = "Title is required in the default language.";
  if (!def || !def.body.trim()) errors[key(form.defaultLocale, "body")] = "Body is required in the default language.";

  Object.keys(form.translations).forEach((locale) => {
    const t = form.translations[locale];
    if (locale !== form.defaultLocale && hasText(t)) {
      if (!t.title.trim()) errors[key(locale, "title")] = "Title is required once this language has text.";
      if (!t.body.trim()) errors[key(locale, "body")] = "Body is required once this language has text.";
    }
    if (t.title.trim().length > L.title) errors[key(locale, "title")] = `Title is limited to ${L.title} characters.`;
    if (t.body.trim().length > L.body) errors[key(locale, "body")] = `Body is limited to ${L.body} characters.`;
    if (t.buttonLabel.trim().length > L.buttonLabel) {
      errors[key(locale, "buttonLabel")] = `Button label is limited to ${L.buttonLabel} characters.`;
    }
  });

  const url = form.buttonUrl.trim();
  const anyLabel = Object.keys(form.translations).some((l) => form.translations[l].buttonLabel.trim() !== "");
  if (url && (url.length > L.buttonUrl || !BUTTON_URL_RE.test(url))) {
    errors.buttonUrl = "Use https://host… or bananatalk://… (in-app links are bananatalk://path).";
  } else if (anyLabel && !url) {
    errors.buttonUrl = "Add a link for the button, or clear the button label.";
  }

  if (form.emoji.trim().length > L.emoji) errors.emoji = `Emoji is limited to ${L.emoji} characters.`;
  if (!form.platforms.length) errors.platforms = "Pick at least one platform.";
  if (!form.showInApp && !form.notify) errors.channels = "Turn on Show in app, Send notification, or both.";
  if (!/^-?\d+$/.test(form.priority.trim())) errors.priority = "Priority is a whole number.";

  const start = fromLocalInput(form.startsAt);
  const end = fromLocalInput(form.endsAt);
  if (form.startsAt && !start) errors.startsAt = "Not a valid date.";
  if (form.endsAt && !end) errors.endsAt = "Not a valid date.";
  // The backend model rejects end <= start for every non-ended row, and publishing saves
  // the form first, so this holds for publish too (no relaxation: the server would 400).
  if (start && end && new Date(end) <= new Date(start)) {
    errors.endsAt = opts.publish
      ? "End must be after start. Fix the start or end time before publishing."
      : "End must be after start.";
  }
  if (opts.publish && end && new Date(end) <= (opts.now || new Date())) {
    errors.endsAt = "The end time is already past, so this would end the moment it publishes.";
  }
  if (opts.schedule) {
    const now = opts.now || new Date();
    if (!start) errors.startsAt = "Pick a start time to schedule.";
    else if (new Date(start) <= now) errors.startsAt = "A scheduled start must be in the future.";
  }
  return errors;
};

export const targetingSummary = (a: { platforms?: string[]; languages?: string[] }): string => {
  const platforms = a.platforms || [];
  const p = !platforms.length || platforms.indexOf("all") >= 0
    ? "All platforms"
    : platforms.map((x) => (x === "ios" ? "iOS" : x === "web" ? "Web" : "Android")).join(" + ");
  const languages = a.languages || [];
  return `${p} · ${languages.length ? languages.join(", ") : "all languages"}`;
};

/** Title in the default language, for tables and audit-style labels. */
export const defaultTitle = (a: { translations?: { [l: string]: { title: string } }; defaultLocale?: string }): string => {
  const t = a.translations && a.defaultLocale ? a.translations[a.defaultLocale] : null;
  return (t && t.title) || "";
};

/** services/announcementDelivery.js MAX_ATTEMPTS: the minute job stops retrying after this many claims. */
export const MAX_DELIVERY_ATTEMPTS = 3;

export interface DeliveryInfo {
  state: string;
  attempts: number;
  error: string;
  /** `failed` with no retries left: nothing will send the rest without a new announcement. */
  exhausted: boolean;
  /** `failed` that the minute job will still retry (only while live and under the cap). */
  retrying: boolean;
  /** `done`, but the end time passed before every batch went out (delivery.stoppedReason 'end_time'). */
  stoppedAtEnd: boolean;
  /** `done`, but an admin pressed End mid-send (stoppedReason 'admin_end'). */
  endedByAdmin: boolean;
}

/** What the delivery block of a row says, independent of how it is drawn. */
export const deliveryInfo = (a: {
  status?: string;
  delivery?: { state?: string; attempts?: number; error?: string | null; stoppedReason?: string | null } | null;
}): DeliveryInfo => {
  const d = a.delivery || {};
  const state = d.state || "none";
  const attempts = typeof d.attempts === "number" && isFinite(d.attempts) ? d.attempts : 0;
  const failed = state === "failed";
  const exhausted = failed && attempts >= MAX_DELIVERY_ATTEMPTS;
  return {
    state,
    attempts,
    error: d.error ? String(d.error) : "",
    exhausted,
    retrying: failed && !exhausted && a.status === "live",
    stoppedAtEnd: state === "done" && d.stoppedReason === "end_time",
    endedByAdmin: state === "done" && d.stoppedReason === "admin_end",
  };
};

/**
 * Client-side search over what the list already loaded (the backend has no
 * search parameter and returns at most 200 rows): any locale's title or body,
 * case-insensitive. Blank matches everything.
 */
export const matchesSearch = (
  a: { translations?: { [l: string]: { title?: string; body?: string } } },
  query: string
): boolean => {
  const q = query.trim().toLowerCase();
  if (!q) return true;
  const translations = a.translations || {};
  return Object.keys(translations).some((locale) => {
    const tr = translations[locale] || {};
    return (
      String(tr.title || "").toLowerCase().indexOf(q) >= 0 ||
      String(tr.body || "").toLowerCase().indexOf(q) >= 0
    );
  });
};
