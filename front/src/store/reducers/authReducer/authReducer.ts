import { ActionType } from "../../actions/authAction/authAction";

export interface AuthState {
  login_check: boolean;
}

const initialState: AuthState = {
  login_check: false,
};

export const authReducer = (
  state: AuthState = initialState,
  action: ActionType
): AuthState => {
  switch (action.type) {
    case "LOGIN":
      return { ...state, login_check: !state.login_check };
    case "REGISTER":
      return { ...state, login_check: !state.login_check };
    default:
      return state;
  }
};
