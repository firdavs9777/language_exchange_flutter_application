import React from "react";
import { I18nextProvider, useTranslation } from "react-i18next";
import i18n from "../../utils/i18n";

// The root route's errorElement.
//
// Since task B6 split the app into route chunks, a navigation can fail where
// nothing could fail before: a tab left open across a deploy asks for hashed
// chunks the server no longer has. src/router/lazyWithRetry.ts retries and then
// reloads once; if that did not help, the rejection lands here instead of on
// react-router's default error screen, which replaces the app with a stack
// trace and leaves the visitor no way back.
//
// This element replaces <App /> when it renders, so it stands alone: no
// navbar, no footer, and -- the part that matters -- no I18nextProvider above
// it. It brings its own, around the same singleton App uses.
//
// Prerender-safe: no browser global is read at import time or during render.
// window.location only appears in the click handler.
const reloadPage = () => {
  if (typeof window !== "undefined") window.location.reload();
};

const RouteErrorBody: React.FC = () => {
  const { t } = useTranslation();
  return (
    <section
      role="alert"
      data-testid="route-error"
      className="bg-canvas px-4 py-24 text-center dark:bg-canvas-dark"
    >
      <h1 className="text-2xl font-extrabold text-gray-900 dark:text-gray-50">
        {t("errors.chunk.title") || "Something went wrong loading this page"}
      </h1>
      <p className="mx-auto mt-3 max-w-md text-sm text-gray-600 dark:text-gray-300">
        {t("errors.chunk.body") ||
          "Part of the app didn't load. This usually happens right after an update — reloading should fix it."}
      </p>
      <button
        type="button"
        onClick={reloadPage}
        className="mt-6 rounded-full bg-brand px-5 py-2.5 text-sm font-extrabold text-white shadow-brand"
      >
        {t("errors.chunk.reload") || "Reload"}
      </button>
    </section>
  );
};

const RouteError: React.FC = () => (
  <I18nextProvider i18n={i18n}>
    <RouteErrorBody />
  </I18nextProvider>
);

export default RouteError;
