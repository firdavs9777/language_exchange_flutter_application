import React from "react";
import { Navigate } from "react-router-dom";

// Legacy placeholder. The real filtering lives inside MainCommunity's
// CommunityFilterSheet — visiting any /community-filter route just bounces
// back to the list. Kept as a stub so any old bookmark / link doesn't 404.
const CommunityFilter: React.FC = () => <Navigate to="/communities" replace />;

export default CommunityFilter;
