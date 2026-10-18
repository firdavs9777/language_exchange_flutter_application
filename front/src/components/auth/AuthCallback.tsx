import { useEffect, useRef, useState } from "react";
import { useDispatch } from "react-redux";
import { useNavigate, useSearchParams } from "react-router-dom";
import { setCredentials } from "../../store/slices/authSlice";
import { Bounce, toast } from "react-toastify";
import { useTranslation } from "react-i18next";
import Loader from "../Loader";
import { BASE_URL, GOOGLE_EXCHANGE_URL, USER_PROFILE_URL } from "../../constants";
import { isProfileComplete, oauthCompletionState } from "./socialSignIn";

interface SignIn { user: any; token: string; refreshToken?: string }
type Translate = (key: string) => string;

const TOAST = { position: "top-right" as const, autoClose: 4000, theme: "dark" as const, transition: Bounce };

/** Drop ?code= / ?token= from the address bar and history before anything awaits. */
function scrubCallbackUrl(): void {
  try {
    window.history.replaceState(window.history.state, "", window.location.pathname);
  } catch (e) {
    // no history API (prerender) -- nothing to scrub
  }
}

async function exchangeCode(code: string): Promise<SignIn> {
  const res = await fetch(`${BASE_URL}${GOOGLE_EXCHANGE_URL}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ code }),
  });
  let body: any = null;
  try {
    body = await res.json();
  } catch (e) {
    body = null;
  }
  if (!res.ok || !body || !body.token) {
    const err: any = new Error((body && (body.error || body.message)) || "Code exchange failed");
    err.status = res.status;
    err.code = body && body.code;
    throw err;
  }
  return { user: body.user || body.data, token: body.token, refreshToken: body.refreshToken };
}

/** The pre-code flow: the JWT came in the URL. Kept until the backend drops `token=`. */
async function legacyTokenSignIn(token: string): Promise<SignIn> {
  const res = await fetch(`${BASE_URL}${USER_PROFILE_URL}`, {
    method: "GET",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
  });
  const body: any = res.ok ? await res.json() : null;
  if (!body || !body.success || !body.data) {
    const err: any = new Error("Failed to fetch user profile");
    err.status = res.status;
    throw err;
  }
  return { user: body.data, token };
}

function refusalMessage(t: Translate, reason: string | null, raw: string | null): string {
  if (reason === "EMAIL_EXISTS") {
    return t("authentication.callback.emailExists") || "An account with this email already exists. Sign in with your email and password.";
  }
  if (reason === "BANNED") return t("authentication.callback.banned") || "This account has been suspended.";
  if (reason === "GOOGLE_FAILED" || !raw) return t("authentication.callback.generic") || "Sign in failed. Please try again.";
  return raw;
}

function failureMessage(t: Translate, err: any): string {
  if (err && (err.status === 403 || err.code === "ACCOUNT_BANNED")) {
    return t("authentication.callback.banned") || "This account has been suspended.";
  }
  if (err && err.code === "OAUTH_CODE_INVALID") {
    return t("authentication.callback.codeExpired") || "This sign-in link has expired. Please sign in again.";
  }
  return t("authentication.callback.generic") || "Sign in failed. Please try again.";
}

const AuthCallback = () => {
  const { t } = useTranslation();
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  // The code works once. React 18 StrictMode runs this effect twice in
  // development; the ref survives that remount, so only one exchange is sent.
  const started = useRef(false);

  useEffect(() => {
    if (started.current) return;
    started.current = true;

    const code = searchParams.get("code");
    const token = searchParams.get("token");
    const errorParam = searchParams.get("error");
    const reason = searchParams.get("reason");
    scrubCallbackUrl();

    const fail = (message: string) => {
      setError(message);
      setIsLoading(false);
      toast.error(message, TOAST);
      setTimeout(() => navigate("/login"), 2000);
    };

    const finish = ({ user: userInfo, token: accessToken, refreshToken }: SignIn) => {
      // Same shape as the email login (Login.tsx), so apiSlice can refresh it.
      dispatch(
        setCredentials({
          user: userInfo,
          token: accessToken,
          refreshToken,
          message: "Successfully authenticated with Google",
        })
      );
      setIsLoading(false);

      if (!isProfileComplete(userInfo)) {
        toast.info(t("authentication.register.completeProfile") || "Please complete your profile to continue", {
          ...TOAST,
          autoClose: 3000,
        });
        // OAuth users already have email + name — the SAME signup wizard in
        // completion mode, starting at the languages step (socialSignIn.ts).
        navigate("/register", { state: oauthCompletionState(userInfo, "google") });
        return;
      }

      toast.success(t("authentication.login.successMessage") || "Login successful!", {
        ...TOAST,
        autoClose: 2000,
        hideProgressBar: false,
      });
      const redirect = sessionStorage.getItem("oauth_redirect") || "/";
      sessionStorage.removeItem("oauth_redirect");
      navigate(redirect, { replace: true });
    };

    if (errorParam || reason) {
      fail(refusalMessage(t, reason, errorParam));
      return;
    }
    if (!code && !token) {
      fail(t("authentication.callback.noCode") || "Sign in didn't finish. Please try again.");
      return;
    }

    (async () => {
      let signIn: SignIn;
      try {
        if (code) {
          try {
            signIn = await exchangeCode(code);
          } catch (exchangeError) {
            // Rollout window: the redirect still carries the legacy token.
            if (!token) throw exchangeError;
            signIn = await legacyTokenSignIn(token);
          }
        } else {
          signIn = await legacyTokenSignIn(token as string);
        }
      } catch (err: any) {
        console.error("OAuth callback error:", err);
        fail(failureMessage(t, err));
        return;
      }
      finish(signIn);
    })();
  }, [searchParams, dispatch, navigate, t]);

  if (isLoading) {
    return (
      <div className="d-flex flex-column justify-content-center align-items-center" style={{ minHeight: "50vh" }}>
        <Loader />
        <h5 className="mt-3">{t("authentication.callback.completing") || "Completing sign in..."}</h5>
        <p className="text-muted">{t("authentication.callback.wait") || "Please wait while we sign you in."}</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="d-flex flex-column justify-content-center align-items-center" style={{ minHeight: "50vh" }}>
        <div className="text-center">
          <div className="text-danger mb-3" style={{ fontSize: "3rem" }} aria-hidden="true">✕</div>
          <h5 className="text-danger">{t("authentication.callback.failedTitle") || "Sign in failed"}</h5>
          <p className="text-muted">{error}</p>
          <p className="text-muted">{t("authentication.callback.redirecting") || "Taking you back to sign in..."}</p>
        </div>
      </div>
    );
  }

  return null;
};

export default AuthCallback;
