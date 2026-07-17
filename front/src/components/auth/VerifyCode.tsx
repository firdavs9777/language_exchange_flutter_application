import React from "react";
import { useTranslation } from "react-i18next";
import {
  useVerifyCodeEmailMutation,
  useSendCodeEmailMutation,
} from "../../store/slices/usersSlice";
import { Bounce, toast } from "react-toastify";
import AuthShell from "./AuthShell";

interface VerifyCodeProps {
  code: string;
  email: string;
  setCode: (code: string) => void;
  onNext: () => void;
  onPrevious: () => void;
}

const VerifyCode: React.FC<VerifyCodeProps> = ({
  email,
  code,
  setCode,
  onNext,
  onPrevious,
}) => {
  const { t } = useTranslation();
  const [verifyCodeEmail, { isLoading }] = useVerifyCodeEmailMutation({});
  const [sendCodeEmail, { isLoading: isResending }] = useSendCodeEmailMutation(
    {}
  );
  interface SendCodeEmailResponse {
    success: boolean;
    statusCode: number;
    message: string;
  }
  const previousHandler = () => {
    onPrevious();
  };
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const response = await verifyCodeEmail({ email, code }).unwrap();
      const typedResponse = response as SendCodeEmailResponse;
      if (typedResponse.success) {
        toast.success(t("authentication.passwordReset.verifySuccessMessage"), {
          autoClose: 3000,
          hideProgressBar: false,
          theme: "dark",
          transition: Bounce,
        });
        // Keep the verified code in parent state — it's required by the
        // reset-password request in the next step.
        setCode(code);
        onNext();
      }
    } catch (error: any) {
      toast.error(
        error?.data?.error ||
          error?.data?.message ||
          t("authentication.passwordReset.verifyErrorDefault"),
        {
          autoClose: 4000,
          hideProgressBar: false,
          theme: "colored",
          transition: Bounce,
        }
      );
    }
  };

  const handleResend = async () => {
    try {
      const response = await sendCodeEmail({ email }).unwrap();
      const typedResponse = response as SendCodeEmailResponse;
      if (typedResponse.success) {
        toast.success(t("authentication.passwordReset.resendSuccessMessage"), {
          autoClose: 3000,
          hideProgressBar: false,
          theme: "dark",
          transition: Bounce,
        });
      }
    } catch (error: any) {
      toast.error(
        error?.data?.error ||
          error?.data?.message ||
          t("authentication.passwordReset.resendErrorDefault"),
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
      title={t("authentication.passwordReset.verifyTitle")}
      subtitle={t("authentication.passwordReset.verifySubtitle") || undefined}
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label
            htmlFor="verification-code"
            className="block text-sm font-medium text-gray-700 mb-1"
          >
            {t("authentication.passwordReset.codeLabel")}
          </label>
          <input
            id="verification-code"
            type="text"
            placeholder={t("authentication.passwordReset.codePlaceholder")}
            value={code}
            onChange={(e) => setCode(e.target.value)}
            required
            className="w-full rounded-lg border px-3 py-2 focus:outline-none focus:ring-2 focus:ring-teal-400 focus:border-transparent"
          />
        </div>
        <div className="flex gap-3">
          <button
            type="button"
            onClick={previousHandler}
            className="flex-1 rounded-lg py-2 border border-gray-300 text-gray-700 hover:bg-gray-50"
          >
            {t("authentication.passwordReset.previousButton")}
          </button>
          <button
            type="submit"
            disabled={isLoading}
            className="flex-1 bg-[#00BFA5] text-white rounded-lg py-2 disabled:opacity-50"
          >
            {isLoading
              ? t("authentication.passwordReset.verifyingButton")
              : t("authentication.passwordReset.verifyButton")}
          </button>
        </div>
        <button
          type="button"
          onClick={handleResend}
          disabled={isResending}
          className="w-full text-sm text-[#00BFA5] hover:underline disabled:opacity-50"
        >
          {isResending
            ? t("authentication.passwordReset.resendingButton")
            : t("authentication.passwordReset.resendButton")}
        </button>
      </form>
    </AuthShell>
  );
};

export default VerifyCode;
