import React, { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Link, useBlocker, useNavigate } from "react-router-dom";
import { useSelector, useDispatch } from "react-redux";
import { useTranslation } from "react-i18next";
import {
  useGetUserProfileQuery,
  useUploadUserPhotoMutation,
  useUpdateUserInfoMutation,
  useUpdateUserByIdMutation,
  useDeleteUserPhotoMutation,
} from "../../store/slices/usersSlice";
import { setCredentials } from "../../store/slices/authSlice";
import { RootState } from "../../store";
import { Bounce, toast } from "react-toastify";
import DatePicker from "react-datepicker";
import "react-datepicker/dist/react-datepicker.css";
import ISO6391 from "iso-639-1";
import {
  ArrowLeft,
  BookOpen,
  Briefcase,
  Calendar,
  FileText,
  Globe,
  GraduationCap,
  Heart,
  Images,
  Loader2,
  Mail,
  Plus,
  Save,
  Trash2,
  User,
  Users,
} from "lucide-react";
import ConfirmDialog from "../../design/ConfirmDialog";
import SurfaceCard from "../../design/SurfaceCard";
import { UserProfileData } from "./ProfileTypes/types";
import { profileCompletion } from "./profileCompletion";
import {
  Intent,
  availableIntents,
  normalizeIntents,
  sameIntents,
  toggleIntent,
} from "./intents";

const MBTI_TYPES = [
  "INTJ", "INTP", "ENTJ", "ENTP",
  "INFJ", "INFP", "ENFJ", "ENFP",
  "ISTJ", "ISFJ", "ESTJ", "ESFJ",
  "ISTP", "ISFP", "ESTP", "ESFP",
];

const BLOOD_TYPES = ["A", "B", "AB", "O"];

/** CEFR, the same ladder `dotsForLevel` in the design system reads. */
const LEVELS = ["A1", "A2", "B1", "B2", "C1", "C2"];

const TOPIC_OPTIONS = [
  "music", "movies", "travel", "sports", "gaming",
  "food", "art", "photography", "reading", "fitness",
  "technology", "fashion", "cooking", "nature", "pets",
  "anime", "kpop", "kdrama", "languages", "culture",
];

const MAX_PHOTOS = 6;
const MAX_TOPICS = 10;
const BIO_LIMIT = 500;

const PAGE = "min-h-screen bg-canvas dark:bg-canvas-dark";
// `pb-6`, not the `pb-28` this used to carry: the save bar below is sticky
// rather than fixed, so it takes its own height out of the flow instead of
// needing the form to leave a hole underneath itself.
const COLUMN = "mx-auto w-full max-w-2xl px-3 pb-6 pt-4 sm:px-4";

const FIELD = [
  "w-full rounded-chip border border-line bg-surface px-3.5 py-2.5 text-sm",
  "text-ink-900 placeholder:text-ink-400",
  "focus:border-brand focus:outline-none focus:ring-2 focus:ring-brand/[0.35]",
  "dark:border-line-dark dark:bg-cardbg-dark dark:text-ink-50",
].join(" ");

const FIELD_LOCKED = [
  "w-full cursor-not-allowed rounded-chip border border-line bg-ink-100 px-3.5 py-2.5 text-sm",
  "text-ink-500 dark:border-line-dark dark:bg-ink-800 dark:text-ink-400",
].join(" ");

const LABEL =
  "flex items-center gap-1.5 pb-1 text-xs font-semibold uppercase tracking-wide text-ink-500 dark:text-ink-400";

const HINT = "pt-1 text-xs text-ink-400 dark:text-ink-500";

const CHOICE = "rounded-chip border px-3 py-2 text-sm font-semibold transition-colors";
const CHOICE_ON = "border-brand bg-brand/[0.12] text-brand-deep dark:text-brand-light";
const CHOICE_OFF =
  "border-line text-ink-600 hover:bg-ink-100 dark:border-line-dark dark:text-ink-300 dark:hover:bg-ink-800";
const CHOICE_LOCKED =
  "cursor-not-allowed border-line text-ink-300 dark:border-line-dark dark:text-ink-600";

const CLEAR_LINK =
  "pt-2 text-xs font-semibold text-ink-400 transition-colors hover:text-ink-600 dark:hover:text-ink-200";

interface SectionProps {
  title: string;
  icon: React.ComponentType<{ className?: string }>;
  children: React.ReactNode;
  testId: string;
}

const Section: React.FC<SectionProps> = ({ title, icon: Icon, children, testId }) => (
  <SurfaceCard padding="lg">
    <section data-testid={testId}>
      <h2 className="flex items-center gap-2 pb-4 text-eyebrow font-extrabold uppercase text-ink-500 dark:text-ink-400">
        <Icon className="h-4 w-4 text-brand" aria-hidden />
        {title}
      </h2>
      {children}
    </section>
  </SurfaceCard>
);

