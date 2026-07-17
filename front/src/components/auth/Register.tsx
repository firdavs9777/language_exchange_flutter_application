import React, { useEffect, useRef, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import ISO6391 from "iso-639-1";
import {
  Eye,
  EyeOff,
  Plus,
  X,
  ArrowLeft,
  ArrowRight,
  UserPlus,
  Loader2,
} from "lucide-react";
import {
  useRegisterUserMutation,
  useUploadUserPhotoMutation,
  useVerifyRegistrationCodeMutation,
  useRegisterCodeEmailMutation,
  useUpdateUserByIdMutation,
  useUpdateUserInfoMutation,
  useAcceptTermsMutation,
} from "../../store/slices/usersSlice";
import { Bounce, toast } from "react-toastify";
import { useTranslation } from "react-i18next";
import { useDispatch, useSelector } from "react-redux";
import { setCredentials } from "../../store/slices/authSlice";

import { SIGNUP_STEPS, STEP_LABELS, SignupStep } from "./register/steps";
import { passwordStrength, isAdult } from "./register/validators";
import { buildRegisterPayload, LocationInput } from "./register/buildRegisterPayload";
import UsernameAvailabilityField from "./register/UsernameAvailabilityField";
import PasswordStrengthMeter from "./register/PasswordStrengthMeter";
import LocationField from "./register/LocationField";

export interface User {
  _id: string;
  name: string;
  gender: string;
  email: string;
  bio: string;
  birth_year: string;
  birth_month: string;
  birth_day: string;
  images: string[];
  followers: string[];
  following: string[];
  native_language: string;
  language_to_learn: string;
  createdAt: string;
}

export interface responseType {
  success: boolean;
  token: string;
  option: {
    expires: string;
    httpOnly: boolean;
  };
  user: User;
}

interface VerifyCodeResponse {
  success: boolean;
  statusCode: number;
  message: string;
}

interface SendCodeEmailResponse {
  success: boolean;
  message: string;
  expiresIn?: string;
}

// CEFR proficiency levels (matches the app's language-level picker).
const CEFR_LEVELS = ["A1", "A2", "B1", "B2", "C1", "C2"];

// OAuth users already have email + name, so completion mode only walks the
// remaining profile steps. The fresh-register flow uses the full SIGNUP_STEPS.
const COMPLETION_STEPS: readonly SignupStep[] = ["languages", "photo", "finish"];

const toastError = (message: string) =>
  toast.error(message, {
    autoClose: 4000,
    hideProgressBar: false,
    theme: "colored",
    transition: Bounce,
  });

const toastSuccess = (message: string) =>
  toast.success(message, {
    autoClose: 3000,
    hideProgressBar: false,
    theme: "dark",
    transition: Bounce,
  });

const Register = () => {
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const { t } = useTranslation();
  const { search, state } = useLocation();

  // --- Completion mode (OAuth profile-completion) --------------------------
  // When AuthCallback routes an incomplete Google profile here it passes
  // `state: { oauth: true, startStep: 'languages', userData }`. In that mode we
  // skip email/verify/basics, prefill from userData, and on finish PATCH the
  // profile via updatedetails + record terms instead of registering afresh.
  const routerState = (state as any) || {};
  const completionMode = routerState.oauth === true;
  const oauthUserData = routerState.userData || {};
  const authUserInfo = useSelector((s: any) => s.auth?.userInfo);
  const completionUserId = oauthUserData._id || authUserInfo?.user?._id || "";

  const STEPS: readonly SignupStep[] = completionMode
    ? COMPLETION_STEPS
    : SIGNUP_STEPS;

  // --- Account / profile fields --------------------------------------------
  const [email, setEmail] = useState(
    completionMode ? oauthUserData.email || "" : ""
  );
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [name, setName] = useState(
    completionMode ? oauthUserData.name || "" : ""
  );
  const [selectedGender, setSelectedGender] = useState(
    completionMode ? oauthUserData.gender || "" : ""
  );
  const [nativeLanguage, setNativeLanguage] = useState(
    completionMode ? oauthUserData.nativeLanguage || "" : ""
  );
  const [languageToLearn, setLanguageToLearn] = useState(
    completionMode ? oauthUserData.languageToLearn || "" : ""
  );
  const [birthDate, setBirthDate] = useState(
    completionMode ? oauthUserData.birthDate || "" : ""
  );
  const [verificationCode, setVerificationCode] = useState("");
  const [selectedImages, setSelectedImages] = useState<File[]>([]);
  const [imagePreviews, setImagePreviews] = useState<string[]>([]);
  const [showPass, setShowPass] = useState(false);
  const [showPassTwo, setShowPassTwo] = useState(false);

  // --- New app-parity fields -----------------------------------------------
  const [username, setUsername] = useState("");
  const [usernameOk, setUsernameOk] = useState(true);
  const [languageLevel, setLanguageLevel] = useState("");
  const [learningLevel, setLearningLevel] = useState("");
  const [location, setLocation] = useState<LocationInput | null>(null);
  const [termsAccepted, setTermsAccepted] = useState(false);

  // --- Wizard state ---------------------------------------------------------
  const [stepIndex, setStepIndex] = useState(() => {
    if (completionMode) {
      const start = STEPS.indexOf(routerState.startStep as SignupStep);
      return start >= 0 ? start : 0;
    }
    return 0;
  });
  const [isCodeVerified, setIsCodeVerified] = useState(false);
  const currentStep = STEPS[stepIndex];

  const [registerUser, { isLoading: isRegistering }] = useRegisterUserMutation();
  const [uploadUserPhoto, { isLoading: isUploading }] = useUploadUserPhotoMutation();
  const [sendCodeEmail, { isLoading: isSendingCode }] = useRegisterCodeEmailMutation();
  const [verifyCode, { isLoading: isVerifying }] = useVerifyRegistrationCodeMutation();
  const [updateUserById] = useUpdateUserByIdMutation();
  const [updateUserInfo, { isLoading: isUpdatingDetails }] = useUpdateUserInfoMutation();
  const [acceptTerms, { isLoading: isAcceptingTerms }] = useAcceptTermsMutation();

  const fileInputRef = useRef<HTMLInputElement>(null);

  const sp = new URLSearchParams(search);
  const redirect = sp.get("redirect") || "/";

  const languageOptions = ISO6391.getAllCodes().map((code) => ({
    value: code,
    label: ISO6391.getName(code),
  }));

  // Clean up object URLs to avoid memory leaks
  useEffect(() => {
    return () => {
      imagePreviews.forEach((preview) => URL.revokeObjectURL(preview));
    };
  }, [imagePreviews]);

  // --- Email + verification -------------------------------------------------
  const handleSendVerificationCode = async (): Promise<boolean> => {
    try {
      const response = (await sendCodeEmail({
        email,
      }).unwrap()) as SendCodeEmailResponse;
      if (response.success) {
        toastSuccess("Verification code sent successfully!");
        return true;
      }
      return false;
    } catch (error: any) {
      // Backend error shape is { success: false, error: "<message>" }.
      const message =
        error?.data?.error ||
        error?.data?.message ||
        "Failed to send verification code";
      toastError(message);
      return false;
    }
  };

  const handleEmailNext = async () => {
    if (!email) {
      toastError("Please enter your email");
      return;
    }
    const sent = await handleSendVerificationCode();
    if (sent) setStepIndex((i) => i + 1); // → verify
  };

  const handleVerifyCode = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    try {
      const verificationResponse = (await verifyCode({
        email,
        code: verificationCode,
      }).unwrap()) as VerifyCodeResponse;
      if (verificationResponse.success) {
        setIsCodeVerified(true);
        toastSuccess("Email verified successfully!");
        setStepIndex((i) => i + 1); // → basics
      }
    } catch (error: any) {
      toastError(
        error?.data?.error || error?.data?.message || "Invalid verification code"
      );
    }
  };

  // --- Shared post-steps ----------------------------------------------------
  // Both the fresh-register and OAuth-completion flows end the same way: upload
  // the selected profile photo(s) and persist the CEFR level. `updatedetails`
  // does not whitelist `languageLevel`, so CEFR goes through PUT /auth/users/:id
  // (same contract the app uses). The learning level wins; fall back to native.
  const uploadPhotoAndPersistCefr = async (userId?: string) => {
    if (selectedImages.length > 0 && userId) {
      const uploadFormData = new FormData();
      selectedImages.forEach((file) => {
        uploadFormData.append("file", file);
      });
      await uploadUserPhoto({
        userId,
        imageFiles: uploadFormData,
      }).unwrap();
    }

    const cefrLevel = learningLevel || languageLevel;
    if (cefrLevel && userId) {
      try {
        await updateUserById({
          id: userId,
          body: { languageLevel: cefrLevel },
        }).unwrap();
      } catch {
        // Non-fatal: the account exists and is logged in; CEFR is optional.
      }
    }
  };

  // --- OAuth profile completion --------------------------------------------
  // The user already exists and is authenticated (token in the store). Patch
  // the collected profile via updatedetails, run the shared post-steps, then
  // record terms via accept-terms. No register call.
  const handleProfileCompletion = async () => {
    if (!location?.city || !location?.country) {
      toastError("Please provide your city and country");
      return;
    }
    if (!termsAccepted) {
      toastError("Please accept the Terms of Service and Privacy Policy");
      return;
    }
    if (selectedImages.length === 0) {
      toastError("Please add a profile photo");
      return;
    }

    const { city, country, coordinates } = location;
    const formattedAddress = [city, country].filter(Boolean).join(", ");
    const locationPayload: any = { formattedAddress, city, country };
    if (coordinates && coordinates.length === 2) {
      locationPayload.type = "Point";
      locationPayload.coordinates = coordinates;
    }

    const detailsPayload: any = {
      native_language: nativeLanguage,
      language_to_learn: languageToLearn,
      location: locationPayload,
      termsAccepted: true,
    };
    if (selectedGender) detailsPayload.gender = selectedGender;
    if (oauthUserData.bio) detailsPayload.bio = oauthUserData.bio;
    if (birthDate && birthDate.includes("-")) {
      const [birth_year, birth_month, birth_day] = birthDate.split("-");
      detailsPayload.birth_year = birth_year;
      detailsPayload.birth_month = birth_month;
      detailsPayload.birth_day = birth_day;
    }

    try {
      await updateUserInfo(detailsPayload).unwrap();

      await uploadPhotoAndPersistCefr(completionUserId);

      // Record acceptance of terms (protected endpoint). Non-fatal on failure —
      // the profile is already saved.
      try {
        await acceptTerms().unwrap();
      } catch {
        // ignore: terms recording is best-effort
      }

      toastSuccess("Profile completed!");
      navigate(redirect && redirect !== "/" ? redirect : "/communities");
    } catch (error: any) {
      toastError(
        error?.data?.error ||
          error?.data?.message ||
          "Error completing your profile"
      );
    }
  };

  // --- Final registration ---------------------------------------------------
  const handleFinalRegistration = async () => {
    if (!isCodeVerified) {
      toastError("Please verify your email first");
      return;
    }
    if (!location?.city || !location?.country) {
      toastError("Please provide your city and country");
      return;
    }
    if (!termsAccepted) {
      toastError("Please accept the Terms of Service and Privacy Policy");
      return;
    }
    if (selectedImages.length === 0) {
      toastError("Please add a profile photo");
      return;
    }

    const payload = buildRegisterPayload({
      name,
      username,
      password,
      email,
      gender: selectedGender,
      birthDate,
      native_language: nativeLanguage,
      language_to_learn: languageToLearn,
      location,
    });

    try {
      const response = await registerUser(payload).unwrap();
      const registrationResponse = response as any;
      const user_id = response as responseType;

      // Register returns { token, user }. Stash credentials immediately so the
      // photo upload + updatedetails below carry an Authorization header.
      if (registrationResponse?.token) {
        dispatch(
          setCredentials({
            user: registrationResponse.user || registrationResponse.data,
            token: registrationResponse.token,
            refreshToken: registrationResponse.refreshToken,
            message: "Registration successful",
          })
        );
      }

      const newUserId =
        user_id?.user?._id ||
        registrationResponse?.user?._id ||
        registrationResponse?.data?._id;

      // Photo upload + CEFR persistence are shared with the OAuth-completion
      // flow. register does NOT persist CEFR levels, so the helper handles it.
      await uploadPhotoAndPersistCefr(newUserId);

      toastSuccess("Registration successful!");
      // Already signed in — honor ?redirect=, defaulting to communities.
      navigate(redirect && redirect !== "/" ? redirect : "/communities");
    } catch (error: any) {
      toastError(
        error?.data?.error || error?.data?.message || "Error during registration"
      );
    }
  };

  // --- Image handling -------------------------------------------------------
  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || []);
    setSelectedImages((prev) => [...prev, ...files]);
    const newPreviews = files.map((file) => URL.createObjectURL(file));
    setImagePreviews((prev) => [...prev, ...newPreviews]);
  };

  const handleRemoveImage = (index: number) => {
    setSelectedImages((prev) => prev.filter((_, i) => i !== index));
    setImagePreviews((prev) => prev.filter((_, i) => i !== index));
  };

  const handleAddMoreImages = () => {
    fileInputRef.current?.click();
  };

  // --- Gating ---------------------------------------------------------------
  const basicsValid =
    usernameOk &&
    passwordStrength(password).valid &&
    password === confirmPassword &&
    isAdult(birthDate) &&
    !!name &&
    !!selectedGender;
  const photoValid = selectedImages.length > 0;
  const finishValid = !!location?.city && !!location?.country && termsAccepted;

  const isBusy =
    isRegistering ||
    isUploading ||
    isUpdatingDetails ||
    isAcceptingTerms;

  const canProceed = (): boolean => {
    switch (currentStep) {
      case "email":
        return !!email && !isSendingCode;
      case "basics":
        return basicsValid;
      case "languages":
        return !!nativeLanguage && !!languageToLearn && !!learningLevel;
      case "photo":
        return photoValid;
      case "finish":
        return finishValid && !isBusy;
      default:
        return true;
    }
  };

  const handleNext = () => {
    switch (currentStep) {
      case "email":
        handleEmailNext();
        break;
      case "finish":
        if (completionMode) {
          handleProfileCompletion();
        } else {
          handleFinalRegistration();
        }
        break;
      default:
        setStepIndex((i) => Math.min(i + 1, STEPS.length - 1));
    }
  };

  const handleBack = () => setStepIndex((i) => Math.max(i - 1, 0));

  // --- Styling helpers ------------------------------------------------------
  const inputClass =
    "w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-teal-400 focus:border-transparent transition-all";
  const labelClass = "block text-sm font-medium text-gray-700 mb-1";
  const progress = ((stepIndex + 1) / STEPS.length) * 100;

  return (
    <div className="min-h-screen bg-gray-50 py-10 px-4">
      <div className="max-w-xl mx-auto bg-white rounded-2xl shadow-lg p-6 sm:p-8">
        {/* Progress bar */}
        <div className="mb-6">
          <div className="h-2 bg-gray-200 rounded-full overflow-hidden">
            <div
              className="h-full bg-teal-500 transition-all"
              role="progressbar"
              style={{ width: `${progress}%` }}
              aria-valuenow={progress}
              aria-valuemin={0}
              aria-valuemax={100}
            />
          </div>
          <div className="flex justify-between mt-2">
            {STEPS.map((s, i) => (
              <span
                key={s}
                className={`text-[11px] sm:text-xs ${
                  i <= stepIndex ? "text-teal-600 font-semibold" : "text-gray-400"
                }`}
              >
                {STEP_LABELS[s]}
              </span>
            ))}
          </div>
        </div>

        {/* Step: Email */}
        {currentStep === "email" && (
          <div>
            <h2 className="text-2xl font-bold text-center mb-6 text-gray-900">
              {t("authentication.account.title")}
            </h2>
            <div className="mb-4">
              <label className={labelClass}>
                {t("authentication.account.email")}{" "}
                <span className="text-red-500">*</span>
              </label>
              <input
                type="email"
                placeholder={t("authentication.account.email")}
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className={inputClass}
                required
              />
              <p className="text-xs text-gray-500 mt-2">
                We'll send a verification code to this address.
              </p>
            </div>
            <div className="text-center mt-4 text-sm text-gray-600">
              {t("authentication.account.alreadyHaveAccount")}{" "}
              <Link
                to={redirect ? `/login?redirect=${redirect}` : `/login`}
                className="text-teal-600 hover:underline"
              >
                {t("authentication.account.login")}
              </Link>
            </div>
          </div>
        )}

        {/* Step: Verify */}
        {currentStep === "verify" && (
          <div>
            <h2 className="text-2xl font-bold text-center mb-4 text-gray-900">
              Email Verification
            </h2>
            <div className="text-center mb-6">
              <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-teal-50 mb-3">
                <UserPlus className="w-8 h-8 text-teal-500" />
              </div>
              <p className="text-gray-600">
                We've sent a verification code to
                <br />
                <strong className="text-gray-900">{email}</strong>
              </p>
            </div>
            <form onSubmit={handleVerifyCode}>
              <div className="mb-4">
                <label className={labelClass}>Verification Code</label>
                <input
                  type="text"
                  placeholder="Enter the 6-digit code"
                  value={verificationCode}
                  onChange={(e) => setVerificationCode(e.target.value)}
                  className={`${inputClass} text-center text-lg tracking-widest`}
                  required
                />
              </div>
              <button
                type="submit"
                disabled={isVerifying || !verificationCode}
                className="w-full py-3 rounded-xl font-medium bg-teal-500 text-white hover:bg-teal-600 transition-colors disabled:opacity-60 disabled:cursor-not-allowed flex items-center justify-center gap-2"
              >
                {isVerifying ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" /> Verifying…
                  </>
                ) : (
                  "Verify Email"
                )}
              </button>
              <div className="text-center mt-3">
                <button
                  type="button"
                  onClick={handleSendVerificationCode}
                  disabled={isSendingCode}
                  className="text-sm text-teal-600 hover:underline disabled:opacity-60"
                >
                  {isSendingCode ? "Sending…" : "Resend verification code"}
                </button>
              </div>
            </form>
          </div>
        )}

        {/* Step: Basics */}
        {currentStep === "basics" && (
          <div>
            <h2 className="text-2xl font-bold text-center mb-6 text-gray-900">
              {t("authentication.account.title")}
            </h2>
            <div className="space-y-4">
              <div>
                <label className={labelClass}>
                  {t("authentication.account.name")}{" "}
                  <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  placeholder={t("authentication.account.name")}
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className={inputClass}
                  required
                />
              </div>

              <div>
                <label className={labelClass}>Username</label>
                <UsernameAvailabilityField
                  value={username}
                  onChange={setUsername}
                  onAvailabilityChange={setUsernameOk}
                />
              </div>

              <div>
                <label className={labelClass}>
                  {t("authentication.account.password")}{" "}
                  <span className="text-red-500">*</span>
                </label>
                <div className="relative">
                  <input
                    type={showPass ? "text" : "password"}
                    placeholder={t("authentication.account.password")}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className={`${inputClass} pr-12`}
                    required
                  />
                  <button
                    type="button"
                    onClick={() => setShowPass((p) => !p)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                    aria-label="toggle password visibility"
                  >
                    {showPass ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                  </button>
                </div>
                <div className="mt-2">
                  <PasswordStrengthMeter password={password} />
                </div>
              </div>

              <div>
                <label className={labelClass}>
                  {t("authentication.account.confirmPassword")}{" "}
                  <span className="text-red-500">*</span>
                </label>
                <div className="relative">
                  <input
                    type={showPassTwo ? "text" : "password"}
                    placeholder={t("authentication.account.confirmPassword")}
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    className={`${inputClass} pr-12`}
                    required
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassTwo((p) => !p)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                    aria-label="toggle confirm password visibility"
                  >
                    {showPassTwo ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                  </button>
                </div>
                {confirmPassword && password !== confirmPassword && (
                  <small className="block text-xs text-red-500 mt-1">
                    Passwords do not match
                  </small>
                )}
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className={labelClass}>
                    {t("authentication.profile.gender")}{" "}
                    <span className="text-red-500">*</span>
                  </label>
                  <select
                    value={selectedGender}
                    onChange={(e) => setSelectedGender(e.target.value)}
                    className={inputClass}
                    required
                  >
                    <option value="">Select Gender</option>
                    <option value="male">Male</option>
                    <option value="female">Female</option>
                    <option value="other">Other</option>
                  </select>
                </div>
                <div>
                  <label className={labelClass}>
                    Birth Date <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="date"
                    value={birthDate}
                    onChange={(e) => setBirthDate(e.target.value)}
                    className={inputClass}
                    required
                  />
                  {birthDate && !isAdult(birthDate) && (
                    <small className="block text-xs text-red-500 mt-1">
                      You must be at least 18 years old
                    </small>
                  )}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Step: Languages */}
        {currentStep === "languages" && (
          <div>
            <h2 className="text-2xl font-bold text-center mb-6 text-gray-900">
              Languages
            </h2>
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className={labelClass}>Native Language</label>
                  <select
                    value={nativeLanguage}
                    onChange={(e) => setNativeLanguage(e.target.value)}
                    className={inputClass}
                  >
                    <option value="">Select Language</option>
                    {languageOptions.map((lang) => (
                      <option key={lang.value} value={lang.label}>
                        {lang.label}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className={labelClass}>Native Level</label>
                  <select
                    value={languageLevel}
                    onChange={(e) => setLanguageLevel(e.target.value)}
                    className={inputClass}
                  >
                    <option value="">Level</option>
                    {CEFR_LEVELS.map((lvl) => (
                      <option key={lvl} value={lvl}>
                        {lvl}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className={labelClass}>Language to Learn</label>
                  <select
                    value={languageToLearn}
                    onChange={(e) => setLanguageToLearn(e.target.value)}
                    className={inputClass}
                  >
                    <option value="">Select Language</option>
                    {languageOptions.map((lang) => (
                      <option key={lang.value} value={lang.label}>
                        {lang.label}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className={labelClass}>Learning Level</label>
                  <select
                    value={learningLevel}
                    onChange={(e) => setLearningLevel(e.target.value)}
                    className={inputClass}
                  >
                    <option value="">Level</option>
                    {CEFR_LEVELS.map((lvl) => (
                      <option key={lvl} value={lvl}>
                        {lvl}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Step: Photo */}
        {currentStep === "photo" && (
          <div>
            <h2 className="text-2xl font-bold text-center mb-6 text-gray-900">
              Profile Photo <span className="text-red-500">*</span>
            </h2>
            {imagePreviews.length > 0 ? (
              <div className="grid grid-cols-3 gap-3 mb-4">
                {imagePreviews.map((preview, index) => (
                  <div key={index} className="relative">
                    <div className="h-28 rounded-xl overflow-hidden bg-gray-100">
                      <img
                        src={preview}
                        alt={`preview ${index + 1}`}
                        className="w-full h-full object-cover"
                      />
                    </div>
                    <button
                      type="button"
                      onClick={() => handleRemoveImage(index)}
                      className="absolute -top-2 -right-2 w-7 h-7 rounded-full bg-red-500 text-white flex items-center justify-center hover:bg-red-600"
                      aria-label="remove image"
                    >
                      <X className="w-4 h-4" />
                    </button>
                  </div>
                ))}
                <button
                  type="button"
                  onClick={handleAddMoreImages}
                  className="h-28 rounded-xl border-2 border-dashed border-gray-300 flex items-center justify-center text-gray-400 hover:border-teal-400 hover:text-teal-500"
                >
                  <Plus className="w-6 h-6" />
                </button>
              </div>
            ) : (
              <div className="border-2 border-dashed border-gray-300 rounded-xl p-8 text-center mb-4">
                <Plus className="w-8 h-8 mx-auto mb-2 text-gray-400" />
                <p className="mb-3 text-gray-600">Click to upload your profile photo</p>
                <label
                  htmlFor="formFileUpload"
                  className="inline-block px-4 py-2 rounded-lg bg-teal-50 text-teal-600 font-medium cursor-pointer hover:bg-teal-100"
                >
                  Select Images
                </label>
                <input
                  id="formFileUpload"
                  type="file"
                  multiple
                  accept="image/*"
                  onChange={handleImageUpload}
                  className="hidden"
                />
              </div>
            )}
            <input
              type="file"
              multiple
              accept="image/*"
              onChange={handleImageUpload}
              ref={fileInputRef}
              className="hidden"
            />
          </div>
        )}

        {/* Step: Finish */}
        {currentStep === "finish" && (
          <div>
            <h2 className="text-2xl font-bold text-center mb-6 text-gray-900">
              Almost there
            </h2>
            <div className="space-y-5">
              <div>
                <label className={labelClass}>
                  Location <span className="text-red-500">*</span>
                </label>
                <LocationField value={location} onChange={setLocation} />
              </div>
              <label className="flex items-start gap-2 text-sm text-gray-700">
                <input
                  type="checkbox"
                  checked={termsAccepted}
                  onChange={(e) => setTermsAccepted(e.target.checked)}
                  className="mt-1"
                />
                <span>I agree to the Terms of Service and Privacy Policy</span>
              </label>
            </div>
          </div>
        )}

        {/* Footer navigation (verify has its own submit button) */}
        {currentStep !== "verify" && (
          <div className="flex gap-3 mt-8">
            {stepIndex > 0 && (
              <button
                type="button"
                onClick={handleBack}
                disabled={isBusy}
                className="flex-1 py-3 rounded-xl font-medium border border-gray-300 text-gray-700 hover:bg-gray-50 transition-colors flex items-center justify-center gap-2 disabled:opacity-60"
              >
                <ArrowLeft className="w-4 h-4" /> Back
              </button>
            )}
            <button
              type="button"
              onClick={handleNext}
              disabled={!canProceed()}
              className="flex-1 py-3 rounded-xl font-medium bg-teal-500 text-white hover:bg-teal-600 transition-colors disabled:opacity-60 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              {currentStep === "finish" ? (
                isBusy ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" /> Processing…
                  </>
                ) : (
                  <>{completionMode ? "Complete Profile" : "Complete Registration"}</>
                )
              ) : currentStep === "email" && isSendingCode ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" /> Sending…
                </>
              ) : (
                <>
                  {t("authentication.account.continue")}{" "}
                  <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>
          </div>
        )}

        {/* Verify step's back button */}
        {currentStep === "verify" && (
          <div className="mt-4">
            <button
              type="button"
              onClick={handleBack}
              className="w-full py-3 rounded-xl font-medium border border-gray-300 text-gray-700 hover:bg-gray-50 transition-colors flex items-center justify-center gap-2"
            >
              <ArrowLeft className="w-4 h-4" /> Back
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default Register;
