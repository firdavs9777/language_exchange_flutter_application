import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { Eye, EyeOff } from "lucide-react";
import { Bounce, toast } from "react-toastify";
import { passwordStrength } from "./register/validators";
import PasswordStrengthMeter from "./register/PasswordStrengthMeter";
import AuthShell from "./AuthShell";

interface SetNewPasswordProps {
  newPassword: string;
  confirmPassword: string;
  setNewPassword: (val: string) => void;
  setConfirmPassword: (val: string) => void;
  onSubmit: () => void;
  isLoading?: boolean;
}

const SetNewPassword: React.FC<SetNewPasswordProps> = ({
  newPassword,
  confirmPassword,
  setNewPassword,
  setConfirmPassword,
  onSubmit,
  isLoading,
}) => {
  const { t } = useTranslation();
  const [showPassword, setShowPassword] = useState(false);
  const isPasswordValid = passwordStrength(newPassword).valid;
  const passwordsMatch = newPassword === confirmPassword;
  const canSubmit = isPasswordValid && passwordsMatch && !isLoading;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!isPasswordValid) {
      toast.error(t("authentication.passwordReset.strengthErrorMessage"), {
        autoClose: 3000,
        hideProgressBar: false,
        theme: "dark",
        transition: Bounce,
      });
      return;
    }
    if (!passwordsMatch) {
      toast.error(t("authentication.passwordReset.mismatchErrorMessage"), {
        autoClose: 3000,
        hideProgressBar: false,
        theme: "dark",
        transition: Bounce,
      });
      return;
    }
    onSubmit();
  };

  return (
    <AuthShell
      title={t("authentication.passwordReset.setPasswordTitle")}
      subtitle={t("authentication.passwordReset.setPasswordSubtitle") || undefined}
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label
            htmlFor="new-password"
            className="block text-sm font-medium text-gray-700 mb-1"
          >
            {t("authentication.passwordReset.newPasswordLabel")}
          </label>
          <div className="relative">
            <input
              id="new-password"
              type={showPassword ? "text" : "password"}
              placeholder={t("authentication.passwordReset.newPasswordPlaceholder")}
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              required
              className="w-full rounded-lg border px-3 py-2 pr-10 focus:outline-none focus:ring-2 focus:ring-teal-400 focus:border-transparent"
            />
            <button
              type="button"
              onClick={() => setShowPassword((prev) => !prev)}
              aria-label={
                showPassword
                  ? t("authentication.passwordReset.hidePassword")
                  : t("authentication.passwordReset.showPassword")
              }
              className="absolute inset-y-0 right-0 flex items-center pr-3 text-gray-400 hover:text-gray-600"
            >
              {showPassword ? (
                <EyeOff className="w-4 h-4" />
              ) : (
                <Eye className="w-4 h-4" />
              )}
            </button>
          </div>
          <div className="mt-2">
            <PasswordStrengthMeter password={newPassword} />
          </div>
        </div>
        <div>
          <label
            htmlFor="confirm-password"
            className="block text-sm font-medium text-gray-700 mb-1"
          >
            {t("authentication.passwordReset.confirmPasswordLabel")}
          </label>
          <input
            id="confirm-password"
            type={showPassword ? "text" : "password"}
            placeholder={t("authentication.passwordReset.confirmPasswordPlaceholder")}
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            required
            className="w-full rounded-lg border px-3 py-2 focus:outline-none focus:ring-2 focus:ring-teal-400 focus:border-transparent"
          />
        </div>
        <button
          type="submit"
          disabled={!canSubmit}
          className="w-full bg-[#00BFA5] text-white rounded-lg py-2 disabled:opacity-50"
        >
          {isLoading
            ? t("authentication.passwordReset.submittingButton")
            : t("authentication.passwordReset.submitButton")}
        </button>
      </form>
    </AuthShell>
  );
};

export default SetNewPassword;
