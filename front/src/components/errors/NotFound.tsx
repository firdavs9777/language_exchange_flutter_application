import React from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import PageMeta from "../../seo/PageMeta";

// Rendered by the "*" route. Prerendered to build/404.html and, once
// deploy/nginx.snippet.conf is applied on the server, served with a real 404
// status for any URL outside the generated route allowlist -- so a dead link no
// longer returns 200 with an empty page.
const NotFound: React.FC = () => {
  const { t } = useTranslation();
  return (
    <section data-testid="not-found" className="bg-canvas px-4 py-24 text-center dark:bg-canvas-dark">
      <PageMeta noindex title={t("notFound.pageTitle") || "Page not found | BananaTalk"} />
      <p className="text-6xl font-extrabold text-brand" aria-hidden>404</p>
      <h1 className="mt-4 text-2xl font-extrabold text-gray-900 dark:text-gray-50">
        {t("notFound.title") || "This page doesn't exist"}
      </h1>
      <p className="mx-auto mt-3 max-w-md text-sm text-gray-600 dark:text-gray-300">
        {t("notFound.body") || "The link may be old, or the page may have moved. Here is the way back."}
      </p>
      <div className="mt-6 flex flex-wrap justify-center gap-2">
        <Link to="/" className="rounded-full bg-brand px-5 py-2.5 text-sm font-extrabold text-white shadow-brand">
          {t("notFound.home") || "Go to the homepage"}
        </Link>
        <Link
          to="/download"
          className="rounded-full border-2 border-brand px-5 py-2.5 text-sm font-extrabold text-brand-dark dark:text-brand-light"
        >
          {t("notFound.download") || "Get the app"}
        </Link>
      </div>
    </section>
  );
};

export default NotFound;