/**
 * Exactly the fields `PUT /auth/updatedetails` is sent, in order. The form
 * state carries more (`email` and `username` are read-only, shown but never
 * edited; everything in `BY_ID_FIELDS` goes to a different endpoint), so the
 * payload is an explicit pick rather than a spread of the whole form: an
 * earlier draft posted `{...formData}` and sent `image: ""`, `images: []` and
 * `createdAt: ""` along with it, which would blank the avatar on any server
 * that took the body at its word.
 */
const SAVED_FIELDS = [
  "_id",
  "name",
  "username",
  "gender",
  "email",
  "bio",
  "birth_year",
  "birth_month",
  "birth_day",
  "native_language",
  "language_to_learn",
  "imageUrls",
  "topics",
];

/**
 * The fields `PUT /auth/updatedetails` does NOT accept, which go to
 * `PUT /auth/users/:id` instead — the endpoint the app has always used for
 * them.
 *
 * `updatedetails` destructures a fixed list of names off the body and builds
 * its update from exactly those; anything else in the request is dropped
 * without a word. So this form collected an MBTI, a blood type, an occupation
 * and a school, sent them, and showed "Profile updated successfully" while the
 * stored document never moved. `languageLevel` had already been routed around
 * the same hole one field at a time; this is that fix, generalised.
 *
 * Only what actually changed is sent, so a save that touches none of them
 * makes no second request at all.
 */
const BY_ID_FIELDS = [
  "languageLevel",
  "mbti",
  "bloodType",
  "occupation",
  "school",
  "intents",
];

/**
 * How a field in `BY_ID_FIELDS` is compared against the loaded document.
 *
 * `intents` is an array, and `!==` on two arrays asks whether they are the
 * same object rather than whether they hold the same thing. Everything else
 * in the group is a string, where the two questions coincide.
 */
function movedFrom(before: any, after: any, field: string): boolean {
  if (field === "intents") return !sameIntents(before, after);
  return before !== after;
}

/** The blank form. Fields the editor does not own are absent, not empty. */
const EMPTY: UserProfileData = {
  _id: "",
  name: "",
  username: "",
  gender: "",
  email: "",
  bio: "",
  birth_year: "",
  birth_month: "",
  birth_day: "",
  native_language: "",
  language_to_learn: "",
  languageLevel: "",
  imageUrls: [],
  mbti: "",
  bloodType: "",
  topics: [],
  occupation: "",
  school: "",
  intents: [],
};

function formFrom(user: any): UserProfileData {
  const source = user || {};
  return {
    ...EMPTY,
    _id: source._id || "",
    name: source.name || "",
    username: source.username || "",
    gender: source.gender || "",
    email: source.email || "",
    bio: source.bio || "",
    birth_year: source.birth_year || "",
    birth_month: source.birth_month || "",
    birth_day: source.birth_day || "",
    native_language: source.native_language || "",
    language_to_learn: source.language_to_learn || "",
    languageLevel: source.languageLevel || "",
    imageUrls: Array.isArray(source.imageUrls) ? source.imageUrls : [],
    mbti: source.mbti || "",
    bloodType: source.bloodType || "",
    topics: Array.isArray(source.topics) ? source.topics : [],
    occupation: source.occupation || "",
    school: source.school || "",
    intents: normalizeIntents(source.intents),
  };
}

/** One icon per intent, in the same order the picker shows them. */
const INTENT_ICONS: Record<Intent, any> = {
  learn: GraduationCap,
  meet: Users,
  date: Heart,
};

const TOAST = { autoClose: 2500, theme: "dark" as "dark", transition: Bounce };

/**
 * The profile editor.
 *
 * Four sections — Photos, Basics, Languages, About — on the `src/design`
 * primitives, with a save bar pinned to the bottom of the viewport so the
 * button stays reachable without scrolling back up a long form.
 *
 * "Dirty" is a comparison against the loaded document, not a flag flipped by
 * the first keystroke: typing a character and deleting it again leaves the
 * form clean, so the unsaved-changes guard only ever interrupts someone who
 * really has unsaved work. That guard is `useBlocker` for in-app navigation
 * (the app mounts a data router in src/index.tsx, so the hook is available)
 * and `beforeunload` for closing the tab — the case react-router cannot see.
 */
