import React from "react";
import { renderToString } from "react-dom/server";
import { Provider } from "react-redux";
import { HelmetProvider } from "react-helmet-async";
import { createStaticHandler, createStaticRouter, StaticRouterProvider } from "react-router-dom/server";
import { routes } from "../../router/routes";
import { makeStore, AppStore } from "../../store";
import { apiSlice } from "../../store/slices/apiSlice";
import i18n from "../../utils/i18n";
import { SITE_ORIGIN } from "../pages";
import { makeRequest } from "./requestShim";
import { prefetchersFor } from "./prefetch";

export interface RenderedRoute {
  path: string;
  status: number;
  html: string;
  head: string;
  /** The store state the prerender fetched, for the client to hydrate from. */
  state: Record<string, unknown>;
}

export interface RenderOptions {
  /** Default true. Tests pass false to stay offline. */
  prefetch?: boolean;
  /** Per-prefetch timeout. Default 5000ms. */
  fetchTimeoutMs?: number;
  /** Where data-fetch warnings go. Default: console.warn. */
  log?: (message: string) => void;
}

// A path nothing routes to, so "/404" renders the catch-all route.
const NOT_FOUND_PROBE = "/__not_found__";

function withTimeout<T>(p: Promise<T>, ms: number): Promise<T> {
  return new Promise((resolve, reject) => {
    const t = setTimeout(() => reject(new Error(`timed out after ${ms}ms`)), ms);
    p.then(
      (v) => {
        clearTimeout(t);
        resolve(v);
      },
      (e) => {
        clearTimeout(t);
        reject(e);
      }
    );
  });
}

async function prefetch(store: AppStore, path: string, opts: RenderOptions): Promise<void> {
  const log = opts.log || ((m: string) => console.warn(m));
  const ms = opts.fetchTimeoutMs || 5000;
  await Promise.all(
    prefetchersFor(path).map((run) =>
      withTimeout(run(store), ms).catch((err) => {
        // Data is allowed to fail; the page renders its fallback (spec §8).
        log(`prefetch for ${path} failed: ${err && err.message ? err.message : err}`);
      })
    )
  );
}

/**
 * Renders one public route to static HTML with its head tags.
 *
 * Throws -- and therefore fails the build -- on any render error, on a page
 * with anything other than exactly one <h1>, or on a page that set no title.
 * Browser globals are simply absent in Node, so a component that reads them
 * during render throws a ReferenceError here instead of shipping an empty page.
 */
export async function renderRoute(path: string, opts: RenderOptions = {}): Promise<RenderedRoute> {
  if (typeof window !== "undefined") {
    throw new Error("renderRoute must run without a DOM; a window global is present");
  }

  const store = makeStore();
  await i18n.changeLanguage("en");
  if (opts.prefetch !== false) await prefetch(store, path, opts);

  const handler = createStaticHandler(routes);
  const url = `${SITE_ORIGIN}${path === "/404" ? NOT_FOUND_PROBE : path}`;
  const queried = await handler.query(makeRequest(url));
  // A redirect or thrown Response comes back as a Response; a render comes
  // back as a StaticHandlerContext. Checked structurally: `Response` is not
  // defined in Jest 27's node sandbox, so `instanceof Response` would throw.
  if (!("statusCode" in queried)) {
    throw new Error(`Route ${path} produced a Response (${(queried as any).status}) instead of rendering`);
  }
  const context = queried;

  const router = createStaticRouter(routes, context);
  const helmetContext: any = {};
  const html = renderToString(
    <HelmetProvider context={helmetContext}>
      <Provider store={store}>
        <StaticRouterProvider router={router} context={context} hydrate={false} />
      </Provider>
    </HelmetProvider>
  );

  const h = helmetContext.helmet;
  const head = [h.title.toString(), h.meta.toString(), h.link.toString(), h.script.toString()]
    .filter(Boolean)
    .join("\n");

  const h1Count = (html.match(/<h1[\s>]/g) || []).length;
  if (h1Count !== 1) throw new Error(`Route ${path} rendered ${h1Count} <h1> elements; expected exactly 1`);
  if (!/<title[^>]*>[^<]+<\/title>/.test(head)) throw new Error(`Route ${path} set no <title>`);

  // Ship the fetched data with the page so the client's first render matches
  // this markup. Subscriptions and in-flight mutations are per-client
  // bookkeeping and mean nothing in the browser, so they are dropped;
  // `queries` and `provided` carry the fulfilled results.
  const apiState = store.getState()[apiSlice.reducerPath];
  const state = { [apiSlice.reducerPath]: { ...apiState, subscriptions: {}, mutations: {} } };

  return { path, status: path === "/404" ? 404 : context.statusCode, html, head, state };
}
