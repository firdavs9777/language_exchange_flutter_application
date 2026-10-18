import "@testing-library/jest-dom";
import React from "react";
import { render, screen, waitFor } from "@testing-library/react";
import { MemoryRouter, Routes, Route, useLocation } from "react-router-dom";
import AuthCallback from "./AuthCallback";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: (k: string) => k }) }));
const mockDispatch = jest.fn();
jest.mock("react-redux", () => ({ useDispatch: () => mockDispatch }));
jest.mock("react-toastify", () => ({ Bounce: {}, toast: { error: jest.fn(), info: jest.fn(), success: jest.fn() } }));
jest.mock("../Loader", () => () => <div data-testid="loader" />);

const COMPLETE_USER = { _id: "u1", name: "Ada", isRegistrationComplete: true };

type Reply = { status: number; body: any };
let replies: Reply[] = [];
const calls: { url: string; init: any }[] = [];

beforeEach(() => {
  replies = [];
  calls.length = 0;
  mockDispatch.mockReset();
  sessionStorage.clear();
  (global as any).fetch = jest.fn(async (url: string, init: any) => {
    calls.push({ url, init });
    const r = replies.shift() || { status: 500, body: {} };
    return { ok: r.status >= 200 && r.status < 300, status: r.status, json: async () => r.body };
  });
});
afterAll(() => window.history.replaceState(null, "", "/"));

const Where = () => <div data-testid="where">{useLocation().pathname}</div>;
const renderAt = (search: string, strict = false) => {
  window.history.replaceState(null, "", `/auth/callback${search}`);
  const tree = (
    <MemoryRouter initialEntries={[`/auth/callback${search}`]}>
      <Routes>
        <Route path="/auth/callback" element={<AuthCallback />} />
        <Route path="*" element={<Where />} />
      </Routes>
    </MemoryRouter>
  );
  return render(strict ? <React.StrictMode>{tree}</React.StrictMode> : tree);
};
const lastCredentials = () => mockDispatch.mock.calls.map((c) => c[0]).find((a) => a && a.type === "auth/setCredentials");

test("exchanges the code once, stores both tokens and scrubs the URL", async () => {
  replies.push({ status: 200, body: { success: true, token: "T", refreshToken: "R", user: COMPLETE_USER } });
  renderAt("?code=abc&token=legacy");
  expect(window.location.search).toBe("");
  await waitFor(() => expect(screen.getByTestId("where")).toHaveTextContent("/"));
  expect(calls).toHaveLength(1);
  expect(calls[0].url).toMatch(/\/api\/v1\/auth\/google\/exchange$/);
  expect(calls[0].init.method).toBe("POST");
  expect(JSON.parse(calls[0].init.body)).toEqual({ code: "abc" });
  expect(lastCredentials().payload).toEqual(expect.objectContaining({ user: COMPLETE_USER, token: "T", refreshToken: "R" }));
});

test("StrictMode's double effect does not spend the single-use code twice", async () => {
  replies.push({ status: 200, body: { success: true, token: "T", refreshToken: "R", user: COMPLETE_USER } });
  renderAt("?code=abc", true);
  await waitFor(() => expect(screen.getByTestId("where")).toHaveTextContent("/"));
  expect(calls).toHaveLength(1);
});

test("an expired code with no legacy token says so", async () => {
  replies.push({ status: 400, body: { success: false, code: "OAUTH_CODE_INVALID" } });
  renderAt("?code=old");
  expect(await screen.findByText("authentication.callback.codeExpired")).toBeInTheDocument();
  expect(lastCredentials()).toBeUndefined();
});

test("a banned account gets the suspended message", async () => {
  replies.push({ status: 403, body: { success: false, code: "ACCOUNT_BANNED" } });
  renderAt("?code=abc");
  expect(await screen.findByText("authentication.callback.banned")).toBeInTheDocument();
});

test("exchange failing during the rollout falls back to the legacy token", async () => {
  replies.push({ status: 404, body: {} });
  replies.push({ status: 200, body: { success: true, data: COMPLETE_USER } });
  renderAt("?code=abc&token=legacy");
  await waitFor(() => expect(screen.getByTestId("where")).toHaveTextContent("/"));
  expect(calls[1].url).toMatch(/\/api\/v1\/auth\/me$/);
  expect(calls[1].init.headers.Authorization).toBe("Bearer legacy");
  expect(lastCredentials().payload.token).toBe("legacy");
});

test("legacy ?token= only (backend not yet deployed) still signs in", async () => {
  replies.push({ status: 200, body: { success: true, data: COMPLETE_USER } });
  renderAt("?token=legacy");
  await waitFor(() => expect(screen.getByTestId("where")).toHaveTextContent("/"));
  expect(calls).toHaveLength(1);
  expect(calls[0].url).toMatch(/\/api\/v1\/auth\/me$/);
});

test("reason=EMAIL_EXISTS shows a localized message and calls nothing", async () => {
  renderAt("?error=An%20account%20exists&reason=EMAIL_EXISTS");
  expect(await screen.findByText("authentication.callback.emailExists")).toBeInTheDocument();
  expect(calls).toHaveLength(0);
});

test("no code and no token (e.g. a reload after scrubbing) asks to try again", async () => {
  renderAt("");
  expect(await screen.findByText("authentication.callback.noCode")).toBeInTheDocument();
  expect(calls).toHaveLength(0);
});

test("an incomplete profile goes to the signup wizard with the exchanged user", async () => {
  replies.push({ status: 200, body: { success: true, token: "T", refreshToken: "R", user: { _id: "u2", profileCompleted: false } } });
  renderAt("?code=abc");
  await waitFor(() => expect(screen.getByTestId("where")).toHaveTextContent("/register"));
});
