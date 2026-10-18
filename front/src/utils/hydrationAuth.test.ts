import { restoreAuthAfterHydration, _resetHydrationAuthForTests } from "./hydrationAuth";
import { setCredentials } from "../store/slices/authSlice";

const STORED = {
  user: { _id: "u1", name: "Ada", email: "ada@example.com", role: "admin" },
  token: "tok",
  refreshToken: "ref",
};

beforeEach(() => {
  window.localStorage.clear();
  _resetHydrationAuthForTests();
});

it("dispatches the stored session once", () => {
  window.localStorage.setItem("userInfo", JSON.stringify(STORED));
  const dispatch = jest.fn();

  restoreAuthAfterHydration(dispatch);

  expect(dispatch).toHaveBeenCalledTimes(1);
  expect(dispatch).toHaveBeenCalledWith(setCredentials(STORED));
});

it("is a no-op when nothing is stored", () => {
  const dispatch = jest.fn();

  restoreAuthAfterHydration(dispatch);

  expect(dispatch).not.toHaveBeenCalled();
});

it("is a no-op on a second call in the same page load", () => {
  window.localStorage.setItem("userInfo", JSON.stringify(STORED));
  const dispatch = jest.fn();

  restoreAuthAfterHydration(dispatch);
  restoreAuthAfterHydration(dispatch);

  expect(dispatch).toHaveBeenCalledTimes(1);
});
