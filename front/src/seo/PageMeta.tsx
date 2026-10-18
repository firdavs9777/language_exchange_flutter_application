import React from "react";
import { Helmet } from "react-helmet-async";
import { useTranslation } from "react-i18next";
import { SEO_PAGES, canonicalUrl, DEFAULT_OG_IMAGE, seoTitleEn, seoDescriptionEn } from "./pages";
import { englishFallback } from "./i18nFallback";

export interface PageMetaProps {
  /** A path from SEO_PAGES. Renders the full indexable tag set. */
  route?: string;
  /** App-only pages: noindex, plain title, no canonical or Open Graph tags. */
  noindex?: boolean;
  /** Overrides the title: with `noindex`, or on dynamic routes once data has loaded. */
  title?: string;
  /** Interpolation values for the title/description keys ({{name}} etc.). */
  values?: Record<string, string>;
}

const INDEX_ROBOTS = "index, follow, max-snippet:-1, max-image-preview:large, max-video-preview:-1";
const NOINDEX_ROBOTS = "noindex, nofollow";

const PageMeta: React.FC<PageMetaProps> = ({ route, noindex = false, title, values }) => {
  const { t } = useTranslation();
  const tr = (key: string) => (t(key, values as any) as string) || englishFallback(key);
  const page = route ? SEO_PAGES.find((p) => p.path === route) : undefined;

  if (noindex || !page) {
    const plain = title || tr("seo.appTitle") || "BananaTalk";
    return (
      <Helmet>
        <title>{plain}</title>
        <meta name="robots" content={NOINDEX_ROBOTS} />
      </Helmet>
    );
  }

  // A page whose keys have not reached the locale files yet falls back to the
  // English on its SEO entry -- never to an empty <title>, which would fail
  // the prerender.
  const resolvedTitle = title || tr(page.titleKey) || seoTitleEn(page);
  const description = tr(page.descriptionKey) || seoDescriptionEn(page);
  const url = canonicalUrl(page.path);
  const image = page.ogImage || DEFAULT_OG_IMAGE;
  const jsonLd = page.jsonLd ? page.jsonLd({ url }) : null;

  return (
    <Helmet>
      <title>{resolvedTitle}</title>
      <meta name="description" content={description} />
      <meta name="robots" content={INDEX_ROBOTS} />
      <link rel="canonical" href={url} />
      <meta property="og:type" content="website" />
      <meta property="og:url" content={url} />
      <meta property="og:title" content={resolvedTitle} />
      <meta property="og:description" content={description} />
      <meta property="og:image" content={image} />
      <meta property="og:site_name" content="BananaTalk" />
      <meta name="twitter:card" content="summary_large_image" />
      <meta name="twitter:title" content={resolvedTitle} />
      <meta name="twitter:description" content={description} />
      <meta name="twitter:image" content={image} />
      {jsonLd && <script type="application/ld+json">{JSON.stringify(jsonLd)}</script>}
    </Helmet>
  );
};

export default PageMeta;
