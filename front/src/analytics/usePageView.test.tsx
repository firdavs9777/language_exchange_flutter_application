import React from "react";
import { render } from "@testing-library/react";
import { createMemoryRouter, RouterProvider, Outlet } from "react-router-dom";
import { usePageView } from "./usePageView";

jest.mock("./ga", () => ({ gaEvent: jest.fn() }));

const flush = () => new Promise((r) => setTimeout(r, 0));

const Layout: React.FC = () => {
  usePageView();
  return <Outlet />;
};

const Profile: React.FC = () => <div>profile page</div>;

beforeEach(() => {
  (global as any).fetch = jest.fn(async () => new Response(null, { status: 204 }));
});

it("tracks the route template, not the concrete path, while the legacy ping keeps the real path", async () => {
  const router = createMemoryRouter(
    [
      {
        path: "/",
        element: <Layout />,
        children: [{ path: "profile/:userId", element: <Profile /> }],
      },
    ],
    { initialEntries: ["/profile/u42"] }
  );

  render(<RouterProvider router={router} />);
  await flush();

  const calls = (global.fetch as jest.Mock).mock.calls;

  const eventsCall = calls.find(([url]) => String(url).includes("/analytics/events"));
  expect(eventsCall).toBeDefined();
  const eventsBody = JSON.parse(eventsCall![1].body);
  expect(eventsBody.path).toBe("/profile/:userId");
  expect(eventsBody.path).not.toContain("u42");
  expect(JSON.stringify(eventsBody)).not.toContain("u42");

  const visitCall = calls.find(([url]) => String(url).includes("/analytics/visit"));
  expect(visitCall).toBeDefined();
  const visitBody = JSON.parse(visitCall![1].body);
  expect(visitBody.page).toBe("/profile/u42");
});
