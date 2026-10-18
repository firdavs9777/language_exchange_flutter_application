import React, { useMemo, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import ISO6391 from "iso-639-1";
import { Check, Copy, ExternalLink, RefreshCw } from "lucide-react";
import { useCreateUserMutation } from "../../../store/slices/adminSlice";
import DialogShell from "../../../design/DialogShell";
import { passwordStrength, isAdult } from "../../auth/register/validators";
import { EMAIL_RE } from "../../../utils/validation";

export interface RegisterUserDialogProps {
  onClose: () => void;
}

/** What `POST /admin/users` returns: `{ id, name, email, role }`. */
interface CreatedUser {
  id: string;
  name: string;
  email: string;
  role: string;
}

// Ambiguous glyphs are out on purpose: this password gets read aloud or
// retyped from a chat message at least once before it is changed.
const UPPER = "ABCDEFGHJKLMNPQRSTUVWXYZ";
const LOWER = "abcdefghijkmnopqrstuvwxyz";
const DIGITS = "23456789";
const SYMBOLS = "!@#$%^&*?-_+=";
const ALL = UPPER + LOWER + DIGITS + SYMBOLS;
const PASSWORD_LENGTH = 14;

/** Random integers from the platform CSPRNG, falling back to Math.random. */
const randomInts = (count: number): number[] => {
  const crypto: any = typeof globalThis !== "undefined" ? (globalThis as any).crypto : undefined;
  if (crypto && typeof crypto.getRandomValues === "function") {
    const bytes = new Uint32Array(count);
    crypto.getRandomValues(bytes);
    return Array.prototype.slice.call(bytes);
  }
  const out: number[] = [];
  for (let i = 0; i < count; i += 1) out.push(Math.floor(Math.random() * 0xffffffff));
  return out;
};

/**
 * A 14-character password with at least one of each class.
 *
 * One of each is placed first and the rest filled from the whole alphabet,
 * then the result is shuffled — picking at random and hoping for coverage
 * fails often enough at this length to matter, and a password the account
 * policy rejects is worse than a predictable position.
 */
export function generatePassword(length: number = PASSWORD_LENGTH): string {
  const pools = [UPPER, LOWER, DIGITS, SYMBOLS];
  const draws = randomInts(length * 2);
  const chars: string[] = pools.map((pool, i) => pool[draws[i] % pool.length]);
  for (let i = pools.length; i < length; i += 1) chars.push(ALL[draws[i] % ALL.length]);

  // Fisher-Yates, so the guaranteed classes are not always in positions 0-3.
  for (let i = chars.length - 1; i > 0; i -= 1) {
    const j = draws[length + i] % (i + 1);
    const swap = chars[i];
    chars[i] = chars[j];
    chars[j] = swap;
  }
  return chars.join("");
}

const MONTHS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
const DAYS: number[] = [];
for (let d = 1; d <= 31; d += 1) DAYS.push(d);

const pad = (value: string): string => (value.length === 1 ? `0${value}` : value);

const emptyForm = {
  name: "",
  email: "",
  password: "",
  gender: "",
  year: "",
  month: "",
  day: "",
  native: "",
  learning: "",
  role: "user",
  bio: "",
};

type Form = typeof emptyForm;
type Errors = { [key: string]: string };

/**
 * Register a user from the console.
 *
 * Mirrors `utils/registration.js` on the backend field for field — required
 * list, and native_language !== language_to_learn — so the common mistakes
 * are caught before a request is built, and only what the client cannot know
 * (a duplicate email) comes back from the server. The created account carries
 * `termsAccepted: false` by design: consent cannot be given on someone's
 * behalf, which is why the success panel says the app will ask for it.
 */
const RegisterUserDialog: React.FC<RegisterUserDialogProps> = ({ onClose }) => {
  const { t } = useTranslation();
  const [createUser, createState] = useCreateUserMutation();
  const [form, setForm] = useState<Form>(emptyForm);
  const [markVerified, setMarkVerified] = useState(true);
  const [errors, setErrors] = useState<Errors>({});
  const [formError, setFormError] = useState("");
  const [created, setCreated] = useState<CreatedUser | null>(null);
  const [issuedPassword, setIssuedPassword] = useState("");
  const [copied, setCopied] = useState(false);
  const firstFieldRef = useRef<HTMLInputElement | null>(null);

  const languages = useMemo(
    () => ISO6391.getAllCodes().map((code: string) => ISO6391.getName(code)),
    []
  );

  // 18 is the floor the app's own signup enforces; a century is as far back as
  // a real birth year goes.
  const years = useMemo(() => {
    const newest = new Date().getFullYear() - 18;
    const list: number[] = [];
    for (let y = newest; y >= newest - 82; y -= 1) list.push(y);
    return list;
  }, []);

  const change = (key: keyof Form) => (
    event: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>
  ) => {
    const value = event.target.value;
    setForm((prev) => ({ ...prev, [key]: value }));
  };

  const required = t("admin.users.required") || "Required";

  const validate = (): Errors => {
    const next: Errors = {};
    if (!form.name.trim()) next.name = required;

    if (!form.email.trim()) next.email = required;
    else if (!EMAIL_RE.test(form.email.trim())) {
      next.email = t("admin.users.invalidEmail") || "Please use a valid email";
    }

    if (!form.password) next.password = required;
    else if (!passwordStrength(form.password).valid) {
      next.password =
        t("admin.users.weakPassword") ||
        "At least 8 characters, with upper and lower case letters and a number";
    }

    if (!form.gender) next.gender = required;

    if (!form.year || !form.month || !form.day) next.birth = required;
    else if (!isAdult(`${form.year}-${pad(form.month)}-${pad(form.day)}`)) {
      next.birth = t("admin.users.under18") || "The user must be at least 18 years old";
    }

    if (!form.native) next.native = required;
    if (!form.learning) next.learning = required;
    else if (
      form.native &&
      form.native.trim().toLowerCase() === form.learning.trim().toLowerCase()
    ) {
      next.learning =
        t("admin.users.sameLanguage") ||
        "Native language and language to learn cannot be the same";
    }

    return next;
  };

  const onSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    const found = validate();
    setErrors(found);
    setFormError("");
    if (Object.keys(found).length > 0) return;

    const body: any = {
      name: form.name.trim(),
      email: form.email.trim().toLowerCase(),
      password: form.password,
      gender: form.gender,
      birth_year: Number(form.year),
      birth_month: Number(form.month),
      birth_day: Number(form.day),
      native_language: form.native,
      language_to_learn: form.learning,
      role: form.role,
      markVerified,
    };
    if (form.bio.trim()) body.bio = form.bio.trim();

    try {
      const data: any = await createUser(body).unwrap();
      setIssuedPassword(form.password);
      setCreated((data && data.data) || data);
    } catch (err) {
      const error: any = err || {};
      const message: string =
        (error.data && (error.data.message || error.data.error)) ||
        error.message ||
        t("admin.users.createFailed") ||
        "That didn't work. No account was created.";
      const duplicate =
        error.status === 409 || (error.data && error.data.code === "EMAIL_EXISTS");
      if (duplicate) setErrors({ email: message });
      else setFormError(message);
    }
  };

  const copy = (value: string) => {
    const nav: any = typeof navigator !== "undefined" ? navigator : undefined;
    if (nav && nav.clipboard && typeof nav.clipboard.writeText === "function") {
      nav.clipboard.writeText(value);
    }
    setCopied(true);
  };

  const addAnother = () => {
    setForm(emptyForm);
    setMarkVerified(true);
    setErrors({});
    setFormError("");
    setIssuedPassword("");
    setCopied(false);
    setCreated(null);
    if (typeof createState.reset === "function") createState.reset();
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
        data-testid={`register-user-error-${key}`}
        className="pt-1 text-xs text-red-700 dark:text-red-300"
      >
        {errors[key]}
      </p>
    ) : null;

  const title = created
    ? t("admin.users.createdTitle") || "User created"
    : t("admin.users.addUser") || "Add user";

  return (
    <DialogShell
      labelledBy="register-user-dialog-title"
      onClose={onClose}
      testId="register-user-dialog"
      backdropTestId="register-user-dialog-backdrop"
      panelClassName={[
        "relative w-full max-w-2xl max-h-[90vh] overflow-y-auto rounded-card border border-line",
        "bg-surface p-5 shadow-lg dark:border-line-dark dark:bg-cardbg-dark",
      ].join(" ")}
      initialFocusRef={firstFieldRef}
    >
      <h2
        id="register-user-dialog-title"
        className="font-display text-base text-ink-900 dark:text-ink-50"
      >
        {title}
      </h2>

      {created ? (
        <div data-testid="register-user-success" className="mt-4 space-y-4 text-sm">
          <div className="rounded-card border border-line px-4 py-3 dark:border-line-dark">
            <div className="text-ink-800 dark:text-ink-100">{created.name}</div>
            <div className="text-ink-600 dark:text-ink-300">{created.email}</div>
            <div className="pt-1 text-xs text-ink-500 dark:text-ink-400">
              {`${t("admin.users.userId") || "User id"}: ${created.id}`}
            </div>
          </div>

          <div className="rounded-card border border-line px-4 py-3 dark:border-line-dark">
            <div className={labelClass}>{t("admin.users.password") || "Password"}</div>
            <div className="mt-1 flex items-center gap-2">
              <code
                data-testid="register-user-success-password"
                className="flex-1 break-all font-mono text-sm text-ink-900 dark:text-ink-50"
              >
                {issuedPassword}
              </code>
              <button
                type="button"
                data-testid="register-user-success-copy"
                onClick={() => copy(issuedPassword)}
                className={buttonClass}
              >
                {copied ? (
                  <Check className="h-4 w-4" aria-hidden />
                ) : (
                  <Copy className="h-4 w-4" aria-hidden />
                )}
                <span className="sr-only">{t("admin.users.copy") || "Copy"}</span>
              </button>
            </div>
            <p className="pt-2 text-xs text-ink-500 dark:text-ink-400">
              {t("admin.users.passwordOnce") ||
                "This is the only time the password is shown. Send it to the user and ask them to change it."}
            </p>
          </div>

          <p className="text-xs text-ink-600 dark:text-ink-300">
            {t("admin.users.termsNote") ||
              "Consent cannot be given on someone's behalf: the app will ask this user to accept the terms the first time they sign in."}
          </p>

          <div className="flex flex-wrap justify-end gap-2 border-t border-line pt-4 dark:border-line-dark">
            <a
              data-testid="register-user-open-profile"
              href={`/profile/${created.id}`}
              target="_blank"
              rel="noreferrer"
              className={`${buttonClass} inline-flex items-center gap-1.5`}
            >
              <ExternalLink className="h-4 w-4" aria-hidden />
              {t("admin.users.openProfile") || "Open profile"}
            </a>
            <button
              type="button"
              data-testid="register-user-add-another"
              onClick={addAnother}
              className={buttonClass}
            >
              {t("admin.users.addAnother") || "Add another"}
            </button>
            <button
              type="button"
              data-testid="register-user-done"
              onClick={onClose}
              className="rounded-chip bg-brand-deep px-3 py-1.5 text-sm font-semibold text-white hover:bg-brand-dark"
            >
              {t("admin.users.done") || "Done"}
            </button>
          </div>
        </div>
      ) : (
        <form onSubmit={onSubmit} noValidate className="mt-4 space-y-4">
          <div className="grid gap-4 sm:grid-cols-2">
            <div>
              <label className={labelClass}>
                {t("admin.users.name") || "Name"}
                <input
                  data-testid="register-user-name"
                  ref={firstFieldRef}
                  type="text"
                  value={form.name}
                  onChange={change("name")}
                  className={fieldClass}
                />
              </label>
              {fieldError("name")}
            </div>

            <div>
              <label className={labelClass}>
                {t("admin.users.email") || "Email"}
                <input
                  data-testid="register-user-email"
                  type="email"
                  autoComplete="off"
                  value={form.email}
                  onChange={change("email")}
                  className={fieldClass}
                />
              </label>
              {fieldError("email")}
            </div>
          </div>

          <div>
            <label className={labelClass}>
              {t("admin.users.password") || "Password"}
              <div className="mt-1 flex items-center gap-2">
                <input
                  data-testid="register-user-password"
                  type="text"
                  autoComplete="new-password"
                  value={form.password}
                  onChange={change("password")}
                  className={`${fieldClass} mt-0`}
                />
                <button
                  type="button"
                  data-testid="register-user-generate"
                  onClick={() => {
                    setForm((prev) => ({ ...prev, password: generatePassword() }));
                    setCopied(false);
                  }}
                  className={`${buttonClass} inline-flex items-center gap-1.5 whitespace-nowrap`}
                >
                  <RefreshCw className="h-4 w-4" aria-hidden />
                  {t("admin.users.generate") || "Generate"}
                </button>
                {form.password ? (
                  <button
                    type="button"
                    data-testid="register-user-copy"
                    onClick={() => copy(form.password)}
                    aria-label={t("admin.users.copy") || "Copy"}
                    className={buttonClass}
                  >
                    {copied ? (
                      <Check className="h-4 w-4" aria-hidden />
                    ) : (
                      <Copy className="h-4 w-4" aria-hidden />
                    )}
                  </button>
                ) : null}
              </div>
            </label>
            {fieldError("password")}
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <div>
              <label className={labelClass}>
                {t("admin.users.gender") || "Gender"}
                <select
                  data-testid="register-user-gender"
                  value={form.gender}
                  onChange={change("gender")}
                  className={fieldClass}
                >
                  <option value="">{t("admin.users.select") || "Select"}</option>
                  <option value="male">{t("admin.users.male") || "Male"}</option>
                  <option value="female">{t("admin.users.female") || "Female"}</option>
                  <option value="other">{t("admin.users.other") || "Other"}</option>
                </select>
              </label>
              {fieldError("gender")}
            </div>

            <div>
              <span className={labelClass}>{t("admin.users.birthDate") || "Birth date"}</span>
              <div className="mt-1 grid grid-cols-3 gap-2">
                <select
                  data-testid="register-user-birth-year"
                  aria-label={t("admin.users.birthYear") || "Birth year"}
                  value={form.year}
                  onChange={change("year")}
                  className={`${fieldClass} mt-0`}
                >
                  <option value="">{t("admin.users.year") || "Year"}</option>
                  {years.map((y) => (
                    <option key={y} value={String(y)}>
                      {y}
                    </option>
                  ))}
                </select>
                <select
                  data-testid="register-user-birth-month"
                  aria-label={t("admin.users.birthMonth") || "Birth month"}
                  value={form.month}
                  onChange={change("month")}
                  className={`${fieldClass} mt-0`}
                >
                  <option value="">{t("admin.users.month") || "Month"}</option>
                  {MONTHS.map((m) => (
                    <option key={m} value={String(m)}>
                      {m}
                    </option>
                  ))}
                </select>
                <select
                  data-testid="register-user-birth-day"
                  aria-label={t("admin.users.birthDay") || "Birth day"}
                  value={form.day}
                  onChange={change("day")}
                  className={`${fieldClass} mt-0`}
                >
                  <option value="">{t("admin.users.day") || "Day"}</option>
                  {DAYS.map((d) => (
                    <option key={d} value={String(d)}>
                      {d}
                    </option>
                  ))}
                </select>
              </div>
              {fieldError("birth")}
            </div>
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <div>
              <label className={labelClass}>
                {t("admin.users.nativeLanguage") || "Native language"}
                <select
                  data-testid="register-user-native"
                  value={form.native}
                  onChange={change("native")}
                  className={fieldClass}
                >
                  <option value="">{t("admin.users.select") || "Select"}</option>
                  {languages.map((name: string) => (
                    <option key={name} value={name}>
                      {name}
                    </option>
                  ))}
                </select>
              </label>
              {fieldError("native")}
            </div>

            <div>
              <label className={labelClass}>
                {t("admin.users.learningLanguage") || "Language to learn"}
                <select
                  data-testid="register-user-learning"
                  value={form.learning}
                  onChange={change("learning")}
                  className={fieldClass}
                >
                  <option value="">{t("admin.users.select") || "Select"}</option>
                  {languages.map((name: string) => (
                    <option key={name} value={name}>
                      {name}
                    </option>
                  ))}
                </select>
              </label>
              {fieldError("learning")}
            </div>
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <div>
              <label className={labelClass}>
                {t("admin.users.role") || "Role"}
                <select
                  data-testid="register-user-role"
                  value={form.role}
                  onChange={change("role")}
                  className={fieldClass}
                >
                  <option value="user">{t("admin.users.roleUser") || "User"}</option>
                  <option value="admin">{t("admin.users.roleAdmin") || "Admin"}</option>
                </select>
              </label>
            </div>

            <label className="flex items-end gap-2 pb-2 text-sm text-ink-700 dark:text-ink-200">
              <input
                data-testid="register-user-verified"
                type="checkbox"
                checked={markVerified}
                onChange={(e) => setMarkVerified(e.target.checked)}
              />
              {t("admin.users.markVerified") || "Mark email verified"}
            </label>
          </div>

          <div>
            <label className={labelClass}>
              {`${t("admin.users.bio") || "Bio"} (${t("admin.users.optional") || "optional"})`}
              <textarea
                data-testid="register-user-bio"
                rows={2}
                value={form.bio}
                onChange={change("bio")}
                className={fieldClass}
              />
            </label>
          </div>

          {formError ? (
            <div
              data-testid="register-user-form-error"
              role="alert"
              className="rounded-card border border-red-300 bg-red-50 px-3 py-2 text-sm text-red-700 dark:border-red-500/40 dark:bg-red-500/10 dark:text-red-300"
            >
              {formError}
            </div>
          ) : null}

          <div className="flex justify-end gap-2 border-t border-line pt-4 dark:border-line-dark">
            <button
              type="button"
              data-testid="register-user-cancel"
              onClick={onClose}
              className={buttonClass}
            >
              {t("admin.common.cancel") || "Cancel"}
            </button>
            <button
              type="submit"
              data-testid="register-user-submit"
              disabled={!!createState.isLoading}
              aria-busy={!!createState.isLoading}
              className="rounded-chip bg-brand-deep px-3 py-1.5 text-sm font-semibold text-white hover:bg-brand-dark disabled:cursor-not-allowed disabled:opacity-50"
            >
              {t("admin.users.createUser") || "Create user"}
            </button>
          </div>
        </form>
      )}
    </DialogShell>
  );
};

export default RegisterUserDialog;
