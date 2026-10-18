import React from "react";

// Self-hosted Inter and Plus Jakarta Sans. First, and before index.css:
// the @font-face rules have to be in the stylesheet ahead of the rules
// that name the families. See src/fonts.css for which weights ship.
import "./fonts.css";
import "./index.css";
import { createRoot, hydrateRoot } from "react-dom/client";
import { RouterProvider } from "react-router-dom";
import { Provider } from "react-redux";
import { HelmetProvider } from "react-helmet-async";
import "./assets/styles/bootstrap.custom.css";
import "./assets/styles/legacy-buttons.css";
// bootstrap-icons is deliberately NOT imported here. It is ~2,000 glyph
// rules plus a webfont that no prerendered marketing page uses. It used to be
// loaded on demand by src/lazyIcons.ts for the few authenticated screens that
// still spelled `bi-*`; the profile redesign moved the last of them onto
// lucide, so nothing in src/ imports the package at all. src/seo/eagerGraph.test.ts
// keeps it out of the entrypoint if it ever comes back.

import router from "./router/AppRouter";
import store from "./store";
import i18n from "./utils/i18n";
import { prepareForHydration } from "./utils/hydrationLanguage";
import { documentIsPrerendered, markPrerendered } from "./seo/prerender/hydrationFlag";

const container = document.getElementById("root") as HTMLElement;

const app = (
  <React.StrictMode>
    <HelmetProvider>
      <Provider store={store}>
        <RouterProvider router={router} />
      </Provider>
    </HelmetProvider>
  </React.StrictMode>
);

if (documentIsPrerendered()) {
  // Prerendered page: hydrate over the English markup; App switches to the
  // visitor's language after the first commit.
  markPrerendered();
  prepareForHydration(i18n);
  hydrateRoot(container, app);
} else {
  createRoot(container).render(app);
}
