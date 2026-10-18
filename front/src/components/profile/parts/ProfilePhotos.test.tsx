import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import ProfilePhotos from "./ProfilePhotos";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

const IMAGES = [
  "https://cdn.test/one.jpg",
  "https://cdn.test/two.jpg",
  "https://cdn.test/three.jpg",
];

function renderPhotos(props: any = {}) {
  return render(
    <MemoryRouter>
      <ProfilePhotos images={IMAGES} isOwn={false} name="Ada" {...props} />
    </MemoryRouter>
  );
}

it("renders one tile per photo", () => {
  renderPhotos();
  expect(screen.getAllByTestId("photo-tile")).toHaveLength(3);
  expect(screen.getAllByTestId("photo-tile-image")[1]).toHaveAttribute(
    "src",
    "https://cdn.test/two.jpg"
  );
});

it("names each tile once — on the button, with the image decorative", () => {
  renderPhotos();
  // A described image inside an aria-labelled button is read twice.
  expect(screen.getAllByTestId("photo-tile-image")[0]).toHaveAttribute("alt", "");
  expect(screen.getAllByTestId("photo-tile")[0].getAttribute("aria-label")).toBeTruthy();
});

it("names the lightbox image, where it is the only accessible name", () => {
  renderPhotos();
  fireEvent.click(screen.getAllByTestId("photo-tile")[1]);
  expect(
    screen.getByTestId("photo-lightbox-image").getAttribute("alt")
  ).toBeTruthy();
});

it("locks the page behind the lightbox and gives the scroll back on close", () => {
  renderPhotos();
  fireEvent.click(screen.getAllByTestId("photo-tile")[0]);
  expect(document.body.style.overflow).toBe("hidden");
  fireEvent.keyDown(document, { key: "Escape" });
  expect(document.body.style.overflow).not.toBe("hidden");
});

it("renders nothing at all when there are no photos", () => {
  const { container } = renderPhotos({ images: [] });
  expect(container).toBeEmptyDOMElement();
});

it("drops blank and non-string entries rather than rendering broken tiles", () => {
  renderPhotos({ images: ["https://cdn.test/one.jpg", "", "   ", null, 7] });
  expect(screen.getAllByTestId("photo-tile")).toHaveLength(1);
});

it("offers Add photos to the owner only, linking to the editor", () => {
  const { unmount } = renderPhotos({ isOwn: true });
  expect(screen.getByTestId("photos-add")).toHaveAttribute("href", "/profile/edit");
  unmount();

  renderPhotos({ isOwn: false });
  expect(screen.queryByTestId("photos-add")).not.toBeInTheDocument();
});

it("opens the lightbox on the photo that was clicked", () => {
  renderPhotos();
  expect(screen.queryByTestId("photo-lightbox")).not.toBeInTheDocument();

  fireEvent.click(screen.getAllByTestId("photo-tile")[1]);
  const lightbox = screen.getByTestId("photo-lightbox");
  expect(lightbox).toHaveAttribute("aria-modal", "true");
  expect(screen.getByTestId("photo-lightbox-image")).toHaveAttribute(
    "src",
    "https://cdn.test/two.jpg"
  );
  expect(screen.getByTestId("photo-lightbox-counter")).toHaveTextContent("2");
  expect(screen.getByTestId("photo-lightbox-counter")).toHaveTextContent("3");
});

it("closes on Escape, on the close button and on the backdrop", () => {
  renderPhotos();

  fireEvent.click(screen.getAllByTestId("photo-tile")[0]);
  fireEvent.keyDown(document, { key: "Escape" });
  expect(screen.queryByTestId("photo-lightbox")).not.toBeInTheDocument();

  fireEvent.click(screen.getAllByTestId("photo-tile")[0]);
  fireEvent.click(screen.getByTestId("photo-lightbox-close"));
  expect(screen.queryByTestId("photo-lightbox")).not.toBeInTheDocument();

  fireEvent.click(screen.getAllByTestId("photo-tile")[0]);
  fireEvent.click(screen.getByTestId("photo-lightbox-backdrop"));
  expect(screen.queryByTestId("photo-lightbox")).not.toBeInTheDocument();
});

