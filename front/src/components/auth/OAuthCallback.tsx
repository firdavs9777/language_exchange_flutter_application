import React, { useEffect, useState } from "react";
import { useSearchParams, useNavigate } from "react-router-dom";
import { useDispatch } from "react-redux";
import { setCredentials } from "../../store/slices/authSlice";
import { Bounce, toast } from "react-toastify";
import { useTranslation } from "react-i18next";
import Loader from "../Loader";
import { BASE_URL, USER_PROFILE_URL } from "../../constants";
import "./OAuthCallback.scss";

// Helper function to check if user profile is complete
const isProfileComplete = (userInfo: any): boolean => {
  // First check: If isRegistrationComplete is true, user is fully registered - log them in directly
  if (userInfo?.isRegistrationComplete === true) {
    return true;
  }

  // Second check: If isRegistrationComplete is false or missing, check profileCompleted flag
  const profileCompleted = userInfo?.profileCompleted;
  if (profileCompleted === false || profileCompleted === undefined) {
    return false;
  }

  // Third check: Verify no default/placeholder values exist
  const nativeLanguage = userInfo?.native_language;
  const languageToLearn = userInfo?.language_to_learn;
  const gender = userInfo?.gender;

  const hasDefaultValues =
    (!nativeLanguage ||
      nativeLanguage === "" ||
      nativeLanguage === "English") &&
    (!languageToLearn ||
      languageToLearn === "" ||
      languageToLearn === "Korean") &&
    (!gender || gender === "other" || gender === "");

  return !hasDefaultValues;
};

const OAuthCallback: React.FC = () => {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const { t } = useTranslation();
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const handleOAuthCallback = async () => {
      try {
        // Extract token from URL
        const token = searchParams.get("token");

        if (!token) {
          setError("No token provided");
          toast.error("Authentication failed: No token received", {
            position: "top-right",
            autoClose: 3000,
            hideProgressBar: false,
            theme: "dark",
            transition: Bounce,
          });
          setTimeout(() => navigate("/login"), 2000);
          return;
        }

        // Fetch user profile using the token
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

        const userData = await response.json();

        // Format response to match setCredentials expected structure
        // Handle different possible response structures
        let userInfo = userData;
        if (userData.data) {
          userInfo = userData.data;
        } else if (userData.user) {
          userInfo = userData.user;
        }

        const credentials = {
          token: token,
          data: userInfo,
          message: "Successfully authenticated with Google",
        };

        // Store credentials in Redux
        dispatch(setCredentials(credentials));

        // Check if profile is complete
        const profileComplete = isProfileComplete(userInfo);

        if (!profileComplete) {
          // Profile incomplete - redirect to Register step 2 with user data
          console.log("Profile incomplete - redirecting to Register step 2");
          toast.info("Please complete your profile to continue", {
            position: "top-right",
            autoClose: 3000,
            hideProgressBar: false,
            theme: "dark",
            transition: Bounce,
          });

          // Normalize gender to lowercase to match backend validation
          const normalizedGender = userInfo?.gender 
            ? userInfo.gender.toLowerCase() 
            : "other";
          
          // Pass user data via location state
          navigate("/register", {
            state: {
              step: 2,
              oauth: true,
              userData: {
                name: userInfo?.name || "",
                email: userInfo?.email || "",
                bio: userInfo?.bio || "Hello! I joined using Google. 👋",
                gender: normalizedGender,
                nativeLanguage: userInfo?.native_language || "",
                languageToLearn: userInfo?.language_to_learn || "",
                birthDate: userInfo?.birth_year && userInfo?.birth_month && userInfo?.birth_day
                  ? `${userInfo.birth_year}-${String(userInfo.birth_month).padStart(2, "0")}-${String(userInfo.birth_day).padStart(2, "0")}`
                  : "2000-01-01",
              },
            },
          });
        } else {
          // Profile complete - proceed with normal redirect
          toast.success(t("authentication.login.successMessage"), {
            position: "top-right",
            autoClose: 2000,
            hideProgressBar: false,
            theme: "dark",
            transition: Bounce,
          });

          // Get redirect URL from sessionStorage
          const redirectUrl = sessionStorage.getItem("oauth_redirect") || "/";
          sessionStorage.removeItem("oauth_redirect");

          // Redirect to the stored URL or home
          navigate(redirectUrl);
        }
      } catch (err: any) {
        console.error("OAuth callback error:", err);
        setError(err.message || "Authentication failed");
        toast.error(
          err.message || t("authentication.login.invalidCredentialsError"),
          {
            position: "top-right",
            autoClose: 4000,
            hideProgressBar: false,
            theme: "dark",
            transition: Bounce,
          }
        );
        setTimeout(() => navigate("/login"), 2000);
      } finally {
        setIsLoading(false);
      }
    };

    handleOAuthCallback();
  }, [searchParams, navigate, dispatch, t]);

  if (isLoading) {
    return (
      <div className="oauth-callback-page">
        <div className="callback-container">
          <Loader />
          <h2 className="callback-title">Completing Sign In...</h2>
          <p className="callback-message">
            Please wait while we authenticate your account.
          </p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="oauth-callback-page">
        <div className="callback-container error">
          <div className="error-icon">✕</div>
          <h2 className="callback-title">Authentication Failed</h2>
          <p className="callback-message">{error}</p>
          <p className="callback-redirect">Redirecting to login...</p>
        </div>
      </div>
    );
  }

  return null;
};

export default OAuthCallback;

