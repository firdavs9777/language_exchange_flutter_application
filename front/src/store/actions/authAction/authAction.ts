import { Action } from "redux";

export const login = (): Action => ({
  type: "LOGIN",
});

export const register = (): Action => ({
  type: "REGISTER",
});

export interface ActionType {
  type: string;
  payload?: any; // Add this if your actions have a payload
}
