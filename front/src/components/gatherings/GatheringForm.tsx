import React, { useEffect, useMemo, useState } from "react";
import { Link, useNavigate, useParams, useSearchParams } from "react-router-dom";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import Loader from "../Loader";
import {
  useCreateGatheringMutation,
  useUpdateGatheringMutation,
  useGetGatheringQuery,
  gatheringEditBody,
  GATHERING_TOPICS,
  GATHERING_LEVELS,
} from "../../store/slices/gatheringsSlice";
import { useGetLanguagesQuery } from "../../store/slices/communitySlice";
import { languageOptions } from "../community/lib/languageOptions";
import { toLocalInputValue, fromLocalInputValue, topicLabel, gatheringErrorText } from "./lib/gatheringFormat";
import {
  GatheringFormValues,
  defaultGatheringValues,
  validateGatheringForm,
  MIN_CAPACITY,
  MAX_CAPACITY,
  MIN_QUORUM,
  TITLE_MAX,
  DESCRIPTION_MAX,
  MAX_DAYS_AHEAD,
} from "./lib/gatheringFormRules";

const ERROR_TEXT: { [k: string]: string } = {
  titleRequired: "Give your gathering a title.",
  titleTooLong: "Keep the title under 120 characters.",
  descriptionTooLong: "Keep the description under 2000 characters.",
  languageRequired: "Pick the language you'll practise.",
  startRequired: "Pick a day and time.",
  startInPast: "Pick a start time in the future.",
  startTooFar: "Pick a time within the next 90 days.",
  capacityRange: "Seats must be between 2 and 20.",
  quorumRange: "The gathering confirms at 2 or more, and not more than the seats.",
};

const field = "mt-1 w-full rounded-lg border border-gray-300 px-3 py-2 dark:border-gray-600 dark:bg-gray-900";

