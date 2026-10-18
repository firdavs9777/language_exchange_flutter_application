import React from "react";
import { useLocation } from "react-router-dom";
import PageMeta from "./PageMeta";
import { findSeoPage } from "./pages";

// Mounted once in App. Indexed pages get their tag set from the SEO map;
// everything else is noindex. A page that needs richer tags (a public profile
// after its data loads) renders its own PageMeta deeper in the tree, and the
// deeper Helmet wins.
const RouteMeta: React.FC = () => {
  const { pathname } = useLocation();
  const page = findSeoPage(pathname);
  return page ? <PageMeta route={page.path} /> : <PageMeta noindex />;
};

export default RouteMeta;
