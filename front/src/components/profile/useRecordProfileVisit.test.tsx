import "@testing-library/jest-dom";
import React from "react";
import { render, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import useRecordProfileVisit from "./useRecordProfileVisit";

const mockRecord = jest.fn();

jest.mock("../../store/slices/usersSlice", () => ({
  useRecordProfileVisitMutation: () => [mockRecord, { isLoading: false }],
}));

const resolved = () => ({ unwrap: () => Promise.resolve({ success: true }) });
const rejected = () => ({ unwrap: () => Promise.reject(new Error("nope")) });

interface ProbeProps {
  profileId: string;
  isOwn?: boolean;
}

/** The hook renders nothing; a bare probe is enough to mount it. */
const Probe: React.FC<ProbeProps> = ({ profileId, isOwn }) => {
  useRecordProfileVisit(profileId, Boolean(isOwn));
  return <div data-testid="probe" />;
};

function renderProbe(props: ProbeProps, viewerId: string | null = "me") {
  const store = configureStore({
    reducer: {
      auth: (state: any = { userInfo: viewerId ? { user: { _id: viewerId } } : null }) =>
        state,
    },
  });
  const view = render(
    <Provider store={store}>
      <Probe {...props} />
    </Provider>
  );
  return { ...view, rerenderWith: (next: ProbeProps) =>
    view.rerender(
      <Provider store={store}>
        <Probe {...next} />
      </Provider>
    ),
  };
}

beforeEach(() => {
  jest.clearAllMocks();
  mockRecord.mockReturnValue(resolved());
});

describe("useRecordProfileVisit", () => {
  it("records the visit when a signed-in viewer opens someone else's profile", async () => {
    renderProbe({ profileId: "u2" });
    await waitFor(() => expect(mockRecord).toHaveBeenCalledWith("u2"));
  });

  it("records once per profile, not once per render", async () => {
    const { rerenderWith } = renderProbe({ profileId: "u2" });
    await waitFor(() => expect(mockRecord).toHaveBeenCalledTimes(1));
    rerenderWith({ profileId: "u2" });
    rerenderWith({ profileId: "u2" });
    expect(mockRecord).toHaveBeenCalledTimes(1);
  });

  it("records again when the viewer moves to a different profile", async () => {
    // /community/:a -> /community/:b changes a route param, so the page never
    // unmounts. A ref that only guarded "already fired" would miss the second
    // person entirely.
    const { rerenderWith } = renderProbe({ profileId: "u2" });
    await waitFor(() => expect(mockRecord).toHaveBeenCalledTimes(1));
    rerenderWith({ profileId: "u3" });
    await waitFor(() => expect(mockRecord).toHaveBeenCalledTimes(2));
    expect(mockRecord).toHaveBeenLastCalledWith("u3");
  });

  it("stays quiet on the viewer's own profile", () => {
    renderProbe({ profileId: "me", isOwn: true });
    expect(mockRecord).not.toHaveBeenCalled();
  });

  it("stays quiet when nobody is signed in", () => {
    // /profile/:userId is public. There is no visitor to attribute, and the
    // endpoint is behind `protect`, so firing it would only earn a 401.
    renderProbe({ profileId: "u2" }, null);
    expect(mockRecord).not.toHaveBeenCalled();
  });

  it("stays quiet until the profile id is known", async () => {
    const { rerenderWith } = renderProbe({ profileId: "" });
    expect(mockRecord).not.toHaveBeenCalled();
    rerenderWith({ profileId: "u2" });
    await waitFor(() => expect(mockRecord).toHaveBeenCalledWith("u2"));
  });

  it("swallows a rejection — a visit nobody asked for must not surface", async () => {
    mockRecord.mockReturnValue(rejected());
    renderProbe({ profileId: "u2" });
    await waitFor(() => expect(mockRecord).toHaveBeenCalled());
    // Reaching here without an unhandled rejection is the assertion.
  });
});
