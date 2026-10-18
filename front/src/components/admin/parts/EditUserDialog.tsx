import React, { useMemo, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import ISO6391 from "iso-639-1";
import { useUpdateUserMutation } from "../../../store/slices/adminSlice";
import DialogShell from "../../../design/DialogShell";

export interface EditUserDialogProps {
  /** The user as `GET /admin/users/:id` returns them. */
  user: any;
  onClose: () => void;
}

const DEFAULT_VIP_DAYS = 30;

/**
 * Edit the handful of fields `PUT /admin/users/:id` will accept.
 *
 * The body carries only what actually changed — the backend whitelists the
 * same five fields plus `vip`, and sending an unchanged value back would
 * still write it, which puts a no-op in the audit log's `details`. `vip` rides
 * along only once the toggle or the day count has been touched: a VIP user
 * whose name is being corrected must not have their subscription re-granted
 * (and its end date pushed out) as a side effect.
 */
const EditUserDialog: React.FC<EditUserDialogProps> = ({ user, onClose }) => {
  const { t } = useTranslation();
  const [updateUser, updateState] = useUpdateUserMutation();
  const source: any = user || {};
  const id = String(source._id || source.id || "");
  const wasVip = source.userMode === "vip";

  const [name, setName] = useState(String(source.name || ""));
  const [bio, setBio] = useState(String(source.bio || ""));
  const [gender, setGender] = useState(String(source.gender || ""));
  const [native, setNative] = useState(String(source.native_language || ""));
  const [learning, setLearning] = useState(String(source.language_to_learn || ""));
  const [vip, setVip] = useState(wasVip);
  const [vipDays, setVipDays] = useState(String(DEFAULT_VIP_DAYS));
  const [vipTouched, setVipTouched] = useState(false);
  const [errors, setErrors] = useState<{ [key: string]: string }>({});
  const [formError, setFormError] = useState("");
  const firstFieldRef = useRef<HTMLInputElement | null>(null);

  const languages = useMemo(
    () => ISO6391.getAllCodes().map((code: string) => ISO6391.getName(code)),
    []
  );

  const onSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    const found: { [key: string]: string } = {};
    if (!name.trim()) found.name = t("admin.users.required") || "Required";
    if (
      native &&
      learning &&
      native.trim().toLowerCase() === learning.trim().toLowerCase()
    ) {
      found.learning =
        t("admin.users.sameLanguage") ||
        "Native language and language to learn cannot be the same";
    }
    setErrors(found);
    setFormError("");
    if (Object.keys(found).length > 0) return;

    const body: any = { id };
    if (name.trim() !== String(source.name || "")) body.name = name.trim();
    if (bio.trim() !== String(source.bio || "")) body.bio = bio.trim();
    if (gender !== String(source.gender || "")) body.gender = gender;
    if (native !== String(source.native_language || "")) body.native_language = native;
    if (learning !== String(source.language_to_learn || "")) {
      body.language_to_learn = learning;
    }
    if (vipTouched) {
      const days = Math.max(1, Math.floor(Number(vipDays) || DEFAULT_VIP_DAYS));
      body.vip = vip ? { grant: true, days } : { grant: false };
    }

    // Nothing but the id: there is no edit to send, and a PUT that changes
    // nothing would still write an audit row.
    if (Object.keys(body).length === 1) {
      onClose();
      return;
    }

    try {
      await updateUser(body).unwrap();
      onClose();
    } catch (err) {
      const error: any = err || {};
      setFormError(
        (error.data && (error.data.message || error.data.error)) ||
          error.message ||
          t("admin.users.actionFailed") ||
          "That didn't work. Nothing was changed."
      );
    }
  };

  const labelClass =
    "block text-xs font-medium uppercase tracking-wide text-ink-500 dark:text-ink-400";
  const fieldClass = [
    "mt-1 w-full rounded-card border border-line bg-surface px-3 py-2 text-sm",
    "text-ink-900 placeholder:text-ink-400",
    "dark:border-line-dark dark:bg-cardbg-dark dark:text-ink-50",
  ].join(" ");
  const buttonClass =
    "rounded-chip border border-line px-3 py-1.5 text-sm font-medium text-ink-700 hover:bg-ink-100 disabled:cursor-not-allowed disabled:opacity-50 dark:border-line-dark dark:text-ink-200 dark:hover:bg-ink-800";

  const fieldError = (key: string) =>
    errors[key] ? (
      <p
        data-testid={`edit-user-error-${key}`}
        className="pt-1 text-xs text-red-700 dark:text-red-300"
      >
        {errors[key]}
      </p>
    ) : null;

  const title = t("admin.users.editTitle") || "Edit user";

  return (
    <DialogShell
      labelledBy="edit-user-dialog-title"
      onClose={onClose}
      testId="edit-user-dialog"
      backdropTestId="edit-user-dialog-backdrop"
      panelClassName={[
        "relative w-full max-w-lg max-h-[90vh] overflow-y-auto rounded-card border border-line",
        "bg-surface p-5 shadow-lg dark:border-line-dark dark:bg-cardbg-dark",
      ].join(" ")}
      initialFocusRef={firstFieldRef}
    >
      <h2
        id="edit-user-dialog-title"
        className="font-display text-base text-ink-900 dark:text-ink-50"
      >
        {title}
      </h2>

      <form onSubmit={onSubmit} noValidate className="mt-4 space-y-4">
        <div>
          <label className={labelClass}>
            {t("admin.users.name") || "Name"}
            <input
              data-testid="edit-user-name"
              ref={firstFieldRef}
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className={fieldClass}
            />
          </label>
          {fieldError("name")}
        </div>

        <div>
          <label className={labelClass}>
            {t("admin.users.bio") || "Bio"}
            <textarea
              data-testid="edit-user-bio"
              rows={3}
              value={bio}
              onChange={(e) => setBio(e.target.value)}
              className={fieldClass}
            />
          </label>
        </div>

        <div className="grid gap-4 sm:grid-cols-2">
          <div>
            <label className={labelClass}>
              {t("admin.users.gender") || "Gender"}
              <select
                data-testid="edit-user-gender"
                value={gender}
                onChange={(e) => setGender(e.target.value)}
                className={fieldClass}
              >
                <option value="">{t("admin.users.select") || "Select"}</option>
                <option value="male">{t("admin.users.male") || "Male"}</option>
                <option value="female">{t("admin.users.female") || "Female"}</option>
                <option value="other">{t("admin.users.other") || "Other"}</option>
              </select>
            </label>
          </div>

          <div>
            <label className={labelClass}>
              {t("admin.users.nativeLanguage") || "Native language"}
              <select
                data-testid="edit-user-native"
                value={native}
                onChange={(e) => setNative(e.target.value)}
                className={fieldClass}
              >
                <option value="">{t("admin.users.select") || "Select"}</option>
                {languages.map((language: string) => (
                  <option key={language} value={language}>
                    {language}
                  </option>
                ))}
              </select>
            </label>
          </div>

          <div>
            <label className={labelClass}>
              {t("admin.users.learningLanguage") || "Language to learn"}
              <select
                data-testid="edit-user-learning"
                value={learning}
                onChange={(e) => setLearning(e.target.value)}
                className={fieldClass}
              >
                <option value="">{t("admin.users.select") || "Select"}</option>
                {languages.map((language: string) => (
                  <option key={language} value={language}>
                    {language}
                  </option>
                ))}
              </select>
            </label>
            {fieldError("learning")}
          </div>
        </div>

        <div className="rounded-card border border-line px-4 py-3 dark:border-line-dark">
          <label className="flex items-center gap-2 text-sm text-ink-700 dark:text-ink-200">
            <input
              data-testid="edit-user-vip"
              type="checkbox"
              checked={vip}
              onChange={(e) => {
                setVip(e.target.checked);
                setVipTouched(true);
              }}
            />
            {t("admin.users.vip") || "VIP"}
          </label>

          {vip ? (
            <label className={`${labelClass} mt-3`}>
              {t("admin.users.vipDays") || "Days"}
              <input
                data-testid="edit-user-vip-days"
                type="number"
                min={1}
                value={vipDays}
                onChange={(e) => {
                  setVipDays(e.target.value);
                  setVipTouched(true);
                }}
                className={`${fieldClass} max-w-[8rem]`}
              />
            </label>
          ) : null}

          <p className="pt-2 text-xs text-ink-500 dark:text-ink-400">
            {vip
              ? t("admin.users.vipGrantNote") ||
                "The subscription runs from today and does not auto-renew."
              : t("admin.users.vipRevokeNote") ||
                "Switching VIP off ends the subscription immediately."}
          </p>
        </div>

        {formError ? (
          <div
            data-testid="edit-user-form-error"
            role="alert"
            className="rounded-card border border-red-300 bg-red-50 px-3 py-2 text-sm text-red-700 dark:border-red-500/40 dark:bg-red-500/10 dark:text-red-300"
          >
            {formError}
          </div>
        ) : null}

        <div className="flex justify-end gap-2 border-t border-line pt-4 dark:border-line-dark">
          <button
            type="button"
            data-testid="edit-user-cancel"
            onClick={onClose}
            className={buttonClass}
          >
            {t("admin.common.cancel") || "Cancel"}
          </button>
          <button
            type="submit"
            data-testid="edit-user-submit"
            disabled={!!updateState.isLoading}
            aria-busy={!!updateState.isLoading}
            className="rounded-chip bg-brand-deep px-3 py-1.5 text-sm font-semibold text-white hover:bg-brand-dark disabled:cursor-not-allowed disabled:opacity-50"
          >
            {t("admin.users.saveChanges") || "Save changes"}
          </button>
        </div>
      </form>
    </DialogShell>
  );
};

export default EditUserDialog;
