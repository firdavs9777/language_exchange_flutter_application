import React from "react";
import { useSelector } from "react-redux";
import { Navigate } from "react-router-dom";

/** The reels endpoints need a session; a signed-out visitor goes to /login. */
const SignedInOnly: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const userId = useSelector((state: any) => state.auth.userInfo && state.auth.userInfo.user && state.auth.userInfo.user._id);
  if (!userId) return <Navigate to="/login" replace />;
  return <>{children}</>;
};

export default SignedInOnly;
