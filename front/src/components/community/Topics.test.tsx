import "@testing-library/jest-dom";
import React from "react";
import fs from "fs";
import path from "path";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import {
  createMemoryRouter,
  createRoutesFromElements,
  Route,
  RouterProvider,
} from "react-router-dom";
import { makeStore } from "../../store";
import Topics from "./Topics";

// `t` returns the key so every assertion below is about behaviour, not copy —
// the same convention the rest of the community suite uses.
jest.mock("react-i18next", () => ({
  useTranslation: () => ({
    t: (key: string, vars?: any) =>
      vars && typeof vars.count === "number" ? `${key}:${vars.count}` : key,
  }),
  Trans: ({ children }: any) => children || null,
  initReactI18next: { type: "3rdParty", init: () => {} },
}));

const mockNotifySuccess = jest.fn();
const mockNotifyError = jest.fn();
jest.mock("../../design/notify", () => ({
  __esModule: true,
  default: {
    success: (...args: any[]) => mockNotifySuccess(...args),
    error: (...args: any[]) => mockNotifyError(...args),
    info: jest.fn(),
    warning: jest.fn(),
    show: jest.fn(),
    dismiss: jest.fn(),
  },
  TOAST_MS: { success: 1, info: 1, warning: 1, error: 1 },
}));

const TOPICS = [
  { id: "travel", name: "Travel", icon: "✈️", category: "travel", userCount: 42 },
  { id: "cooking", name: "Cooking", icon: "🍳", category: "food_drink", userCount: 7 },
  { id: "kpop", name: "K-Pop", icon: "🇰🇷", category: "entertainment", userCount: 91 },
];

const person = (n: number) => ({
  _id: `p${n}`,
  name: `Person ${n}`,
  native_language: "Korean",
  language_to_learn: "English",
  images: [],
  imageUrls: [],
  isOnline: n % 2 === 0,
});

type Req = { url: string; method: string; body?: any };
let requests: Req[] = [];
/** How many people the topic-users endpoint answers with, per call. */
let usersPerPage = 2;
let usersHasMore = true;
let updateFails = false;

const originalFetch = global.fetch;

beforeEach(() => {
  requests = [];
  usersPerPage = 2;
  usersHasMore = true;
  updateFails = false;
  (global as any).fetch = jest.fn((input: any, init?: any) => {
    const url = typeof input === "string" ? input : input?.url || "";
    const method = (init?.method || (typeof input === "string" ? "GET" : input?.method) || "GET").toUpperCase();
    const record: Req = { url, method };
    requests.push(record);

    // RTK Query hands `fetch` a Request object, not (url, init) -- so the
    // body has to be read off the clone, which is a promise. Assertions on it
    // go through `waitFor`.
    let body: any;
    const rawBody = init && init.body;
    if (rawBody) {
      try {
        body = JSON.parse(rawBody);
      } catch (e) {
        body = rawBody;
      }
      record.body = body;
    } else if (input && typeof input.clone === "function" && method !== "GET") {
      input
        .clone()
        .text()
        .then((text: string) => {
          try {
            record.body = JSON.parse(text);
            body = record.body;
          } catch (e) {
            record.body = text;
          }
        });
    }

    if (/\/topics\/my\b/.test(url) || /\/topics\/my-topics\b/.test(url)) {
      if (updateFails) {
        return Promise.resolve(
          new Response(JSON.stringify({ success: false }), {
            status: 500,
            headers: { "content-type": "application/json" },
          })
        );
      }
      return Promise.resolve(
        new Response(JSON.stringify({ success: true, data: { topics: [] } }), {
          status: 200,
          headers: { "content-type": "application/json" },
        })
      );
    }

    if (/\/topics\/[^/]+\/users/.test(url)) {
      const pageMatch = url.match(/[?&]page=(\d+)/);
      const page = pageMatch ? parseInt(pageMatch[1], 10) : 1;
      const data = Array.from({ length: usersPerPage }, (_u, i) =>
        person((page - 1) * usersPerPage + i + 1)
      );
      return Promise.resolve(
        new Response(
          JSON.stringify({
            success: true,
            data,
            pagination: { total: 10, page, limit: 20, hasMore: usersHasMore },
          }),
          { status: 200, headers: { "content-type": "application/json" } }
        )
      );
    }

    if (/\/community\/topics(\?|$)/.test(url)) {
      return Promise.resolve(
        new Response(JSON.stringify({ success: true, data: TOPICS }), {
          status: 200,
          headers: { "content-type": "application/json" },
        })
      );
    }

    return Promise.resolve(
      new Response(JSON.stringify({ success: true, data: [] }), {
        status: 200,
        headers: { "content-type": "application/json" },
      })
    );
  });
});

