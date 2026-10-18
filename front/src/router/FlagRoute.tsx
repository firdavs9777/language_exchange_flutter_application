import React from "react";
import Loader from "../components/Loader";
import NotFound from "../components/errors/NotFound";
import { useWebFlagState, WebFlag } from "../utils/webFlags";

/**
 * Route gate for a Phase 4 feature. While its flag is off the path is a plain
 * 404 -- the feature does not exist as far as a visitor (or a crawler) can
 * tell. While app-config is still loading, a spinner: a deep link into a
 * flagged-on feature must not flash "page not found" first.
 */
const FlagRoute: React.FC<{ flag: WebFlag; children: React.ReactNode }> = ({ flag, children }) => {
  const { on, ready } = useWebFlagState(flag);
  if (!ready) {
    return (
      <div
        data-testid="flag-route-loading"
        style={{ minHeight: "60vh", display: "flex", alignItems: "center", justifyContent: "center" }}
        aria-busy="true"
      >
        <Loader />
      </div>
    );
  }
  if (!on) return <NotFound />;
  return <>{children}</>;
};

export default FlagRoute;
