import "@testing-library/jest-dom";
import React, { useState } from "react";
import { render, screen, fireEvent, act } from "@testing-library/react";
import ReelViewer, { _resetReelMuteForTests } from "./ReelViewer";

const mockViewRef = jest.fn();
jest.mock("../moments/useMomentViews", () => ({
  useMomentViews: (args: any) => {
    mockViewRef(args.momentId);
    return () => {};
  },
}));
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

const reel = (id: string) => ({
  id, description: "about " + id, language: "ko", likeCount: 0, commentCount: 0, shareCount: 0, isLiked: false,
  createdAt: "", videoUrl: `https://cdn.test/${id}.mp4`, thumbnail: null, duration: null, portrait: true,
  author: { id: "u", name: "Mina", avatar: undefined },
});
const REELS = ["a", "b", "c", "d", "e"].map(reel);

let playMock: jest.Mock;
beforeEach(() => {
  _resetReelMuteForTests();
  playMock = jest.fn().mockResolvedValue(undefined);
  window.HTMLMediaElement.prototype.play = playMock;
  window.HTMLMediaElement.prototype.pause = jest.fn();
  mockViewRef.mockClear();
});

function Harness(props: any) {
  const [index, setIndex] = useState(props.start || 0);
  return (
    <ReelViewer
      reels={props.reels || REELS}
      index={index}
      hasMore={!!props.hasMore}
      onIndexChange={setIndex}
      onNeedMore={props.onNeedMore || jest.fn()}
      onClose={props.onClose || jest.fn()}
    />
  );
}
const current = () => (screen.getByTestId("reel-viewer").querySelector("[data-testid^='reel-slide-']") as HTMLElement).dataset.testid;

it("plays exactly one video, muted, and records a view for it", async () => {
  await act(async () => {
    render(<Harness start={1} />);
  });
  expect(current()).toBe("reel-slide-b");
  const videos = screen.getByTestId("reel-viewer").querySelectorAll("video");
  expect(videos).toHaveLength(1);
  expect((videos[0] as HTMLVideoElement).muted).toBe(true);
  expect(videos[0]).toHaveAttribute("src", "https://cdn.test/b.mp4");
  expect(playMock).toHaveBeenCalled();
  expect(mockViewRef).toHaveBeenCalledWith("b");
});

it("moves with the arrow keys and closes on Escape", async () => {
  const onClose = jest.fn();
  await act(async () => {
    render(<Harness onClose={onClose} />);
  });
  fireEvent.keyDown(window, { key: "ArrowUp" });
  expect(current()).toBe("reel-slide-a");
  fireEvent.keyDown(window, { key: "ArrowDown" });
  expect(current()).toBe("reel-slide-b");
  fireEvent.keyDown(window, { key: "Escape" });
  expect(onClose).toHaveBeenCalled();
});

it("moves once per wheel gesture, and on a vertical swipe", async () => {
  const now = jest.spyOn(Date, "now");
  now.mockReturnValue(1000);
  await act(async () => {
    render(<Harness />);
  });
  const viewer = screen.getByTestId("reel-viewer");
  fireEvent.wheel(viewer, { deltaY: 120 });
  fireEvent.wheel(viewer, { deltaY: 120 }); // same gesture: ignored
  expect(current()).toBe("reel-slide-b");
  now.mockReturnValue(2000);
  fireEvent.wheel(viewer, { deltaY: -120 });
  expect(current()).toBe("reel-slide-a");
  fireEvent.touchStart(viewer, { touches: [{ clientY: 500 }] });
  fireEvent.touchEnd(viewer, { changedTouches: [{ clientY: 380 }] });
  expect(current()).toBe("reel-slide-b");
  now.mockRestore();
});

it("asks for the next page three reels from the end", async () => {
  const onNeedMore = jest.fn();
  await act(async () => {
    render(<Harness start={1} hasMore onNeedMore={onNeedMore} />);
  });
  expect(onNeedMore).not.toHaveBeenCalled();
  fireEvent.keyDown(window, { key: "ArrowDown" }); // index 2 = length - 3
  expect(onNeedMore).toHaveBeenCalled();
});

it("unmutes on request and keeps the choice for the next reel", async () => {
  await act(async () => {
    render(<Harness />);
  });
  fireEvent.click(screen.getByTestId("reel-mute"));
  expect((screen.getByTestId("reel-video") as HTMLVideoElement).muted).toBe(false);
  fireEvent.keyDown(window, { key: "ArrowDown" });
  expect((screen.getByTestId("reel-video") as HTMLVideoElement).muted).toBe(false);
});

it("shows a tap-to-play button when the browser refuses autoplay", async () => {
  playMock.mockRejectedValueOnce(Object.assign(new Error("blocked"), { name: "NotAllowedError" }));
  await act(async () => {
    render(<Harness />);
  });
  const tap = screen.getByTestId("reel-tap-to-play");
  await act(async () => {
    fireEvent.click(tap);
  });
  expect(playMock).toHaveBeenCalledTimes(2);
  expect(screen.queryByTestId("reel-tap-to-play")).not.toBeInTheDocument();
});