afterEach(() => {
  global.fetch = originalFetch;
  jest.clearAllMocks();
});

const signedIn = (topics: string[] = ["travel"]) => ({
  auth: {
    userInfo: {
      user: {
        _id: "u1",
        name: "Me",
        native_language: "English",
        language_to_learn: "Korean",
        topics,
      },
      token: "t",
    },
  },
});

function renderTopics(entries: string[] = ["/topics"], preloaded: any = signedIn()) {
  const router = createMemoryRouter(
    createRoutesFromElements(
      <Route path="/">
        <Route path="topics" element={<Topics />} />
        <Route path="communities" element={<div data-testid="communities-screen" />} />
        <Route path="community/:id" element={<div data-testid="member-screen" />} />
      </Route>
    ),
    { initialEntries: entries }
  );
  const utils = render(
    <Provider store={makeStore(preloaded)}>
      <RouterProvider router={router} />
    </Provider>
  );
  return { ...utils, router };
}

/** Every `GET .../topics/<id>/users` the page asked for, oldest first. */
const userRequests = () => requests.filter((r) => /\/topics\/[^/]+\/users/.test(r.url));

describe("the topics grid", () => {
  it("renders a tile per topic with a lucide icon and the member count", async () => {
    renderTopics();

    await waitFor(() => expect(screen.getByTestId("topic-tile-travel")).toBeInTheDocument());

    expect(screen.getByTestId("topic-tile-cooking")).toBeInTheDocument();
    expect(screen.getByTestId("topic-tile-kpop")).toBeInTheDocument();
    expect(screen.getByTestId("topic-tile-travel")).toHaveTextContent("Travel");
    // `{{count}} members` goes through i18n, never a bare concatenation.
    expect(screen.getByTestId("topic-tile-travel")).toHaveTextContent("topics.memberCount:42");

    // A lucide <svg>, not the backend's emoji string, carries the icon.
    const icon = screen.getByTestId("topic-tile-travel").querySelector("svg");
    expect(icon).toBeTruthy();
    expect(screen.getByTestId("topic-tile-travel").textContent).not.toContain("✈️");
  });

  it("lays the grid out 2 / 3 / 4 across", async () => {
    renderTopics();
    await waitFor(() => expect(screen.getByTestId("topics-grid")).toBeInTheDocument());
    const cls = screen.getByTestId("topics-grid").className;
    expect(cls).toContain("grid-cols-2");
    expect(cls).toContain("md:grid-cols-3");
    expect(cls).toContain("lg:grid-cols-4");
  });

  it("shows skeletons before the topics land", () => {
    renderTopics();
    expect(screen.getByTestId("topics-skeletons")).toBeInTheDocument();
  });

  it("shows an empty state when the search matches nothing", async () => {
    renderTopics();
    await waitFor(() => expect(screen.getByTestId("topic-tile-travel")).toBeInTheDocument());

    fireEvent.change(screen.getByTestId("topics-search"), { target: { value: "zzzz" } });

    expect(screen.getByTestId("topics-empty")).toBeInTheDocument();
    expect(screen.queryByTestId("topic-tile-travel")).not.toBeInTheDocument();
  });
});

