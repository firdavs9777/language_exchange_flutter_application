// src/store/index.ts
import { createStore, combineReducers } from 'redux';
import { counterReducer } from './reducers/counterReducer/counterReducer';

const rootReducer = combineReducers({
  counter: counterReducer,
});

export type RootState = ReturnType<typeof rootReducer>;

const store = createStore(rootReducer);

export default store;