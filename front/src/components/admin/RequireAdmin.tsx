import React from "react";
import { useSelector } from "react-redux";
import { Navigate } from "react-router-dom";
import { selectIsAdmin } from "../../store/slices/authSlice";

/**
 * Client-side gate for `/admin/*`. It hides the console from everyone whose
 * stored `userInfo` doesn't say `role: "admin"` — a UX guard, not a security
 * boundary: every admin API route is `protect` + `authorize('admin')`
 * server-side, so forging the local role yields a console of 403s.
 *
 * Redirects rather than rendering a "forbidden" page: a non-admin who lands on
 * `/admin` (stale bookmark, shared link) has no business knowing the console
 * exists. `replace` keeps it out of the back stack.
 */
const RequireAdmin: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const isAdmin = useSelector(selectIsAdmin);
  if (!isAdmin) return <Navigate to="/" replace />;
  return <>{children}</>;
};

export default RequireAdmin;
