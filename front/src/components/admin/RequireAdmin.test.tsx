import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import RequireAdmin from "./RequireAdmin";

function renderGuarded(role?: string) {
  const store = configureStore({
    reducer: {
      auth: (state: any = { userInfo: role ? { user: { _id: "me", role } } : null }) => state,
    },
  });
  return render(
    <Provider store={store}>
      <MemoryRouter initialEntries={["/admin"]}>
        <Routes>
          <Route path="/" element={<div>home</div>} />
          <Route
            path="/admin"
            element={
              <RequireAdmin>
                <div>admin console</div>
              </RequireAdmin>
            }
          />
        </Routes>
      </MemoryRouter>
    </Provider>
  );
}

it("renders the console for an admin", () => {
  renderGuarded("admin");
  expect(screen.getByText("admin console")).toBeInTheDocument();
});

it("redirects a signed-in non-admin to the homepage", () => {
  renderGuarded("user");
  expect(screen.queryByText("admin console")).not.toBeInTheDocument();
  expect(screen.getByText("home")).toBeInTheDocument();
});

it("redirects a logged-out visitor to the homepage", () => {
  renderGuarded(undefined);
  expect(screen.queryByText("admin console")).not.toBeInTheDocument();
  expect(screen.getByText("home")).toBeInTheDocument();
});