it("walks the photos with the arrow keys, wrapping at both ends", () => {
  renderPhotos();
  fireEvent.click(screen.getAllByTestId("photo-tile")[0]);

  fireEvent.keyDown(document, { key: "ArrowRight" });
  expect(screen.getByTestId("photo-lightbox-image")).toHaveAttribute(
    "src",
    "https://cdn.test/two.jpg"
  );

  fireEvent.keyDown(document, { key: "ArrowLeft" });
  fireEvent.keyDown(document, { key: "ArrowLeft" });
  expect(screen.getByTestId("photo-lightbox-image")).toHaveAttribute(
    "src",
    "https://cdn.test/three.jpg"
  );

  fireEvent.keyDown(document, { key: "ArrowRight" });
  expect(screen.getByTestId("photo-lightbox-image")).toHaveAttribute(
    "src",
    "https://cdn.test/one.jpg"
  );
});

it("walks the photos with the previous and next buttons", () => {
  renderPhotos();
  fireEvent.click(screen.getAllByTestId("photo-tile")[0]);

  fireEvent.click(screen.getByTestId("photo-lightbox-next"));
  expect(screen.getByTestId("photo-lightbox-counter")).toHaveTextContent("2");

  fireEvent.click(screen.getByTestId("photo-lightbox-prev"));
  expect(screen.getByTestId("photo-lightbox-counter")).toHaveTextContent("1");
});

it("hides the navigation entirely for a single photo", () => {
  renderPhotos({ images: ["https://cdn.test/one.jpg"] });
  fireEvent.click(screen.getAllByTestId("photo-tile")[0]);
  expect(screen.queryByTestId("photo-lightbox-next")).not.toBeInTheDocument();
  expect(screen.queryByTestId("photo-lightbox-prev")).not.toBeInTheDocument();
});

it("moves focus into the dialog and traps Tab inside it", () => {
  renderPhotos();
  fireEvent.click(screen.getAllByTestId("photo-tile")[0]);

  const close = screen.getByTestId("photo-lightbox-close");
  expect(document.activeElement).toBe(close);

  // Tab off the last control wraps to the first, and Shift+Tab off the first
  // wraps to the last — nothing outside the dialog can be reached.
  const next = screen.getByTestId("photo-lightbox-next");
  next.focus();
  fireEvent.keyDown(next, { key: "Tab" });
  expect(document.activeElement).toBe(close);

  fireEvent.keyDown(close, { key: "Tab", shiftKey: true });
  expect(document.activeElement).toBe(next);
});

it("restores focus to the tile that opened the lightbox", () => {
  renderPhotos();
  const tile = screen.getAllByTestId("photo-tile")[2];
  tile.focus();
  fireEvent.click(tile);
  fireEvent.keyDown(document, { key: "Escape" });
  expect(document.activeElement).toBe(tile);
});

it("draws its controls with icons, never emoji", () => {
  const { container } = renderPhotos({ isOwn: true });
  fireEvent.click(screen.getAllByTestId("photo-tile")[0]);
  expect(container.querySelectorAll("svg").length).toBeGreaterThan(0);
  expect(document.body.textContent).not.toMatch(
    /[\u{1F300}-\u{1FAFF}\u{2190}-\u{21FF}\u{2700}-\u{27BF}]/u
  );
});

// The tiles are how someone decides whether to open the viewer at all. At
// three per row a phone gives each about 110px, which is too small to read a
// face in. Two per row is ~165px; a desktop keeps three, where the column is
// wide enough for them.
it("shows two tiles per row on a phone and three above it", () => {
  const { container } = renderPhotos();
  const list = container.querySelector("ul") as HTMLElement;

  expect(list.className).toContain("grid-cols-2");
  expect(list.className).toContain("sm:grid-cols-3");
});
