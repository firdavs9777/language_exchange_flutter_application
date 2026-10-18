import React, { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { useTranslation } from "react-i18next";
import { Bounce, toast } from "react-toastify";
import { ArrowLeft, Check, Loader2, Lock, X } from "lucide-react";
import SurfaceCard from "../../design/SurfaceCard";
import { useUpdatePasswordMutation } from "../../store/slices/usersSlice";
import { setCredentials } from "../../store/slices/authSlice";

export type PasswordProblem = "length" | "upper" | "lower" | "number" | "charset";

/**
 * What is wrong with a proposed new password, by the server's own rule.
 *
 * `controllers/auth.js:updatePassword` tests
 * `/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$/` and answers 400
 * when it fails. The last clause is the one people trip on: only `@$!%*?&` are
 * allowed beyond letters and digits, so `#` or a space is refused even in an
 * otherwise strong password. Checked here so the form says which rule failed
 * rather than letting the server answer with all of them at once.
 */
export function passwordProblems(value: string): PasswordProblem[] {
  const problems: PasswordProblem[] = [];
  if (/[^a-zA-Z\d@$!%*?&]/.test(value)) return ["charset"];
  if (!/[A-Z]/.test(value)) problems.push("upper");
  if (!/[a-z]/.test(value)) problems.push("lower");
  if (!/\d/.test(value)) problems.push("number");
  if (value.length < 8) problems.push("length");
  return problems;
}

const FIELD =
  "w-full rounded-chip border border-line bg-surface px-3 py-2.5 text-sm text-ink-900 placeholder:text-ink-400 focus:border-brand focus:outline-none dark:border-line-dark dark:bg-cardbg-dark dark:text-ink-50";
const LABEL = "block pb-1.5 text-sm font-semibold text-ink-700 dark:text-ink-200";
const ERROR = "pt-1 text-xs font-medium text-red-600 dark:text-red-400";
const TOAST = { autoClose: 2500, theme: "dark" as "dark", transition: Bounce };

/**
 * Change the password from inside the app, with the current one as proof.
 *
 * Settings used to send everyone to /forgot-password — the email reset flow —
 * which works, but asks someone who knows their password to leave the app,
 * open their inbox and come back. The app has had this screen
 * (change_password_screen.dart) all along.
 *
 * Accounts signed up through Google, Apple or Facebook have no password to
 * prove, so Settings keeps sending them to the reset flow, where they can set
 * one. A wrong current password is a 401 from the controller, which apiSlice
 * is told not to mistake for an expired session; the server's message is
 * shown as it comes.
 */
const ChangePassword: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const userInfo = useSelector((state: any) => state.auth.userInfo);
  const [updatePassword, { isLoading }] = useUpdatePasswordMutation();

  const [current, setCurrent] = useState("");
  const [next, setNext] = useState("");
  const [confirm, setConfirm] = useState("");
  const [serverError, setServerError] = useState("");

  const problems = passwordProblems(next);
  const mismatch = confirm.length > 0 && confirm !== next;
  const same = next.length > 0 && next === current;
  const ready =
    current.length > 0 && next.length > 0 && problems.length === 0 && !mismatch && !same &&
    confirm === next;

  const rules: Array<{ key: PasswordProblem; label: string }> = [
    { key: "length", label: t("settings.password.new_hint") || "At least 8 chars, A-Z, a-z, 0-9" },
    { key: "upper", label: t("settings.password.rule_upper") || "One uppercase letter" },
    { key: "lower", label: t("settings.password.rule_lower") || "One lowercase letter" },
    { key: "number", label: t("settings.password.rule_number") || "One number" },
  ];

  const handleSubmit = async (event: React.FormEvent): Promise<void> => {
    event.preventDefault();
    if (!ready || isLoading) return;
    setServerError("");
    try {
      const result: any = await updatePassword({
        currentPassword: current,
        newPassword: next,
      }).unwrap();
      // The response is a fresh sendTokenResponse. Keep it: it is the token
      // issued against the new password.
      if (result && result.token) {
        dispatch(
          setCredentials({
            ...userInfo,
            token: result.token,
            refreshToken: result.refreshToken || (userInfo && userInfo.refreshToken),
          })
        );
      }
      toast.success(
        t("settings.password.success") || "Password changed successfully",
        TOAST
      );
      navigate("/settings");
    } catch (error: any) {
      setServerError(
        (error && error.data && error.data.message) ||
          t("settings.password.failed") ||
          "Failed to update"
      );
    }
  };

  return (
    <div className="min-h-screen bg-canvas dark:bg-canvas-dark">
      <div className="mx-auto w-full max-w-lg px-4 pb-16 pt-6">
        <div className="flex items-center gap-2 pb-4">
          <Link
            to="/settings"
            aria-label={t("profile.edit.back") || "Back"}
            className="inline-flex h-10 w-10 items-center justify-center rounded-full text-ink-500 hover:bg-ink-50 dark:hover:bg-white/5"
          >
            <ArrowLeft className="h-5 w-5" aria-hidden />
          </Link>
          <h1 className="font-display text-xl text-ink-900 dark:text-ink-50">
            {t("settings.password.title") || "Change password"}
          </h1>
        </div>

        <SurfaceCard padding="lg">
          <form onSubmit={handleSubmit} noValidate className="space-y-4">
            <div>
              <label htmlFor="password-current" className={LABEL}>
                {t("settings.password.current") || "Current password"}
              </label>
              <input
                id="password-current"
                data-testid="password-current"
                type="password"
                autoComplete="current-password"
                value={current}
                onChange={(event) => {
                  setCurrent(event.target.value);
                  setServerError("");
                }}
                placeholder={t("settings.password.current_hint") || "Enter your current password"}
                className={FIELD}
              />
              <Link
                to="/forgot-password"
                data-testid="password-forgot"
                className="inline-block pt-1.5 text-xs font-semibold text-brand hover:underline"
              >
                {t("authentication.login.forgotPassword") || "Forgot Password?"}
              </Link>
            </div>

            <div>
              <label htmlFor="password-new" className={LABEL}>
                {t("settings.password.new") || "New password"}
              </label>
              <input
                id="password-new"
                data-testid="password-new"
                type="password"
                autoComplete="new-password"
                aria-describedby="password-rules"
                value={next}
                onChange={(event) => setNext(event.target.value)}
                className={FIELD}
              />
              <ul id="password-rules" className="space-y-0.5 pt-2">
                {rules.map((rule) => {
                  const met = next.length > 0 && problems.indexOf(rule.key) === -1 &&
                    problems.indexOf("charset") === -1;
                  return (
                    <li
                      key={rule.key}
                      data-testid={`password-rule-${rule.key}`}
                      data-met={met ? "true" : "false"}
                      className={`flex items-center gap-1.5 text-xs ${
                        met ? "text-emerald-600 dark:text-emerald-400" : "text-ink-500 dark:text-ink-400"
                      }`}
                    >
                      {met ? (
                        <Check className="h-3.5 w-3.5" aria-hidden />
                      ) : (
                        <X className="h-3.5 w-3.5" aria-hidden />
                      )}
                      {rule.label}
                    </li>
                  );
                })}
              </ul>
              {problems.indexOf("charset") > -1 && (
                <p data-testid="password-charset" className={ERROR}>
                  {t("settings.password.symbols") ||
                    "Only these symbols are allowed: @ $ ! % * ? &"}
                </p>
              )}
              {same && (
                <p data-testid="password-same" className={ERROR}>
                  {t("settings.password.same_as_current") ||
                    "New password must be different from current."}
                </p>
              )}
            </div>

            <div>
              <label htmlFor="password-confirm" className={LABEL}>
                {t("settings.password.confirm") || "Confirm new password"}
              </label>
              <input
                id="password-confirm"
                data-testid="password-confirm"
                type="password"
                autoComplete="new-password"
                value={confirm}
                onChange={(event) => setConfirm(event.target.value)}
                placeholder={t("settings.password.confirm_hint") || "Re-enter the new password"}
                className={FIELD}
              />
              {mismatch && (
                <p data-testid="password-mismatch" className={ERROR}>
                  {t("settings.password.mismatch") || "Passwords don't match."}
                </p>
              )}
            </div>

            {serverError && (
              <p
                data-testid="password-error"
                role="alert"
                className="rounded-chip bg-red-50 px-3 py-2 text-sm text-red-700 dark:bg-red-500/10 dark:text-red-300"
              >
                {serverError}
              </p>
            )}

            <button
              type="submit"
              data-testid="password-save"
              disabled={!ready || isLoading}
              className="inline-flex min-h-[44px] w-full items-center justify-center gap-2 rounded-chip bg-brand px-4 text-sm font-semibold text-white transition-opacity disabled:opacity-50"
            >
              {isLoading ? (
                <Loader2 className="h-4 w-4 animate-spin" aria-hidden />
              ) : (
                <Lock className="h-4 w-4" aria-hidden />
              )}
              {t("settings.password.title") || "Change password"}
            </button>
          </form>
        </SurfaceCard>
      </div>
    </div>
  );
};

export default ChangePassword;
