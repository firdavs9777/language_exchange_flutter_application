import React, { useRef, useState } from "react";
import { useDispatch } from "react-redux";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Bounce, toast } from "react-toastify";
import { FaApple } from "react-icons/fa";
import { useWebFlag } from "../../../utils/webFlags";
import { setCredentials } from "../../../store/slices/authSlice";
import { useAppleWebLoginMutation } from "../../../store/slices/appleAuthSlice";
import { appleServicesId, loadAppleJs, makeNonce, signInWithApple } from "./appleJs";
import { appleErrorKind, appleErrorText } from "./appleErrors";
import { isProfileComplete, oauthCompletionState } from "../socialSignIn";

const TOAST = { position: "top-right" as const, theme: "dark" as const, transition: Bounce };

/**
 * Sign in with Apple (Apple JS popup -> POST /auth/apple/web). Hidden unless
 * webAppleSigninEnabled is on AND this build has a Services ID; hidden again
 * for the rest of the page view if the backend says the feature is off.
 * Apple's style rules: black button, white logo, "Continue with Apple".
 */
const AppleSignInButton: React.FC<{ redirect: string }> = ({ redirect }) => {
  const { t } = useTranslation();
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const enabled = useWebFlag("webAppleSigninEnabled");
  const [appleWebLogin] = useAppleWebLoginMutation();
  const [busy, setBusy] = useState(false);
  const [serverDisabled, setServerDisabled] = useState(false);
  const busyRef = useRef(false);

  if (!enabled || serverDisabled || !appleServicesId()) return null;

  // Warm the script so the popup opens inside the click's user activation
  // (Safari drops popups opened after a slow await).
  const preload = () => {
    loadAppleJs().catch(() => {
      /* the click retries and reports */
    });
  };

  const onClick = async () => {
    if (busyRef.current) return;
    busyRef.current = true;
    setBusy(true);
    try {
      const nonce = makeNonce();
      const state = makeNonce();
      const apple = await signInWithApple({ nonce, state });
      if (!apple) return; // closed the window: nothing to say

      const args: any = { identityToken: apple.identityToken, nonce };
      if (apple.user) args.user = apple.user;
      const res: any = await appleWebLogin(args).unwrap();
      const user = res.user || res.data;
      const credentials = setCredentials({
        user,
        token: res.token,
        refreshToken: res.refreshToken,
        message: "Signed in with Apple",
      });

      if (!isProfileComplete(user)) {
        toast.info(t("authentication.register.completeProfile") || "Please complete your profile to continue", {
          ...TOAST,
          autoClose: 3000,
        });
        // Navigate BEFORE storing the session: Login.tsx redirects to
        // ?redirect= the moment userInfo appears, which would skip the wizard.
        navigate("/register", { state: oauthCompletionState(user, "apple") });
        dispatch(credentials);
        return;
      }

      dispatch(credentials);
      toast.success(t("auth.apple.signedIn") || "Signed in with Apple", { ...TOAST, autoClose: 2000 });
      navigate(redirect, { replace: true });
    } catch (err) {
      const kind = appleErrorKind(err);
      if (kind === "disabled") setServerDisabled(true);
      toast.error(appleErrorText(kind, t), { ...TOAST, autoClose: 4000 });
    } finally {
      busyRef.current = false;
      setBusy(false);
    }
  };

  return (
    <button
      type="button"
      data-testid="apple-signin-button"
      onClick={onClick}
      onPointerEnter={preload}
      onFocus={preload}
      disabled={busy}
      aria-busy={busy}
      className="apple-btn flex w-full items-center justify-center gap-3 rounded-xl bg-black px-6 py-3.5 text-base font-semibold text-white transition hover:bg-gray-900 disabled:cursor-wait disabled:opacity-60"
      style={{ marginBlockStart: "0.75rem" }}
    >
      <FaApple size={20} aria-hidden />
      <span>
        {busy
          ? t("auth.apple.signingIn") || "Signing in with Apple…"
          : t("auth.apple.continue") || "Continue with Apple"}
      </span>
    </button>
  );
};

export default AppleSignInButton;
