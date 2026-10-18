import React from "react";
import { Navigate, useParams } from "react-router-dom";

/** Old shared links look like /moments/<id>; the detail page lives at /moment/<id>. */
const MomentLinkRedirect: React.FC = () => {
  const { id } = useParams();
  return <Navigate to={`/moment/${encodeURIComponent(id || "")}`} replace />;
};

export default MomentLinkRedirect;
