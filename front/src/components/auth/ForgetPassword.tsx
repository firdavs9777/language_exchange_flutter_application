import React, { useState } from "react";
import EnterEmail from "./EnterEmail";
import VerifyCode from "./VerifyCode";
import SetNewPassword from "./SetNewPassword";
import { useResetPasswordUserMutation } from "../../store/slices/usersSlice";
import { Bounce, toast } from "react-toastify";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";

interface SendCodeEmailResponse {
  success: boolean;
  statusCode: number;
  message: string;
}
const ForgetPassword: React.FC = () => {
  const [step, setStep] = useState(1);
  const [email, setEmail] = useState("");
  const [code, setCode] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [resetPassword] = useResetPasswordUserMutation(
    {}
  );
  const {t} = useTranslation()
  const handleNext = () => setStep((prev) => prev + 1);
  const handlePrevious = () => setStep((prev) => prev - 1);
  const navigate = useNavigate();

  const handlePasswordReset = async () => {
    try {
      const response = await resetPassword({
        email,
        newPassword,
      }).unwrap();
      const typedResponse = response as SendCodeEmailResponse;
      if (typedResponse.success) {
        toast.success(t("authentication.passwordReset.successMessage"), {
          autoClose: 3000,
          hideProgressBar: false,
          theme: "dark",
          transition: Bounce,
        });
        setCode("");
        setNewPassword("");
        setConfirmPassword("");
        navigate("/login");
      }
    } catch (error: any) {
      toast.error(`${error?.data?.error}`, {
        autoClose: 3000,
        hideProgressBar: false,
        theme: "dark",
        transition: Bounce,
      });
    }
  };
  return (
    <div>
      {step === 1 && (
        <EnterEmail email={email} setEmail={setEmail} onNext={handleNext} />
      )}
      {step === 2 && (
        <VerifyCode
          code={code}
          email={email}
          setCode={setCode}
          onPrevious={handlePrevious}
          onNext={handleNext}
        />
      )}
      {step === 3 && (
        <SetNewPassword
          newPassword={newPassword}
          confirmPassword={confirmPassword}
          setNewPassword={setNewPassword}
          setConfirmPassword={setConfirmPassword}
          onSubmit={handlePasswordReset}
        />
      )}
    </div>
  );
};

export default ForgetPassword;
