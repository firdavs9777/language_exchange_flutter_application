import { useEffect, useState } from "react";
import { useDispatch } from "react-redux";
import { useNavigate, useSearchParams } from "react-router-dom";
import { setCredentials } from "../../store/slices/authSlice";
import { Bounce, toast } from "react-toastify";
import { useTranslation } from "react-i18next";
import Loader from "../Loader";
import { BASE_URL, USER_PROFILE_URL } from "../../constants";

// Helper function to check if user profile is complete
const isProfileComplete = (userInfo: any): boolean => {
  // If isRegistrationComplete is true, user is fully registered
  if (userInfo?.isRegistrationComplete === true) {
    return true;
  }

  // Check profileCompleted flag
  if (userInfo?.profileCompleted === false || userInfo?.profileCompleted === undefined) {
    return false;
  }

  // Verify required fields exist
  const nativeLanguage = userInfo?.native_language;
  const languageToLearn = userInfo?.language_to_learn;
  const gender = userInfo?.gender;

  const hasDefaultValues =
    (!nativeLanguage || nativeLanguage === "" || nativeLanguage === "English") &&
    (!languageToLearn || languageToLearn === "" || languageToLearn === "Korean") &&
    (!gender || gender === "other" || gender === "");

  return !hasDefaultValues;
};

const AuthCallback = () => {
  const { t } = useTranslation();
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const handleCallback = async () => {
      try {
        const token = searchParams.get("token");
        const errorParam = searchParams.get("error");

        if (errorParam) {
          setError(errorParam);
          toast.error(errorParam, {
            position: "top-right",
            autoClose: 4000,
            theme: "dark",
            transition: Bounce,
          });
          setTimeout(() => navigate("/login"), 2000);
          return;
        }

        if (!token) {
          setError("No authentication token received");
          toast.error("Authentication failed. Please try again.", {
            position: "top-right",
            autoClose: 4000,
            theme: "dark",
            transition: Bounce,
          });
          setTimeout(() => navigate("/login"), 2000);
          return;
        }

        // Fetch user profile with the token
        const response = await fetch(`${BASE_URL}${USER_PROFILE_URL}`, {
          method: "GET",
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
          },
        });

        if (!response.ok) {
          throw new Error("Failed to fetch user profile");
        }

        const responseData = await response.json();

        if (!responseData.success || !responseData.data) {
          throw new Error("Invalid response from server");
        }

        const userInfo = responseData.data;

        // Set credentials with correct structure: { user: {...}, token: "..." }
        // This matches what components expect (e.g., state.auth.userInfo?.user._id)
        dispatch(
          setCredentials({
            user: userInfo,
            token,
            message: "Successfully authenticated with Google",
          })
        );

        // Check if profile is complete
        const profileComplete = isProfileComplete(userInfo);

        if (!profileComplete) {
          // Profile incomplete - redirect to Register step 2
          toast.info(t("authentication.register.completeProfile") || "Please complete your profile to continue", {
            position: "top-right",
            autoClose: 3000,
            theme: "dark",
            transition: Bounce,
          });

          const normalizedGender = userInfo?.gender?.toLowerCase() || "other";

          navigate("/register", {
            state: {
              step: 2,
              oauth: true,
              userData: {
                name: userInfo?.name || "",
                email: userInfo?.email || "",
                bio: userInfo?.bio || "Hello! I joined using Google.",
                gender: normalizedGender,
                nativeLanguage: userInfo?.native_language || "",
                languageToLearn: userInfo?.language_to_learn || "",
                birthDate:
                  userInfo?.birth_year && userInfo?.birth_month && userInfo?.birth_day
                    ? `${userInfo.birth_year}-${String(userInfo.birth_month).padStart(2, "0")}-${String(userInfo.birth_day).padStart(2, "0")}`
                    : "2000-01-01",
              },
            },
          });
        } else {
          // Profile complete - proceed with normal redirect
          toast.success(t("authentication.login.successMessage") || "Login successful!", {
            position: "top-right",
            autoClose: 2000,
            hideProgressBar: false,
            theme: "dark",
            transition: Bounce,
          });

          const redirect = sessionStorage.getItem("oauth_redirect") || "/";
          sessionStorage.removeItem("oauth_redirect");
          navigate(redirect);
        }
      } catch (err: any) {
        console.error("OAuth callback error:", err);
        setError(err.message || "Authentication failed");
        toast.error(err.message || "Authentication failed. Please try again.", {
          position: "top-right",
          autoClose: 4000,
          theme: "dark",
          transition: Bounce,
        });
        setTimeout(() => navigate("/login"), 2000);
      } finally {
        setIsLoading(false);
      }
    };

    handleCallback();
  }, [searchParams, dispatch, navigate, t]);

  if (isLoading) {
    return (
      <div className="d-flex flex-column justify-content-center align-items-center" style={{ minHeight: "50vh" }}>
        <Loader />
        <h5 className="mt-3">Completing Sign In...</h5>
        <p className="text-muted">Please wait while we authenticate your account.</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="d-flex flex-column justify-content-center align-items-center" style={{ minHeight: "50vh" }}>
        <div className="text-center">
          <div className="text-danger mb-3" style={{ fontSize: "3rem" }}>✕</div>
          <h5 className="text-danger">Authentication Failed</h5>
          <p className="text-muted">{error}</p>
          <p className="text-muted">Redirecting to login...</p>
        </div>
      </div>
    );
  }

  return null;
};

export default AuthCallback;
