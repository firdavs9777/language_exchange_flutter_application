import "@testing-library/jest-dom";
import React from "react";
import { render } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import AdUnit from "./AdUnit";
import AdsBootstrap from "./AdsBootstrap";
import { loadAdSense } from "./loadAdSense";
import { writeConsent } from "../../analytics/consent";

jest.mock("./loadAdSense", () => ({ loadAdSense: jest.fn() }));
const loadAdSenseMock = loadAdSense as jest.Mock;

// The config reads the env on every call, so a case just sets the variables it
// cares about. REACT_APP_ADS_DEV is what makes `adsEnabled()` true outside a
// production build.
const CLIENT = "ca-pub-1";
let savedEnv: NodeJS.ProcessEnv;

function setEnv(env: Record<string, string>) {
  Object.assign(process.env, {
    REACT_APP_ADSENSE_CLIENT: "",
    REACT_APP_ADS_DEV: "true",
    REACT_APP_ADSENSE_AUTO_ADS: "",
    ...env,
  });
}

/** `user` null renders as a logged-out visitor. */
function renderFor(user: any, element: React.ReactElement) {
  const store = configureStore({
    reducer: { auth: () => ({ userInfo: user ? { user, token: "t" } : null }) },
  });
  return render(<Provider store={store}>{element}</Provider>);
}

beforeEach(() => {
  savedEnv = { ...process.env };
  loadAdSenseMock.mockClear();
  delete (window as any).adsbygoogle;
  window.localStorage.clear();
});

afterEach(() => {
  process.env = savedEnv;
});

describe("AdUnit", () => {
  it("renders nothing without a client id", () => {
    setEnv({});
    const { container } = renderFor(null, <AdUnit slot="123" />);
    expect(container.querySelector("ins")).toBeNull();
    expect(loadAdSenseMock).not.toHaveBeenCalled();
  });

  it("renders nothing without a slot id", () => {
    setEnv({ REACT_APP_ADSENSE_CLIENT: CLIENT });
    const { container } = renderFor(null, <AdUnit slot="" />);
    expect(container.querySelector("ins")).toBeNull();
  });

  it("renders the unit and pushes once for a regular user", () => {
    setEnv({ REACT_APP_ADSENSE_CLIENT: CLIENT });
    const { container } = renderFor(
      { userMode: "regular" },
      <AdUnit slot="123" />
    );
    const ins = container.querySelector("ins.adsbygoogle");
    expect(ins).toHaveAttribute("data-ad-client", CLIENT);
    expect(ins).toHaveAttribute("data-ad-slot", "123");
    expect(loadAdSenseMock).toHaveBeenCalledTimes(1);
    expect((window as any).adsbygoogle).toHaveLength(1);
  });

  it("renders for logged-out visitors", () => {
    setEnv({ REACT_APP_ADSENSE_CLIENT: CLIENT });
    const { container } = renderFor(null, <AdUnit slot="123" />);
    expect(container.querySelector("ins.adsbygoogle")).not.toBeNull();
  });

  it("renders nothing and never pushes for a VIP user", () => {
    setEnv({ REACT_APP_ADSENSE_CLIENT: CLIENT });
    const { container } = renderFor({ userMode: "vip" }, <AdUnit slot="123" />);
    expect(container.querySelector("ins")).toBeNull();
    expect(loadAdSenseMock).not.toHaveBeenCalled();
    expect((window as any).adsbygoogle).toBeUndefined();
  });

  it("renders nothing for an active VIP subscription on a regular account", () => {
    setEnv({ REACT_APP_ADSENSE_CLIENT: CLIENT });
    const { container } = renderFor(
      { userMode: "regular", vipSubscription: { isActive: true } },
      <AdUnit slot="123" />
    );
    expect(container.querySelector("ins")).toBeNull();
  });
});

describe("AdsBootstrap", () => {
  it("loads the script site-wide when auto ads are on", () => {
    setEnv({
      REACT_APP_ADSENSE_CLIENT: CLIENT,
      REACT_APP_ADSENSE_AUTO_ADS: "true",
    });
    renderFor(null, <AdsBootstrap />);
    expect(loadAdSenseMock).toHaveBeenCalledTimes(1);
  });

  it("does not load the script when auto ads are off", () => {
    setEnv({ REACT_APP_ADSENSE_CLIENT: CLIENT });
    renderFor(null, <AdsBootstrap />);
    expect(loadAdSenseMock).not.toHaveBeenCalled();
  });

  it("does not load the script for VIP users", () => {
    setEnv({
      REACT_APP_ADSENSE_CLIENT: CLIENT,
      REACT_APP_ADSENSE_AUTO_ADS: "true",
    });
    renderFor({ userMode: "vip" }, <AdsBootstrap />);
    expect(loadAdSenseMock).not.toHaveBeenCalled();
  });

  it("mirrors a declined consent onto the AdSense queue and follows changes", () => {
    window.localStorage.setItem("bt.consent", "denied");
    setEnv({ REACT_APP_ADSENSE_CLIENT: CLIENT });
    renderFor(null, <AdsBootstrap />);
    expect((window as any).adsbygoogle.requestNonPersonalizedAds).toBe(1);
    writeConsent("granted");
    expect((window as any).adsbygoogle.requestNonPersonalizedAds).toBe(0);
  });

  it("stops following consent once unmounted", () => {
    window.localStorage.setItem("bt.consent", "denied");
    setEnv({ REACT_APP_ADSENSE_CLIENT: CLIENT });
    const { unmount } = renderFor(null, <AdsBootstrap />);
    unmount();
    delete (window as any).adsbygoogle;
    writeConsent("granted");
    expect((window as any).adsbygoogle).toBeUndefined();
  });

  it("touches nothing without a client id", () => {
    window.localStorage.setItem("bt.consent", "denied");
    setEnv({});
    renderFor(null, <AdsBootstrap />);
    expect((window as any).adsbygoogle).toBeUndefined();
  });
});
