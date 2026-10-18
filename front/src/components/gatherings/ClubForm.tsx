import React, { useEffect, useMemo, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import Loader from "../Loader";
import { useCreateClubMutation, useUpdateClubMutation, useGetClubQuery } from "../../store/slices/gatheringsSlice";
import { useGetLanguagesQuery } from "../../store/slices/communitySlice";
import { languageOptions } from "../community/lib/languageOptions";
import { gatheringErrorText } from "./lib/gatheringFormat";

const NAME_MAX = 80;
const DESCRIPTION_MAX = 2000;
const INTEREST_MAX = 60;

interface ClubValues {
  name: string;
  language: string;
  description: string;
  interest: string;
  city: string;
  placeName: string;
  placeAddress: string;
}

const ERROR_TEXT: { [k: string]: string } = {
  nameRequired: "Give your club a name.",
  nameTooLong: "Keep the name under 80 characters.",
  languageRequired: "Pick the club's language.",
  descriptionTooLong: "Keep the description under 2000 characters.",
  interestTooLong: "Keep the interest under 60 characters.",
};

export function validateClub(v: ClubValues, mode: "create" | "edit"): { [k: string]: string } {
  const e: { [k: string]: string } = {};
  const name = v.name.trim();
  if (!name) e.name = "nameRequired";
  else if (name.length > NAME_MAX) e.name = "nameTooLong";
  if (mode === "create" && !v.language) e.language = "languageRequired";
  if (v.description.length > DESCRIPTION_MAX) e.description = "descriptionTooLong";
  if (v.interest.trim().length > INTEREST_MAX) e.interest = "interestTooLong";
  return e;
}

const field = "mt-1 w-full rounded-lg border border-gray-300 px-3 py-2 dark:border-gray-600 dark:bg-gray-900";
const orNull = (s: string) => (s.trim() ? s.trim() : null);

const ClubForm: React.FC<{ mode: "create" | "edit" }> = ({ mode }) => {
  const { t, i18n } = useTranslation();
  const navigate = useNavigate();
  const { id = "" } = useParams();
  const target = useSelector(
    (s: any) => (s.auth && s.auth.userInfo && s.auth.userInfo.user && s.auth.userInfo.user.language_to_learn) || ""
  );
  const existing = useGetClubQuery(id, { skip: mode !== "edit" || !id });
  const [createClub, createState] = useCreateClubMutation();
  const [updateClub, updateState] = useUpdateClubMutation();
  const busy = !!(createState && createState.isLoading) || !!(updateState && updateState.isLoading);
  const [v, setV] = useState<ClubValues>({
    name: "",
    language: String(target).replace(/\s*\([^)]*\)\s*$/, ""),
    description: "",
    interest: "",
    city: "",
    placeName: "",
    placeAddress: "",
  });
  const [loadedId, setLoadedId] = useState("");
  const [errors, setErrors] = useState<{ [k: string]: string }>({});
  const [serverError, setServerError] = useState("");
  const c = existing.data;

  useEffect(() => {
    if (mode === "edit" && c && c._id !== loadedId) {
      setV({
        name: c.name || "",
        language: c.languageLabel || c.language || "",
        description: c.description || "",
        interest: c.interest || "",
        city: c.city || "",
        placeName: (c.place && c.place.name) || "",
        placeAddress: (c.place && c.place.address) || "",
      });
      setLoadedId(c._id);
    }
  }, [mode, c, loadedId]);

  const { data: catalog } = useGetLanguagesQuery();
  const langs = useMemo(() => {
    const opts: { value: string; label: string }[] = languageOptions((catalog && catalog.data) || [], i18n.language);
    if (v.language && !opts.some((o) => o.value === v.language)) return [{ value: v.language, label: v.language }].concat(opts);
    return opts;
  }, [catalog, i18n.language, v.language]);

  if (mode === "edit") {
    if (existing.isLoading) return <Loader />;
    if (existing.isError || !c || !c.viewerCanManage) {
      return (
        <p data-testid="cf-not-allowed" className="mx-auto max-w-xl px-4 py-16 text-center font-bold">
          {t("clubs.form.notAllowed") || "Only the club's owner or an organizer can edit it."}
        </p>
      );
    }
  }

  const set = (patch: Partial<ClubValues>) => setV((x) => Object.assign({}, x, patch));
  const errorText = (key: string) => t(`clubs.form.errors.${key}`) || ERROR_TEXT[key] || key;

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setServerError("");
    const found = validateClub(v, mode);
    setErrors(found);
    if (Object.keys(found).length) return;
    try {
      if (mode === "create") {
        const created: any = await createClub({
          name: v.name.trim(),
          description: v.description.trim(),
          language: v.language,
          interest: v.interest.trim(),
        }).unwrap();
        navigate(`/clubs/${created && created._id ? created._id : ""}`, { replace: true });
      } else if (c) {
        const body: { [k: string]: any } = {};
        if (v.name.trim() !== (c.name || "")) body.name = v.name.trim();
        if (v.description.trim() !== (c.description || "")) body.description = v.description.trim();
        if (v.interest.trim() !== (c.interest || "")) body.interest = v.interest.trim();
        if (orNull(v.city) !== (c.city || null)) body.city = orNull(v.city);
        const beforePlace = { name: (c.place && c.place.name) || null, address: (c.place && c.place.address) || null };
        const afterPlace = { name: orNull(v.placeName), address: orNull(v.placeAddress) };
        if (beforePlace.name !== afterPlace.name || beforePlace.address !== afterPlace.address) {
          body.place = afterPlace;
        }
        if (Object.keys(body).length) await updateClub({ id: c._id, body }).unwrap();
        navigate(`/clubs/${c._id}`, { replace: true });
      }
    } catch (err) {
      setServerError(gatheringErrorText(err, t));
    }
  };

  const err = (name: string) =>
    errors[name] ? (
      <p data-testid={`cf-error-${name}`} className="mt-1 text-sm text-red-700">
        {errorText(errors[name])}
      </p>
    ) : null;

  return (
    <form data-testid="club-form" onSubmit={submit} noValidate className="mx-auto grid max-w-xl gap-4 px-4 py-6 text-start">
      <h1 className="text-2xl font-extrabold">
        {mode === "create" ? t("clubs.form.createTitle") || "Start a club" : t("clubs.form.editTitle") || "Edit club"}
      </h1>
      <label className="block text-sm font-bold">
        {t("clubs.form.name") || "Name"}
        <input data-testid="cf-name" className={field} value={v.name} onChange={(e) => set({ name: e.target.value })} />
        {err("name")}
      </label>
      <label className="block text-sm font-bold">
        {t("clubs.form.language") || "Language"}
        <select data-testid="cf-language" className={field} value={v.language} disabled={mode === "edit"}
          onChange={(e) => set({ language: e.target.value })}>
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
        {t("clubs.form.interest") || "What brings you together (e.g. books, K-drama)"}
        <input data-testid="cf-interest" className={field} value={v.interest} onChange={(e) => set({ interest: e.target.value })} />
        {err("interest")}
      </label>
      <label className="block text-sm font-bold">
        {t("clubs.form.description") || "About the club (optional)"}
        <textarea data-testid="cf-description" className={field} rows={4} value={v.description} onChange={(e) => set({ description: e.target.value })} />
        {err("description")}
      </label>
      {mode === "edit" && (
        <>
          <label className="block text-sm font-bold">
            {t("clubs.form.city") || "City (optional)"}
            <input data-testid="cf-city" className={field} value={v.city} onChange={(e) => set({ city: e.target.value })} />
          </label>
          <div className="grid grid-cols-2 gap-3">
            <label className="block text-sm font-bold">
              {t("clubs.form.placeName") || "Where you meet (optional)"}
              <input data-testid="cf-place-name" className={field} value={v.placeName} onChange={(e) => set({ placeName: e.target.value })} />
            </label>
            <label className="block text-sm font-bold">
              {t("clubs.form.placeAddress") || "Address (optional)"}
              <input data-testid="cf-place-address" className={field} value={v.placeAddress} onChange={(e) => set({ placeAddress: e.target.value })} />
            </label>
          </div>
        </>
      )}
      {serverError && (
        <p data-testid="cf-server-error" role="alert" className="rounded-lg bg-red-50 p-3 text-sm text-red-800">
          {serverError}
        </p>
      )}
      <div className="flex justify-end gap-2">
        <Link to={mode === "edit" && c ? `/clubs/${c._id}` : "/gatherings?tab=clubs"} className="rounded-full px-4 py-2 font-bold">
          {t("gatherings.form.cancel") || "Cancel"}
        </Link>
        <button type="submit" data-testid="cf-submit" disabled={busy} className="rounded-full bg-brand px-5 py-2 font-extrabold text-white disabled:opacity-50">
          {mode === "create" ? t("clubs.form.create") || "Create club" : t("gatherings.form.save") || "Save"}
        </button>
      </div>
    </form>
  );
};

export default ClubForm;
