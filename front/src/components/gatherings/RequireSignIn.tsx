import React from "react";
import { useSelector } from "react-redux";
import { Navigate, useLocation } from "react-router-dom";

/**
 * Gatherings and clubs are private (`protect` on every route). A signed-out
 * visitor goes to login and comes back -- the AnnouncementPage pattern.
 */
const RequireSignIn: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const signedIn = useSelector((s: any) => !!(s.auth && s.auth.userInfo && s.auth.userInfo.token));
  const location = useLocation();
  if (!signedIn) {
    return <Navigate to={`/login?redirect=${encodeURIComponent(location.pathname + location.search)}`} replace />;
  }
  return <>{children}</>;
};

export default RequireSignIn;
