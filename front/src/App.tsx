import React, { useEffect } from "react";
import "./App.scss";
import { I18nextProvider } from "react-i18next";
import i18n from "./utils/i18n";
import { restoreAfterHydration } from "./utils/hydrationLanguage";
import { restoreAuthAfterHydration } from "./utils/hydrationAuth";
import { clearPrerendered, isPrerendered } from "./seo/prerender/hydrationFlag";
import RouteMeta from "./seo/RouteMeta";

import MainNavbar from "./components/navbar/MainNavbar";
import { Container } from "react-bootstrap";
import { Outlet, ScrollRestoration } from "react-router-dom";
import { useDispatch } from "react-redux";
import { ToastContainer, Slide } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
// Must come AFTER toastify's own stylesheet: it overrides it.
import "./design/toastTheme.css";
import FooterMain from "./components/footer/FooterMain";
import { SocketProvider } from "./components/chat/hooks/useSocket";
import AppBanner from "./components/linking/AppBanner";
import AnnouncementSurfaces from "./components/announcements/AnnouncementSurfaces";
import { usePageView } from "./analytics/usePageView";
import ConsentBar from "./components/growth/ConsentBar";
import AdsBootstrap from "./components/ads/AdsBootstrap";

const App = () => {
  usePageView();
  const dispatch = useDispatch();

  // After a prerendered page hydrates logged out and in English, put the
  // visitor's session and language back — and let later mounts animate again:
  // hydration has committed, so nothing more will be compared against the
  // prerendered markup. Client-rendered pages already have both.
  useEffect(() => {
    if (isPrerendered()) restoreAuthAfterHydration(dispatch);
    restoreAfterHydration(i18n);
    clearPrerendered();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <I18nextProvider i18n={i18n}>
      <RouteMeta />
      <SocketProvider>
        <MainNavbar />
        <AppBanner />
        <AnnouncementSurfaces />
        <Container fluid>
          <Outlet />
        </Container>
        {/* Every route change started where the last one left off: clicking a
            suggested member at the foot of a profile loaded the new profile
            with the window still scrolled to the bottom, because the route
            param changes without remounting the page component.
            React Router's own restorer rather than a scrollTo(0, 0) effect:
            it sends a NEW navigation to the top but puts BACK where it was,
            which is what a reader expects and what a manual reset destroys. */}
        <ScrollRestoration />
        <FooterMain />
        <ConsentBar />
        <AdsBootstrap />
        {/*
          Defaults for every toast that does not override them. Most existing
          call sites still pass their own options object and win over these;
          the appearance is fixed in design/toastTheme.css instead, which no
          call site can override. `newestOnTop` + a stack limit keeps a burst
          of failures from covering the screen, which is when a toast is least
          useful and most in the way.
        */}
        <ToastContainer
          position="top-right"
          autoClose={3200}
          limit={3}
          newestOnTop
          transition={Slide}
          closeOnClick
          pauseOnHover
          pauseOnFocusLoss
          draggable
          role="alert"
        />
      </SocketProvider>
    </I18nextProvider>
  );
};

export default App;