const GatheringForm: React.FC<{ mode: "create" | "edit" }> = ({ mode }) => {
  const { t, i18n } = useTranslation();
  const navigate = useNavigate();
  const { id = "" } = useParams();
  const [params] = useSearchParams();
  const clubId = params.get("club") || "";
  const targetLanguage = useSelector(
    (s: any) => (s.auth && s.auth.userInfo && s.auth.userInfo.user && s.auth.userInfo.user.language_to_learn) || ""
  );
  const existing = useGetGatheringQuery(id, { skip: mode !== "edit" || !id });
  const [createGathering, createState] = useCreateGatheringMutation();
  const [updateGathering, updateState] = useUpdateGatheringMutation();
  const busy = !!(createState && createState.isLoading) || !!(updateState && updateState.isLoading);

  const [values, setValues] = useState<GatheringFormValues>(() =>
    defaultGatheringValues(new Date(), String(targetLanguage).replace(/\s*\([^)]*\)\s*$/, ""))
  );
  const [loadedId, setLoadedId] = useState("");
  const [errors, setErrors] = useState<{ [k: string]: string }>({});
  const [serverError, setServerError] = useState("");

  const g = existing.data;
  useEffect(() => {
    if (mode === "edit" && g && g._id !== loadedId) {
      setValues({
        title: g.title || "",
        description: g.description || "",
        language: g.languageLabel || g.language || "",
        level: g.level || "",
        topic: g.topic || "",
        startsAt: g.startsAt,
        durationMinutes: g.durationMinutes || 60,
        capacity: g.capacity,
        quorum: g.quorum,
        joinMode: g.joinMode === "approval" ? "approval" : "open",
      });
      setLoadedId(g._id);
    }
  }, [mode, g, loadedId]);

  const { data: catalog } = useGetLanguagesQuery();
  const langs = useMemo(() => {
    const opts: { value: string; label: string }[] = languageOptions((catalog && catalog.data) || [], i18n.language);
    // An existing gathering's label that the catalog does not list (an old
    // variant name) must still be selectable, or saving would silently change it.
    if (values.language && !opts.some((o) => o.value === values.language)) {
      return [{ value: values.language, label: values.language }].concat(opts);
    }
    return opts;
  }, [catalog, i18n.language, values.language]);

  if (mode === "edit") {
    if (existing.isLoading) return <Loader />;
    if (existing.isError || !g) {
      return (
        <p data-testid="gf-not-host" className="mx-auto max-w-xl px-4 py-16 text-center font-bold">
          {t("gatherings.errors.gatheringGone") || "This gathering isn't available."}
        </p>
      );
    }
    if (!g.viewerIsHost) {
      return (
        <p data-testid="gf-not-host" className="mx-auto max-w-xl px-4 py-16 text-center font-bold">
          {t("gatherings.form.notHost") || "Only the host can edit this gathering."}
        </p>
      );
    }
  }

  const set = (patch: Partial<GatheringFormValues>) => setValues((v) => Object.assign({}, v, patch));
  const errorText = (key: string) => {
    if (key === "capacityBelowGoing") {
      const count = g ? g.going : 0;
      return t("gatherings.errors.capacityBelowGoing", { count }) || `Capacity can't be lower than the ${count} people already going.`;
    }
    return t(`gatherings.form.errors.${key}`) || ERROR_TEXT[key] || key;
  };

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setServerError("");
    const found = validateGatheringForm(values, {
      mode,
      now: new Date(),
      going: g ? g.going : undefined,
      originalStartsAt: g ? g.startsAt : undefined,
    });
    setErrors(found);
    if (Object.keys(found).length) return;

    try {
      if (mode === "create") {
        const body: any = {
          title: values.title.trim(),
          language: values.language,
          startsAt: values.startsAt,
          description: values.description.trim(),
          durationMinutes: values.durationMinutes,
          capacity: Number(values.capacity),
          quorum: Math.min(Number(values.quorum), Number(values.capacity)),
          joinMode: values.joinMode,
        };
        if (values.level) body.level = values.level;
        if (values.topic) body.topic = values.topic;
        if (clubId) body.club = clubId;
        const created: any = await createGathering(body).unwrap();
        navigate(`/gatherings/${created && created._id ? created._id : ""}`, { replace: true });
      } else if (g) {
        const body = gatheringEditBody(
          {
            title: g.title,
            description: g.description || "",
            languageLabel: g.languageLabel || g.language,
            level: g.level || null,
            topic: g.topic || null,
            startsAt: g.startsAt,
            durationMinutes: g.durationMinutes,
            capacity: g.capacity,
            joinMode: g.joinMode,
          },
          {
            title: values.title.trim(),
            description: values.description.trim(),
            languageLabel: values.language,
            level: values.level || null,
            topic: values.topic || null,
            startsAt: values.startsAt,
            durationMinutes: values.durationMinutes,
            capacity: Number(values.capacity),
            joinMode: values.joinMode,
          }
        );
        if (Object.keys(body).length) await updateGathering({ id: g._id, body }).unwrap();
        navigate(`/gatherings/${g._id}`, { replace: true });
      }
    } catch (err) {
      setServerError(gatheringErrorText(err, t));
    }
  };

  const now = new Date();
  const minLocal = toLocalInputValue(now.toISOString());
  const maxLocal = toLocalInputValue(new Date(now.getTime() + MAX_DAYS_AHEAD * 24 * 3600 * 1000).toISOString());
  const err = (name: string) =>
    errors[name] ? (
      <p data-testid={`gf-error-${name}`} className="mt-1 text-sm text-red-700">
        {errorText(errors[name])}
      </p>
    ) : null;

  return (
    <form data-testid="gathering-form" onSubmit={submit} noValidate className="mx-auto grid max-w-xl gap-4 px-4 py-6 text-start">
      <h1 className="text-2xl font-extrabold">
        {mode === "create" ? t("gatherings.form.createTitle") || "Host a gathering" : t("gatherings.form.editTitle") || "Edit gathering"}
      </h1>

      <label className="block text-sm font-bold">
        {t("gatherings.form.title") || "Title"}
        <input data-testid="gf-title" className={field} maxLength={TITLE_MAX} value={values.title} onChange={(e) => set({ title: e.target.value })} />
        {err("title")}
      </label>

      <label className="block text-sm font-bold">
        {t("gatherings.form.language") || "Language"}
        <select data-testid="gf-language" className={field} value={values.language} onChange={(e) => set({ language: e.target.value })}>
          <option value="">{t("gatherings.form.pickLanguage") || "Pick a language"}</option>
          {langs.map((o) => (
            <option key={o.value} value={o.value}>
              {o.label}
            </option>
          ))}
        </select>
        {err("language")}
      </label>

      <label className="block text-sm font-bold">
        {t("gatherings.form.startsAt") || "Starts"}
        <input
          data-testid="gf-starts-at"
          type="datetime-local"
          className={field}
          min={minLocal}
          max={maxLocal}
          value={toLocalInputValue(values.startsAt)}
          onChange={(e) => set({ startsAt: fromLocalInputValue(e.target.value) })}
        />
        <span className="mt-1 block text-xs font-normal text-gray-500">
          {t("gatherings.form.duration", { count: values.durationMinutes }) || `Lasts ${values.durationMinutes} minutes · in your time zone`}
        </span>
        {err("startsAt")}
      </label>

      <div className="grid grid-cols-2 gap-3">
        <label className="block text-sm font-bold">
          {t("gatherings.form.capacity") || "Seats"}
          <input
            data-testid="gf-capacity"
            type="number"
            min={MIN_CAPACITY}
            max={MAX_CAPACITY}
            className={field}
            value={values.capacity}
            onChange={(e) => {
              const capacity = Number(e.target.value);
              set(mode === "create" && values.quorum > capacity && capacity >= MIN_QUORUM ? { capacity, quorum: capacity } : { capacity });
            }}
          />
          {err("capacity")}
        </label>
        <label className="block text-sm font-bold">
          {t("gatherings.form.quorum") || "Confirms at"}
          <input
            data-testid="gf-quorum"
            type="number"
            min={MIN_QUORUM}
            max={values.capacity}
            className={field}
            disabled={mode === "edit"}
            value={values.quorum}
            onChange={(e) => set({ quorum: Number(e.target.value) })}
          />
          {err("quorum")}
        </label>
      </div>

      <fieldset className="text-sm">
        <legend className="font-bold">{t("gatherings.form.joinMode") || "Who can join"}</legend>
        <label className="me-4 inline-flex items-center gap-1">
          <input type="radio" name="joinMode" data-testid="gf-join-open" checked={values.joinMode === "open"} onChange={() => set({ joinMode: "open" })} />
          {t("gatherings.form.joinOpen") || "Anyone"}
        </label>
        <label className="inline-flex items-center gap-1">
          <input type="radio" name="joinMode" data-testid="gf-join-approval" checked={values.joinMode === "approval"} onChange={() => set({ joinMode: "approval" })} />
          {t("gatherings.form.joinApproval") || "I approve each person"}
        </label>
      </fieldset>

      <div className="grid grid-cols-2 gap-3">
        <label className="block text-sm font-bold">
          {t("gatherings.form.topic") || "Topic"}
          <select data-testid="gf-topic" className={field} value={values.topic} onChange={(e) => set({ topic: e.target.value })}>
            <option value="">{t("gatherings.form.noTopic") || "No topic"}</option>
            {GATHERING_TOPICS.map((k: string) => (
              <option key={k} value={k}>
                {topicLabel(k, t)}
              </option>
            ))}
          </select>
        </label>
        <label className="block text-sm font-bold">
          {t("gatherings.form.level") || "Level"}
          <select data-testid="gf-level" className={field} value={values.level} onChange={(e) => set({ level: e.target.value })}>
            <option value="">{t("gatherings.form.anyLevel") || "Any level"}</option>
            {GATHERING_LEVELS.map((l: string) => (
              <option key={l} value={l}>
                {l}
              </option>
            ))}
          </select>
        </label>
      </div>

      <label className="block text-sm font-bold">
        {t("gatherings.form.description") || "What will you do? (optional)"}
        <textarea data-testid="gf-description" className={field} rows={4} maxLength={DESCRIPTION_MAX} value={values.description} onChange={(e) => set({ description: e.target.value })} />
        {err("description")}
      </label>

      {serverError && (
        <p data-testid="gf-server-error" role="alert" className="rounded-lg bg-red-50 p-3 text-sm text-red-800">
          {serverError}
        </p>
      )}

      <div className="flex justify-end gap-2">
        <Link to={mode === "edit" && g ? `/gatherings/${g._id}` : "/gatherings"} className="rounded-full px-4 py-2 font-bold">
          {t("gatherings.form.cancel") || "Cancel"}
        </Link>
        <button type="submit" data-testid="gf-submit" disabled={busy} className="rounded-full bg-brand px-5 py-2 font-extrabold text-white disabled:opacity-50">
          {mode === "create" ? t("gatherings.form.create") || "Post gathering" : t("gatherings.form.save") || "Save"}
        </button>
      </div>
    </form>
  );
};

export default GatheringForm;