describe("your topics", () => {
  it("lists the viewer's own topics as chips", async () => {
    renderTopics(["/topics"], signedIn(["travel", "kpop"]));
    expect(screen.getByTestId("topics-my-section")).toBeInTheDocument();
    // The chips carry the topic's real (localized) name, so they wait for the
    // list rather than falling back to the slug.
    await waitFor(() => expect(screen.getByTestId("topic-tile-travel")).toBeInTheDocument());

    expect(screen.getByTestId("topics-my-chip-travel")).toHaveTextContent("Travel");
    expect(screen.getByTestId("topics-my-chip-kpop")).toHaveTextContent("K-Pop");
    expect(screen.queryByTestId("topics-my-chip-cooking")).not.toBeInTheDocument();
  });

  it("is hidden for a signed-out visitor", async () => {
    renderTopics(["/topics"], { auth: { userInfo: null } });
    await waitFor(() => expect(screen.getByTestId("topic-tile-travel")).toBeInTheDocument());
    expect(screen.queryByTestId("topics-my-section")).not.toBeInTheDocument();
    expect(screen.queryByTestId("topics-edit-button")).not.toBeInTheDocument();
  });

  it("Edit turns the grid into a multi-select and Save sends the chosen ids", async () => {
    renderTopics(["/topics"], signedIn(["travel"]));
    await waitFor(() => expect(screen.getByTestId("topic-tile-travel")).toBeInTheDocument());

    fireEvent.click(screen.getByTestId("topics-edit-button"));

    // The viewer's existing pick starts selected.
    expect(screen.getByTestId("topic-tile-travel")).toHaveAttribute("aria-pressed", "true");
    expect(screen.getByTestId("topic-tile-cooking")).toHaveAttribute("aria-pressed", "false");

    // In edit mode a tile toggles instead of opening the topic's people.
    fireEvent.click(screen.getByTestId("topic-tile-cooking"));
    expect(screen.getByTestId("topic-tile-cooking")).toHaveAttribute("aria-pressed", "true");
    expect(screen.queryByTestId("topic-people")).not.toBeInTheDocument();

    fireEvent.click(screen.getByTestId("topic-tile-travel"));
    expect(screen.getByTestId("topic-tile-travel")).toHaveAttribute("aria-pressed", "false");

    fireEvent.click(screen.getByTestId("topics-save-button"));

    await waitFor(() => expect(mockNotifySuccess).toHaveBeenCalled());

    const put = requests.filter((r) => r.method === "PUT");
    expect(put).toHaveLength(1);
    expect(put[0].url).toContain("/community/topics/my");
    await waitFor(() => expect(put[0].body).toBeDefined());
    expect(put[0].body.topics).toEqual(["cooking"]);

    // Saving leaves edit mode and the chips reflect the new selection.
    expect(screen.queryByTestId("topics-save-button")).not.toBeInTheDocument();
    expect(screen.getByTestId("topics-my-chip-cooking")).toBeInTheDocument();
  });

  it("Cancel throws the draft away", async () => {
    renderTopics(["/topics"], signedIn(["travel"]));
    await waitFor(() => expect(screen.getByTestId("topic-tile-travel")).toBeInTheDocument());

    fireEvent.click(screen.getByTestId("topics-edit-button"));
    fireEvent.click(screen.getByTestId("topic-tile-cooking"));
    fireEvent.click(screen.getByTestId("topics-cancel-button"));

    expect(screen.queryByTestId("topics-my-chip-cooking")).not.toBeInTheDocument();
    expect(screen.getByTestId("topics-my-chip-travel")).toBeInTheDocument();
    expect(requests.filter((r) => r.method === "PUT")).toHaveLength(0);
  });

  it("reports a failed save without leaving edit mode", async () => {
    updateFails = true;
    renderTopics(["/topics"], signedIn(["travel"]));
    await waitFor(() => expect(screen.getByTestId("topic-tile-travel")).toBeInTheDocument());

    fireEvent.click(screen.getByTestId("topics-edit-button"));
    fireEvent.click(screen.getByTestId("topics-save-button"));

    await waitFor(() => expect(mockNotifyError).toHaveBeenCalled());
    expect(screen.getByTestId("topics-save-button")).toBeInTheDocument();
  });
});