const EditProfile: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const userId = useSelector((state: RootState) => state.auth.userInfo?.user?._id);
  const storedRefreshToken = useSelector((state: RootState) => state.auth.userInfo?.refreshToken);

  const { data, isLoading, refetch } = useGetUserProfileQuery({});
  const [uploadUserPhoto, { isLoading: isUploading }] = useUploadUserPhotoMutation();
  const [updateUserProfile, { isLoading: isSaving }] = useUpdateUserInfoMutation();
  // CEFR does not go with the rest: `/auth/updatedetails` does not whitelist
  // `languageLevel`, so it is persisted through `PUT /auth/users/:id` exactly
  // as Register.uploadPhotoAndPersistCefr does.
  const [updateUserById, { isLoading: isSavingLevel }] = useUpdateUserByIdMutation();
  const [deleteUserPhoto, { isLoading: isDeletingPhoto }] = useDeleteUserPhotoMutation();

  const [formData, setFormData] = useState<UserProfileData>(EMPTY);
  // What the server last told us. `dirty` is the diff against this.
  const [baseline, setBaseline] = useState<UserProfileData>(EMPTY);
  const [birthDate, setBirthDate] = useState<Date | null>(null);
  const [pendingPhoto, setPendingPhoto] = useState<number | null>(null);
  const [photoError, setPhotoError] = useState("");

  // A save navigates away on purpose; the guard must not stop it.
  const bypass = useRef(false);
  const mounted = useRef(true);
  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
    };
  }, []);

  const languageOptions = useMemo(
    () =>
      ISO6391.getAllCodes().map((code) => ({
        value: code,
        label: ISO6391.getName(code),
      })),
    []
  );

  const user = data && (data as any).data;

  useEffect(() => {
    if (!user) return;
    const next = formFrom(user);
    setFormData(next);
    setBaseline(next);

    const year = parseInt(String(next.birth_year), 10);
    const month = parseInt(String(next.birth_month), 10) - 1;
    const day = parseInt(String(next.birth_day), 10);
    if (isFinite(year) && isFinite(month) && isFinite(day)) {
      setBirthDate(new Date(year, month, day));
    }
  }, [user]);

  const dirty = useMemo(
    () => JSON.stringify(formData) !== JSON.stringify(baseline),
    [formData, baseline]
  );

  // Closing the tab. react-router's blocker cannot see this one.
  useEffect(() => {
    if (!dirty) return undefined;
    const onBeforeUnload = (event: BeforeUnloadEvent) => {
      event.preventDefault();
      event.returnValue = "";
      return "";
    };
    window.addEventListener("beforeunload", onBeforeUnload);
    return () => window.removeEventListener("beforeunload", onBeforeUnload);
  }, [dirty]);

  const shouldBlock = useCallback(
    (args: any) =>
      dirty &&
      !bypass.current &&
      Boolean(args && args.currentLocation && args.nextLocation) &&
      args.currentLocation.pathname !== args.nextLocation.pathname,
    [dirty]
  );
  const blocker: any = useBlocker(shouldBlock as any);
  const leaving = Boolean(blocker && blocker.state === "blocked");

  const patch = useCallback((fields: any) => {
    setFormData((prev) => ({ ...prev, ...fields }));
  }, []);

  const handleInputChange = useCallback(
    (
      event: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>
    ) => {
      const name = event.target.name;
      const value = event.target.value;
      setFormData((prev) => ({ ...prev, [name]: value }));
    },
    []
  );

  const handleBirthDateChange = useCallback(
    (date: Date | null) => {
      if (!date) return;
      setBirthDate(date);
      patch({
        birth_year: String(date.getFullYear()),
        birth_month: String(date.getMonth() + 1),
        birth_day: String(date.getDate()),
      });
    },
    [patch]
  );

  const handleTopicToggle = useCallback((topic: string) => {
    setFormData((prev) => {
      const current = prev.topics || [];
      const next =
        current.indexOf(topic) > -1
          ? current.filter((entry) => entry !== topic)
          : current.concat([topic]);
      return { ...prev, topics: next };
    });
  }, []);

  const handleIntentToggle = useCallback((intent: Intent) => {
    setFormData((prev) => ({ ...prev, intents: toggleIntent(prev.intents, intent) }));
  }, []);

  const handleSave = async (): Promise<void> => {
    // The backend validates gender lowercase, so the form and the payload
    // agree on the lowercased value -- otherwise the render after a save is
    // still "dirty" and the beforeunload listener stays bound.
    const next: any = { ...formData, gender: (formData.gender || "").toLowerCase() };
    const payload: any = {};
    SAVED_FIELDS.forEach((field) => {
      payload[field] = next[field];
    });

    try {
      const result = await updateUserProfile(payload).unwrap();
      // updatedetails answers with a token response whose refreshToken is null
      // (no device info on this request): keep the stored one, or the session
      // can no longer refresh itself once the access token expires.
      dispatch(setCredentials({ ...result, refreshToken: result.refreshToken || storedRefreshToken }));

      // Only what actually moved: the endpoint is a different one, and
      // unchanged fields are not worth a second round trip. One request for
      // the whole group rather than one per field.
      //
      // Its own try/catch on purpose. The fields above are already saved by
      // the time this runs, so a rejection here must not report the whole save
      // as failed -- the user would be told nothing persisted while most of it
      // did. This group gets its own, secondary message and the save still
      // finishes: success toast, clean baseline, redirect.
      const moved = BY_ID_FIELDS.filter(
        (field) => next[field] !== (baseline as any)[field]
      );
      if (userId && moved.length > 0) {
        const body: any = {};
        moved.forEach((field) => {
          body[field] = next[field];
        });
        try {
          await updateUserById({ id: userId, body }).unwrap();
        } catch (extrasError) {
          toast.error(
            t("profile.messages.extras_update_failure") ||
              "Your profile was saved, but some details did not update",
            TOAST
          );
          // They did not persist, so neither the form nor the new baseline may
          // claim they did: both go back to the stored values.
          // (`updateUserById` invalidates "User", so anything that DID save is
          // picked up by the profile's own query on the next render.)
          moved.forEach((field) => {
            next[field] = (baseline as any)[field];
          });
        }
      }

      toast.success(
        t("profile.messages.profile_update_success") || "Profile updated successfully",
        TOAST
      );
      if (!mounted.current) return;
      setFormData(next);
      setBaseline(next);
      // The guard reads a ref rather than the state just set: the navigation
      // below runs before React has re-rendered with the new baseline, so a
      // state-only check would still see a dirty form and block the save.
      bypass.current = true;
      navigate("/profile");
    } catch (error) {
      toast.error(
        t("profile.messages.profile_update_failure") || "Failed to update profile",
        TOAST
      );
    }
  };

  const handlePhotoUpload = async (
    event: React.ChangeEvent<HTMLInputElement>
  ): Promise<void> => {
    const files = event.target.files;
    if (!files || files.length === 0 || !userId) return;
    const upload = new FormData();
    Array.prototype.slice.call(files).forEach((file: File) => upload.append("photo", file));
    event.target.value = "";

    try {
      const result = await uploadUserPhoto({ userId, imageFiles: upload }).unwrap();
      dispatch(setCredentials({ ...result }));
      refetch();
      toast.success(t("profile.messages.image_update_success") || "Photo uploaded", TOAST);
    } catch (error) {
      toast.error(
        t("profile.messages.image_update_failure") || "Failed to upload photo",
        TOAST
      );
    }
  };

  const handleDeletePhoto = async (): Promise<void> => {
    if (pendingPhoto === null || !userId) return;
    setPhotoError("");
    try {
      const result = await deleteUserPhoto({ userId, index: pendingPhoto }).unwrap();
      dispatch(setCredentials({ ...result }));
      refetch();
      if (mounted.current) setPendingPhoto(null);
      toast.success(t("profile.messages.image_delete_success") || "Photo deleted", TOAST);
    } catch (error) {
      if (!mounted.current) return;
      setPhotoError(t("profile.messages.image_delete_failure") || "Failed to delete photo");
    }
  };

  if (isLoading) {
    return (
      <div className={`${PAGE} flex items-center justify-center`}>
        <Loader2 data-testid="edit-loading" className="h-8 w-8 animate-spin text-brand" aria-hidden />
      </div>
    );
  }

  const photos = formData.imageUrls || [];
  // Live from the form, so it moves as fields are filled. Address is not in
  // the form, so the loaded document supplies it underneath.
  const completion = profileCompletion({ ...(user || {}), ...formData });
  const topics = formData.topics || [];
  const intents = normalizeIntents(formData.intents);
  // `date` is only offered to a known adult: sanitizeIntents strips it from
  // the write for everyone else, and a choice the server is about to discard
  // is worse than no choice. Derived from the form rather than the loaded
  // document, so correcting a birthday in this session offers it at once.
  const intentOptions = availableIntents(formData);
  const bio = formData.bio || "";

  return (
    <div className={PAGE}>
      <header className="sticky top-0 z-20 border-b border-line bg-surface/95 backdrop-blur dark:border-line-dark dark:bg-cardbg-dark/95">
        <div className="mx-auto flex w-full max-w-2xl items-center gap-2 px-3 py-3 sm:px-4">
          <button
            type="button"
            data-testid="edit-back"
            onClick={() => navigate(-1)}
            aria-label={t("profile.edit.back") || "Back"}
            className="rounded-chip p-2 text-ink-600 transition-colors hover:bg-ink-100 dark:text-ink-300 dark:hover:bg-ink-800"
          >
            <ArrowLeft className="h-5 w-5" aria-hidden />
          </button>
          <h1 className="font-display text-lg text-ink-900 dark:text-ink-50">
            {t("profile.edit_profile") || "Edit profile"}
          </h1>
        </div>
        {completion.percent < 100 && (
          <div data-testid="edit-completion" className="px-1 pt-3">
            <div className="flex items-baseline justify-between pb-1.5 text-xs font-semibold">
              <span id="edit-completion-label" className="text-ink-700 dark:text-ink-200">
                {t("profile.edit.completion") || "Profile Completion"}
              </span>
              <span data-testid="edit-completion-percent" className="text-brand">
                {completion.percent}%
              </span>
            </div>
            <div
              role="progressbar"
              aria-labelledby="edit-completion-label"
              aria-valuemin={0}
              aria-valuemax={100}
              aria-valuenow={completion.percent}
              className="h-1.5 w-full overflow-hidden rounded-full bg-ink-100 dark:bg-white/10"
            >
              <div
                className="h-full rounded-full bg-brand transition-all duration-300"
                style={{ width: `${completion.percent}%` }}
              />
            </div>
          </div>
        )}
      </header>

      <div className={COLUMN}>
        <div className="space-y-4">
          <Section
            testId="edit-photos"
            title={t("profile.photos.title") || "Photos"}
            icon={Images}
          >
            <p className="pb-3 text-xs text-ink-400 dark:text-ink-500">
              {t("profile.edit.photos_hint") ||
                "Your first photo is the one people see everywhere."}
            </p>
            <ul className="grid grid-cols-3 gap-3">
              {photos.map((url, index) => (
                <li
                  key={`${index}-${url}`}
                  data-testid="edit-photo"
                  className="group relative aspect-square overflow-hidden rounded-chip bg-ink-100 dark:bg-ink-800"
                >
                  <img
                    src={url}
                    alt={
                      t("profile.edit.photo_alt", { index: index + 1 }) ||
                      `Photo ${index + 1}`
                    }
                    className="h-full w-full object-cover"
                  />
                  <button
                    type="button"
                    data-testid={`edit-photo-delete-${index}`}
                    onClick={() => {
                      setPhotoError("");
                      setPendingPhoto(index);
                    }}
                    aria-label={
                      t("profile.edit.delete_photo", { index: index + 1 }) ||
                      `Delete photo ${index + 1}`
                    }
                    className="absolute right-1.5 top-1.5 rounded-full bg-red-600 p-1.5 text-white opacity-0 transition-opacity focus:opacity-100 group-hover:opacity-100"
                  >
                    <Trash2 className="h-4 w-4" aria-hidden />
                  </button>
                </li>
              ))}

              {photos.length < MAX_PHOTOS && (
                <li>
                  <label
                    data-testid="edit-photo-add"
                    className="flex aspect-square cursor-pointer flex-col items-center justify-center gap-1 rounded-chip border-2 border-dashed border-line-strong text-ink-400 transition-colors hover:border-brand hover:text-brand dark:border-line-dark"
                  >
                    <input
                      type="file"
                      accept="image/*"
                      multiple
                      onChange={handlePhotoUpload}
                      className="hidden"
                      aria-label={t("profile.edit.add_photo") || "Add photo"}
                    />
                    {isUploading ? (
                      <Loader2 className="h-6 w-6 animate-spin" aria-hidden />
                    ) : (
                      <Plus className="h-6 w-6" aria-hidden />
                    )}
                    <span className="text-xs font-semibold">
                      {t("profile.edit.add_photo") || "Add photo"}
                    </span>
                  </label>
                </li>
              )}
            </ul>
          </Section>

          <Section
            testId="edit-basics"
            title={t("profile.sections.personal_info") || "Basics"}
            icon={User}
          >
            <div className="space-y-4">
              <div>
                <label className={LABEL} htmlFor="edit-name">
                  <User className="h-3.5 w-3.5" aria-hidden />
                  {t("profile.labels.name") || "Name"}
                </label>
                <input
                  id="edit-name"
                  data-testid="edit-name"
                  type="text"
                  name="name"
                  value={formData.name}
                  onChange={handleInputChange}
                  className={FIELD}
                />
              </div>

              {formData.username ? (
                <div>
                  <label className={LABEL} htmlFor="edit-username">
                    {t("profile.labels.username") || "Username"}
                  </label>
                  <input
                    id="edit-username"
                    data-testid="edit-username"
                    type="text"
                    value={`@${formData.username}`}
                    disabled
                    aria-describedby="edit-username-hint"
                    className={FIELD_LOCKED}
                  />
                  <p id="edit-username-hint" className={HINT}>
                    {t("profile.hints.username_readonly") || "Username cannot be changed"}
                  </p>
                </div>
              ) : null}

              <div>
                <label className={LABEL} htmlFor="edit-email">
                  <Mail className="h-3.5 w-3.5" aria-hidden />
                  {t("profile.labels.email") || "Email"}
                </label>
                <input
                  id="edit-email"
                  data-testid="edit-email"
                  type="email"
                  value={formData.email}
                  disabled
                  className={FIELD_LOCKED}
                />
              </div>

              <div>
                <span id="edit-gender-label" className={LABEL}>
                  {t("profile.labels.gender") || "Gender"}
                </span>
                <div role="group" aria-labelledby="edit-gender-label" className="flex gap-2">
                  {["male", "female"].map((option) => {
                    const on = (formData.gender || "").toLowerCase() === option;
                    return (
                      <button
                        key={option}
                        type="button"
                        data-testid={`edit-gender-${option}`}
                        onClick={() => patch({ gender: option })}
                        aria-pressed={on}
                        className={`flex-1 ${CHOICE} ${on ? CHOICE_ON : CHOICE_OFF}`}
                      >
                        {t(`profile.options.${option}`) || option}
                      </button>
                    );
                  })}
                </div>
              </div>

              <div>
                <label className={LABEL} htmlFor="edit-birthday">
                  <Calendar className="h-3.5 w-3.5" aria-hidden />
                  {t("profile.labels.birthday") || "Birthday"}
                </label>
                <DatePicker
                  id="edit-birthday"
                  selected={birthDate}
                  onChange={handleBirthDateChange}
                  dateFormat="MMMM d, yyyy"
                  placeholderText={t("profile.placeholders.select_date") || "Select date"}
                  className={FIELD}
                  showYearDropdown
                  showMonthDropdown
                  dropdownMode="select"
                  maxDate={new Date()}
                />
              </div>
            </div>
          </Section>

          <Section
            testId="edit-languages"
            title={t("profile.sections.languages") || "Languages"}
            icon={Globe}
          >
            <div className="space-y-4">
              <div>
                <label className={LABEL} htmlFor="edit-native">
                  <Globe className="h-3.5 w-3.5" aria-hidden />
                  {t("profile.labels.native_language") || "Native language"}
                </label>
                <select
                  id="edit-native"
                  data-testid="edit-native"
                  name="native_language"
                  value={formData.native_language}
                  onChange={handleInputChange}
                  className={FIELD}
                >
                  <option value="">
                    {t("profile.placeholders.select_native_language") ||
                      "Select native language"}
                  </option>
                  {languageOptions.map((lang) => (
                    <option key={lang.value} value={lang.label}>
                      {lang.label}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className={LABEL} htmlFor="edit-learning">
                  <BookOpen className="h-3.5 w-3.5" aria-hidden />
                  {t("profile.labels.learning") || "Learning"}
                </label>
                <select
                  id="edit-learning"
                  data-testid="edit-learning"
                  name="language_to_learn"
                  value={formData.language_to_learn}
                  onChange={handleInputChange}
                  className={FIELD}
                >
                  <option value="">
                    {t("profile.placeholders.select_learning_language") ||
                      "Select the language you are learning"}
                  </option>
                  {languageOptions.map((lang) => (
                    <option key={lang.value} value={lang.label}>
                      {lang.label}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <span id="edit-level-label" className={LABEL}>
                  {t("profile.edit.level") || "Level"}
                </span>
                <div
                  role="group"
                  aria-labelledby="edit-level-label"
                  aria-describedby="edit-level-hint"
                  className="grid grid-cols-6 gap-2"
                >
                  {LEVELS.map((level) => {
                    const on = formData.languageLevel === level;
                    return (
                      <button
                        key={level}
                        type="button"
                        data-testid={`edit-level-${level}`}
                        onClick={() => patch({ languageLevel: level })}
                        aria-pressed={on}
                        className={`${CHOICE} ${on ? CHOICE_ON : CHOICE_OFF}`}
                      >
                        {level}
                      </button>
                    );
                  })}
                </div>
                <p id="edit-level-hint" className={HINT}>
                  {t("profile.edit.level_hint") ||
                    "Your level in the language you are learning."}
                </p>
                {formData.languageLevel ? (
                  <button
                    type="button"
                    data-testid="edit-level-clear"
                    onClick={() => patch({ languageLevel: "" })}
                    className={CLEAR_LINK}
                  >
                    {t("profile.actions.clear") || "Clear selection"}
                  </button>
                ) : null}
              </div>
            </div>
          </Section>

          <Section
            testId="edit-about"
            title={t("profile.edit.about") || "About"}
            icon={FileText}
          >
            <div className="space-y-5">
              <div>
                <label className={LABEL} htmlFor="edit-bio">
                  <FileText className="h-3.5 w-3.5" aria-hidden />
                  {t("profile.sections.bio") || "Bio"}
                </label>
                <textarea
                  id="edit-bio"
                  data-testid="edit-bio"
                  name="bio"
                  value={bio}
                  onChange={handleInputChange}
                  maxLength={BIO_LIMIT}
                  placeholder={t("profile.placeholders.bio") || "Tell people about yourself"}
                  rows={4}
                  aria-describedby="edit-bio-count"
                  className={`${FIELD} resize-none`}
                />
                <p id="edit-bio-count" data-testid="edit-bio-count" className={`${HINT} text-right`}>
                  {bio.length}/{BIO_LIMIT}
                </p>
              </div>

              <div>
                <label className={LABEL} htmlFor="edit-occupation">
                  <Briefcase className="h-3.5 w-3.5" aria-hidden />
                  {t("profile.edit.occupation") || "Occupation"}
                </label>
                <input
                  id="edit-occupation"
                  data-testid="edit-occupation"
                  type="text"
                  name="occupation"
                  value={formData.occupation || ""}
                  onChange={handleInputChange}
                  placeholder={t("profile.edit.occupation_placeholder") || "What do you do?"}
                  className={FIELD}
                />
              </div>

              <div>
                <label className={LABEL} htmlFor="edit-school">
                  <GraduationCap className="h-3.5 w-3.5" aria-hidden />
                  {t("profile.edit.school") || "School"}
                </label>
                <input
                  id="edit-school"
                  data-testid="edit-school"
                  type="text"
                  name="school"
                  value={formData.school || ""}
                  onChange={handleInputChange}
                  placeholder={t("profile.edit.school_placeholder") || "Where do you study?"}
                  className={FIELD}
                />
              </div>

              <div>
                <span id="edit-intents-label" className={LABEL}>
                  {t("profile.edit.intent_title") || "What you're here for"}
                </span>
                <div
                  role="group"
                  aria-labelledby="edit-intents-label"
                  aria-describedby="edit-intent-note"
                  className="flex flex-wrap gap-2 pt-2"
                >
                  {intentOptions.map((intent) => {
                    const on = intents.indexOf(intent) > -1;
                    const Icon = INTENT_ICONS[intent];
                    return (
                      <button
                        key={intent}
                        type="button"
                        data-testid={`edit-intent-${intent}`}
                        onClick={() => handleIntentToggle(intent)}
                        aria-pressed={on}
                        className={`inline-flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-sm font-semibold transition-colors ${
                          on ? CHOICE_ON : CHOICE_OFF
                        }`}
                      >
                        <Icon className="h-3.5 w-3.5" aria-hidden />
                        {t(`profile.edit.intent_${intent}`) || intent}
                      </button>
                    );
                  })}
                </div>
                <p id="edit-intent-note" data-testid="edit-intent-note" className={HINT}>
                  {t("profile.edit.intent_privacy_note") ||
                    "Others see what you pick, except dating, which stays private."}
                </p>
              </div>

              <div>
                <span id="edit-topics-label" className={LABEL}>
                  {t("profile.sections.topics") || "Topics & interests"}
                </span>
                <p id="edit-topics-hint" className="pb-2 text-xs text-ink-400 dark:text-ink-500">
                  {t("profile.labels.topics_hint") ||
                    "Select topics you're interested in (max 10)"}
                </p>
                <div
                  role="group"
                  aria-labelledby="edit-topics-label"
                  aria-describedby="edit-topics-hint edit-topic-count"
                  className="flex flex-wrap gap-2"
                >
                  {TOPIC_OPTIONS.map((topic) => {
                    const on = topics.indexOf(topic) > -1;
                    const locked = !on && topics.length >= MAX_TOPICS;
                    return (
                      <button
                        key={topic}
                        type="button"
                        data-testid={`edit-topic-${topic}`}
                        onClick={() => {
                          if (!locked) handleTopicToggle(topic);
                        }}
                        disabled={locked}
                        aria-pressed={on}
                        className={`rounded-full border px-3 py-1.5 text-sm font-semibold transition-colors ${
                          on ? CHOICE_ON : locked ? CHOICE_LOCKED : CHOICE_OFF
                        }`}
                      >
                        {t(`profile.topics.${topic}`) || topic}
                      </button>
                    );
                  })}
                </div>
                <p id="edit-topic-count" data-testid="edit-topic-count" className={`${HINT} text-right`}>
                  {topics.length}/{MAX_TOPICS} {t("profile.labels.selected") || "selected"}
                </p>
              </div>

              <div>
                <span id="edit-mbti-label" className={LABEL}>
                  {t("profile.labels.mbti") || "MBTI"}
                </span>
                <div role="group" aria-labelledby="edit-mbti-label" className="grid grid-cols-4 gap-2">
                  {MBTI_TYPES.map((type) => {
                    const on = formData.mbti === type;
                    return (
                      <button
                        key={type}
                        type="button"
                        data-testid={`edit-mbti-${type}`}
                        onClick={() => patch({ mbti: type })}
                        aria-pressed={on}
                        className={`${CHOICE} ${on ? CHOICE_ON : CHOICE_OFF}`}
                      >
                        {type}
                      </button>
                    );
                  })}
                </div>
                {formData.mbti ? (
                  <button
                    type="button"
                    data-testid="edit-mbti-clear"
                    onClick={() => patch({ mbti: "" })}
                    className={CLEAR_LINK}
                  >
                    {t("profile.actions.clear") || "Clear selection"}
                  </button>
                ) : null}
              </div>

              <div>
                <span id="edit-blood-label" className={LABEL}>
                  {t("profile.labels.blood_type") || "Blood type"}
                </span>
                <div role="group" aria-labelledby="edit-blood-label" className="flex gap-2">
                  {BLOOD_TYPES.map((type) => {
                    const on = formData.bloodType === type;
                    return (
                      <button
                        key={type}
                        type="button"
                        data-testid={`edit-blood-${type}`}
                        onClick={() => patch({ bloodType: type })}
                        aria-pressed={on}
                        className={`flex-1 ${CHOICE} ${on ? CHOICE_ON : CHOICE_OFF}`}
                      >
                        {type}
                      </button>
                    );
                  })}
                </div>
                {formData.bloodType ? (
                  <button
                    type="button"
                    data-testid="edit-blood-clear"
                    onClick={() => patch({ bloodType: "" })}
                    className={CLEAR_LINK}
                  >
                    {t("profile.actions.clear") || "Clear selection"}
                  </button>
                ) : null}
              </div>
            </div>
          </Section>
        </div>
      </div>

      {/* The save bar. Pinned to the viewport so a long form never hides it --
          but `sticky`, not `fixed`: a fixed bar is out of the flow, so it sat
          on top of whatever the document ended with (the footer's legal row)
          with no way to scroll it clear. Sticky pins it exactly the same way
          while the form is on screen and still reserves its own height at the
          foot of the page. */}
      <div
        data-testid="edit-save-bar"
        className="sticky bottom-0 z-20 border-t border-line bg-surface/95 backdrop-blur dark:border-line-dark dark:bg-cardbg-dark/95"
      >
        <div className="mx-auto flex w-full max-w-2xl items-center gap-3 px-3 py-3 sm:px-4">
          <p
            data-testid="edit-dirty-note"
            className="min-w-0 flex-1 truncate text-xs text-ink-500 dark:text-ink-400"
          >
            {dirty ? t("profile.edit.unsaved") || "You have unsaved changes" : ""}
          </p>
          <Link
            to="/profile"
            data-testid="edit-cancel"
            className="rounded-chip border border-line px-4 py-2 text-sm font-semibold text-ink-700 transition-colors hover:bg-ink-100 dark:border-line-dark dark:text-ink-200 dark:hover:bg-ink-800"
          >
            {t("profile.actions.cancel") || "Cancel"}
          </Link>
          <button
            type="button"
            data-testid="edit-save"
            onClick={handleSave}
            disabled={!dirty || isSaving || isSavingLevel}
            className="inline-flex items-center gap-1.5 rounded-chip bg-brand-deep px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-brand-dark disabled:cursor-not-allowed disabled:opacity-50"
          >
            {isSaving || isSavingLevel ? (
              <Loader2 className="h-4 w-4 animate-spin" aria-hidden />
            ) : (
              <Save className="h-4 w-4" aria-hidden />
            )}
            {isSaving || isSavingLevel
              ? t("profile.edit.saving") || "Saving"
              : t("profile.actions.save") || "Save"}
          </button>
        </div>
      </div>

      <ConfirmDialog
        open={pendingPhoto !== null}
        danger
        title={t("profile.edit.delete_photo_title") || "Delete this photo?"}
        body={
          t("profile.edit.delete_photo_body") ||
          "It is removed from your profile for everyone."
        }
        confirmLabel={t("profile.edit.delete_photo_confirm") || "Delete photo"}
        cancelLabel={t("profile.actions.cancel") || "Cancel"}
        busy={isDeletingPhoto}
        error={photoError || undefined}
        onConfirm={handleDeletePhoto}
        onCancel={() => setPendingPhoto(null)}
      />

      <ConfirmDialog
        open={leaving}
        danger
        title={t("profile.edit.leave_title") || "Leave without saving?"}
        body={t("profile.edit.leave_body") || "Your changes to this profile will be lost."}
        confirmLabel={t("profile.edit.leave_confirm") || "Discard changes"}
        cancelLabel={t("profile.edit.stay") || "Keep editing"}
        onConfirm={() => {
          if (blocker && blocker.proceed) blocker.proceed();
        }}
        onCancel={() => {
          if (blocker && blocker.reset) blocker.reset();
        }}
      />
    </div>
  );
};

export default EditProfile;
