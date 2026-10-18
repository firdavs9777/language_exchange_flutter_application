import { useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import { PublicAnnouncement } from "../../store/slices/appConfigSlice";
import { webTargetFor } from "./announcementLinks";

const loginFor = (path: string) => `/login?redirect=${encodeURIComponent(path)}`;

/** Button and "Read more" behaviour shared by the modal, banner and page. Logged out → login, then back. */
export function useAnnouncementActions(a: PublicAnnouncement, preview = false) {
  const navigate = useNavigate();
  const loggedIn = useSelector((s: any) => !!(s.auth && s.auth.userInfo));
  const target = a.buttonLabel ? webTargetFor(a.buttonUrl) : null;
  const pagePath = `/announcement/${encodeURIComponent(a.id)}`;

  const go = (path: string) => { if (!preview) navigate(loggedIn ? path : loginFor(path)); };

  const primary = !target ? null : () => {
    if (preview) return;
    if (target.kind === "external") {
      if (loggedIn) window.open(target.href, "_blank", "noopener,noreferrer");
      else navigate(loginFor(pagePath));
      return;
    }
    go(target.path);
  };

  return { primary, readMore: () => go(pagePath) };
}
