import { Action } from "redux";

export const increment = (): Action => ({
  type: 'INCREMENT',
});

export const decrement = (): Action => ({
  type: 'DECREMENT'
});

export interface ActionType {
  type: string;
  payload?: any; // Add this if your actions have a payload
}