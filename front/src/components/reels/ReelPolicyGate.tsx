import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { useDispatch, useSelector } from "react-redux";
import { setCredentials } from "../../store/slices/authSlice";
import { useUpdateUserInfoMutation } from "../../store/slices/usersSlice";
import "./Reels.scss";

/** Same key name the app keeps in SharedPreferences (reel_policy_dialog.dart). */
export const REEL_POLICY_STORAGE_KEY = "reels_policy_accepted";

export function hasAcceptedReelPolicy(user: any): boolean {
  return !!user && user.reelsPolicyAccepted === true;
}

function readLocal(): boolean {
  try {
    return localStorage.getItem(REEL_POLICY_STORAGE_KEY) === "1";
  } catch (e) {
    return false;
  }
}

function writeLocal(): void {
  try {
    localStorage.setItem(REEL_POLICY_STORAGE_KEY, "1");
  } catch (e) {
    // Private mode: the account field below still carries it.
  }
}

/**
 * One-time objectionable-content agreement before any reel is shown or
 * posted (Apple Guideline 1.2 -- public user-generated video). The account
 * field is shared with the app, so accepting on either side counts on both.
 */
const ReelPolicyGate: React.FC<{ children: React.ReactNode; onDeclined: () => void }> = ({
  children,
  onDeclined,
}) => {
  const { t } = useTranslation();
  const dispatch = useDispatch();
  const userInfo = useSelector((state: any) => state.auth.userInfo);
  const user = userInfo && userInfo.user;
  const [acceptedNow, setAcceptedNow] = useState(false);
  const [updateUserInfo] = useUpdateUserInfoMutation();

  if (acceptedNow || hasAcceptedReelPolicy(user) || readLocal()) return <>{children}</>;

  const accept = () => {
    writeLocal();
    setAcceptedNow(true);
    if (userInfo && user) {
      dispatch(setCredentials({ ...userInfo, user: { ...user, reelsPolicyAccepted: true } }));
    }
    // Best effort, as in the app: the local flag already gates this browser.
    Promise.resolve()
      .then(() => updateUserInfo({ reelsPolicyAccepted: true }).unwrap())
      .catch(() => {});
  };

  return (
    <div className="reel-policy-backdrop" role="presentation">
      <div
        className="reel-policy-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="reel-policy-title"
        data-testid="reel-policy-dialog"
      >
        <h2 id="reel-policy-title" className="reel-policy-title">
          {t("reels.policy.title") || "Reels content guidelines"}
        </h2>
        <p className="reel-policy-body">
          {t("reels.policy.body") ||
            "Reels are short language-learning videos — prompt answers, speaking practice, native-speaker explainers, and culture clips.\n\nBananaTalk has zero tolerance for objectionable content: no nudity, hate speech, harassment, violence, or illegal content. Reported videos are automatically hidden pending review after 2 reports, and violations can result in content removal or account bans.\n\nYou can report or block from any reel at any time."}
        </p>
        <div className="reel-policy-actions">
          <button type="button" className="reel-btn reel-btn-ghost" data-testid="reel-policy-decline" onClick={onDeclined}>
            {t("reels.policy.decline") || "Decline"}
          </button>
          <button type="button" className="reel-btn reel-btn-primary" data-testid="reel-policy-accept" onClick={accept}>
            {t("reels.policy.accept") || "I agree"}
          </button>
        </div>
      </div>
    </div>
  );
};

export default ReelPolicyGate;
