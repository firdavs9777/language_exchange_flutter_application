import React from "react";
import { Link } from "react-router-dom";
import { useSendCodeEmailMutation } from "../../store/slices/usersSlice";

import { Bounce, toast } from "react-toastify";
import { useTranslation } from "react-i18next";
import AuthShell from "./AuthShell";

interface EnterEmailProps {
  email: string;
  setEmail: (email: string) => void;
  onNext: () => void;
}
interface SendCodeEmailResponse {
  success: boolean;
  statusCode: number;
  message: string; // Adjust based on actual response
}
const EnterEmail: React.FC<EnterEmailProps> = ({ email, setEmail, onNext }) => {
  const [sendCodeEmail, { isLoading }] = useSendCodeEmailMutation({});
  const { t } = useTranslation();
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const response = await sendCodeEmail({ email }).unwrap();

      const typedResponse = response as SendCodeEmailResponse;

      if (typedResponse.success) {
        toast.success(t("authentication.enterEmail.successMessage"), {
          autoClose: 3000,
          hideProgressBar: false,
          theme: "dark",
          transition: Bounce,
        });
        onNext();
      }
    } catch (error: any) {
      console.log(error);
      toast.error(
        error?.data?.error || error?.data?.message || "Failed to send the code",
        {
          autoClose: 4000,
          hideProgressBar: false,
          theme: "colored",
          transition: Bounce,
        }
      );
    }
  };

  return (
    <AuthShell
      title={t("authentication.enterEmail.title")}
      subtitle={t("authentication.enterEmail.subtitle") || undefined}
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label
            htmlFor="reset-email"
            className="block text-sm font-medium text-gray-700 mb-1"
          >
            {t("authentication.enterEmail.emailLabel")}
          </label>
          <input
            id="reset-email"
            type="email"
            placeholder={t("authentication.enterEmail.emailPlaceholder")}
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            className="w-full rounded-lg border px-3 py-2 focus:outline-none focus:ring-2 focus:ring-teal-400 focus:border-transparent"
          />
        </div>
        <button
          type="submit"
          disabled={isLoading}
          className="w-full bg-[#00BFA5] text-white rounded-lg py-2 disabled:opacity-50"
        >
          {isLoading
            ? t("authentication.enterEmail.sendingButton")
            : t("authentication.enterEmail.sendButton")}
        </button>
        <p className="text-center text-sm text-gray-500">
          <Link to="/login" className="text-[#00BFA5] hover:underline">
            {t("authentication.passwordReset.backToLogin")}
          </Link>
        </p>
      </form>
    </AuthShell>
  );
};

export default EnterEmail;