describe("the people in a topic", () => {
  it("opens on a tile click, writes ?topic= and asks for that topic's users", async () => {
    const { router } = renderTopics();
    await waitFor(() => expect(screen.getByTestId("topic-tile-kpop")).toBeInTheDocument());

    fireEvent.click(screen.getByTestId("topic-tile-kpop"));

    await waitFor(() => expect(screen.getByTestId("topic-people")).toBeInTheDocument());
    expect(router.state.location.search).toBe("?topic=kpop");

    await waitFor(() => expect(userRequests().length).toBeGreaterThan(0));
    expect(userRequests()[0].url).toContain("/topics/kpop/users");
    expect(userRequests()[0].url).toContain("page=1");

    await waitFor(() =>
      expect(screen.getAllByTestId("member-card-root").length).toBe(2)
    );
  });

  it("opens straight from a ?topic= link", async () => {
    renderTopics(["/topics?topic=cooking"]);

    await waitFor(() => expect(screen.getByTestId("topic-people")).toBeInTheDocument());
    await waitFor(() => expect(userRequests().length).toBeGreaterThan(0));
    expect(userRequests()[0].url).toContain("/topics/cooking/users");
  });

  it("the back link clears ?topic= and closes the panel", async () => {
    const { router } = renderTopics(["/topics?topic=cooking"]);
    await waitFor(() => expect(screen.getByTestId("topic-people")).toBeInTheDocument());

    fireEvent.click(screen.getByTestId("topic-people-back"));

    await waitFor(() => expect(screen.queryByTestId("topic-people")).not.toBeInTheDocument());
    expect(router.state.location.search).toBe("");
  });

  it("the online-only toggle re-asks with onlineOnly=true", async () => {
    renderTopics(["/topics?topic=travel"]);
    await waitFor(() => expect(userRequests().length).toBeGreaterThan(0));
    expect(userRequests()[0].url).not.toContain("onlineOnly=true");

    fireEvent.click(screen.getByTestId("topic-people-online-toggle"));

    await waitFor(() =>
      expect(userRequests().some((r) => r.url.indexOf("onlineOnly=true") >= 0)).toBe(true)
    );
    const last = userRequests()[userRequests().length - 1];
    expect(last.url).toContain("/topics/travel/users");
    expect(last.url).toContain("page=1");
  });

  it("Load more appends the next page", async () => {
    renderTopics(["/topics?topic=travel"]);
    await waitFor(() =>
      expect(screen.getAllByTestId("member-card-root").length).toBe(2)
    );

    fireEvent.click(screen.getByTestId("topic-people-loadmore"));

    await waitFor(() =>
      expect(screen.getAllByTestId("member-card-root").length).toBe(4)
    );
    expect(userRequests()[userRequests().length - 1].url).toContain("page=2");
  });

  it("hides Load more on the last page and shows an empty state with nobody in it", async () => {
    usersPerPage = 0;
    usersHasMore = false;
    renderTopics(["/topics?topic=travel"]);

    await waitFor(() => expect(screen.getByTestId("topic-people-empty")).toBeInTheDocument());
    expect(screen.queryByTestId("topic-people-loadmore")).not.toBeInTheDocument();
  });
});

describe("the copy", () => {
  it("every topics.* key the page uses exists in eng.json", () => {
    const source = fs.readFileSync(path.join(__dirname, "Topics.tsx"), "utf8");
    const used: string[] = [];
    const re = /t\("(topics\.[A-Za-z0-9_.]+)"/g;
    let m = re.exec(source);
    while (m) {
      if (used.indexOf(m[1]) < 0) used.push(m[1]);
      m = re.exec(source);
    }
    expect(used.length).toBeGreaterThan(0);

    const eng = JSON.parse(
      fs.readFileSync(path.join(__dirname, "../../utils/locales/eng.json"), "utf8")
    );
    // Every key must live in eng.json (the locale merge happened); no scratch files.
    const newKeys = {};

    const has = (tree: any, key: string): boolean => {
      let node = tree;
      const parts = key.split(".");
      for (let i = 0; i < parts.length; i += 1) {
        if (!node || typeof node !== "object") return false;
        node = node[parts[i]];
      }
      return typeof node === "string";
    };

    const missing = used.filter((k) => !has(eng, k) && !has(newKeys, k));
    expect(missing).toEqual([]);

    // The new-keys file must not re-declare something eng.json already ships.
    const flatten = (tree: any, prefix: string, out: string[]) => {
      Object.keys(tree).forEach((k) => {
        if (k.charAt(0) === "_") return;
        const full = prefix ? `${prefix}.${k}` : k;
        if (tree[k] && typeof tree[k] === "object") flatten(tree[k], full, out);
        else out.push(full);
      });
    };
    const declared: string[] = [];
    flatten(newKeys, "", declared);
    expect(declared.filter((k) => has(eng, k))).toEqual([]);
    // ...and everything it declares must actually be used by the page.
    expect(declared.filter((k) => used.indexOf(k) < 0)).toEqual([]);
  });
});
