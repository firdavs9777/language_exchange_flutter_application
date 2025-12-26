// hooks/useAuthToken.ts
import { useSelector } from "react-redux";
import { RootState } from "../store";

export const useAuthToken = () => {
  const token = useSelector((state: RootState) => state.auth.userInfo?.token);
  return token;
};
