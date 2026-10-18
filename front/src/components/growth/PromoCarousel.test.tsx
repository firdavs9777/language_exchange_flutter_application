import "@testing-library/jest-dom";
import { render, screen, act, fireEvent, within } from "@testing-library/react";
import PromoCarousel from "./PromoCarousel";
import { PROMO_SLIDES, promoKey } from "../../data/promoSlides";

// Same idiom as HeroDemo.test: `mockTMode` toggles the mocked `t` between
// echoing its key (proves every string is routed through i18n) and returning
// "" the way src/utils/i18n.ts does for a missing key (proves the
// `t(key) || "English"` fallback). Must be prefixed with "mock" --
// babel-plugin-jest-hoist only allows referencing such names in the factory.
let mockTMode: "echo" | "fallback" = "fallback";
jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: (key: string) => (mockTMode === "echo" ? key : "") }),
}));

beforeEach(() => {
  mockTMode = "fallback";
  window.localStorage.clear();
  jest.useFakeTimers();
});
afterEach(() => jest.useRealTimers());

const slides = () => screen.getAllByTestId("promo-slide");
const current = () => slides().filter((s) => s.getAttribute("data-active") === "true");
const currentSlide = () => current()[0];

it("renders every slide from the data, with its eyebrow, title and body", () => {
  render(<PromoCarousel />);
  expect(slides()).toHaveLength(PROMO_SLIDES.length);
  PROMO_SLIDES.forEach((slide, i) => {
    expect(slides()[i]).toHaveTextContent(slide.eyebrow);
    expect(slides()[i]).toHaveTextContent(slide.title);
    expect(slides()[i]).toHaveTextContent(slide.body);
  });
});

// `hidden: true` because three of the four slides are aria-hidden at any
// moment; the art is still in the DOM, which is the point of mounting all four.
const arts = () => screen.getAllByRole("img", { hidden: true });

it("gives every slide an illustration announced by its own alt text", () => {
  render(<PromoCarousel />);
  const svgs = arts();
  expect(svgs).toHaveLength(PROMO_SLIDES.length);
  PROMO_SLIDES.forEach((slide, i) => {
    const svg = svgs[i];
    expect(svg.tagName.toLowerCase()).toBe("svg");
    // A viewBox and no width/height is what lets the art fill its slot at any
    // size; the label is wired through aria-labelledby, not an alt attribute.
    expect(svg).toHaveAttribute("viewBox");
    const titleId = svg.getAttribute("aria-labelledby") || "";
    expect(titleId).toBe(`promo-art-${slide.key}`);
    const title = document.getElementById(titleId);
    expect(title && title.tagName.toLowerCase()).toBe("title");
    expect(title && title.textContent).toBe(slide.alt);
  });
});

// The whole reason the screenshots went: the band is above the fold on a
// phone, and four cropped phone photos were four network requests and four
// chances to reflow. Inline SVG is neither.
it("fetches no image at all", () => {
  const { container } = render(<PromoCarousel />);
  expect(container.querySelectorAll("img")).toHaveLength(0);
  expect(container.querySelectorAll("picture")).toHaveLength(0);
  expect(container.innerHTML).not.toContain("/images/app/");
});

it("shows the first slide and a dot per slide", () => {
  render(<PromoCarousel />);
  expect(currentSlide()).toHaveTextContent(PROMO_SLIDES[0].title);
  expect(current()).toHaveLength(1);
  expect(screen.getAllByTestId("promo-dot")).toHaveLength(PROMO_SLIDES.length);
});

it("hides the slides it is not showing from assistive tech", () => {
  render(<PromoCarousel />);
  expect(currentSlide()).not.toHaveAttribute("aria-hidden", "true");
  slides()
    .filter((s) => s.getAttribute("data-active") !== "true")
    .forEach((s) => expect(s).toHaveAttribute("aria-hidden", "true"));
});

it("advances on its own", () => {
  render(<PromoCarousel />);
  act(() => { jest.advanceTimersByTime(6000); });
  expect(currentSlide()).toHaveTextContent(PROMO_SLIDES[1].title);
});

it("wraps around at the end", () => {
  render(<PromoCarousel />);
  act(() => { jest.advanceTimersByTime(6000 * PROMO_SLIDES.length); });
  expect(currentSlide()).toHaveTextContent(PROMO_SLIDES[0].title);
});

it("pauses while hovered", () => {
  render(<PromoCarousel />);
  fireEvent.mouseEnter(screen.getByTestId("promo-carousel"));
  act(() => { jest.advanceTimersByTime(12000); });
  expect(currentSlide()).toHaveTextContent(PROMO_SLIDES[0].title);
});

it("pauses while keyboard-focused on a descendant", () => {
  render(<PromoCarousel />);
  const dot = screen.getAllByTestId("promo-dot")[0];
  fireEvent.focus(dot);
  act(() => { jest.advanceTimersByTime(12000); });
  expect(currentSlide()).toHaveTextContent(PROMO_SLIDES[0].title);
  fireEvent.blur(dot);
  act(() => { jest.advanceTimersByTime(6000); });
  expect(currentSlide()).toHaveTextContent(PROMO_SLIDES[1].title);
});

it("stands still for a visitor who asked for reduced motion", () => {
  const matchMedia = jest.fn().mockReturnValue({ matches: true });
  (window as any).matchMedia = matchMedia;
  render(<PromoCarousel />);
  act(() => { jest.advanceTimersByTime(30000); });
  expect(currentSlide()).toHaveTextContent(PROMO_SLIDES[0].title);
  delete (window as any).matchMedia;
});

it("jumps to a slide when its dot is clicked", () => {
  render(<PromoCarousel />);
  fireEvent.click(screen.getAllByTestId("promo-dot")[2]);
  expect(currentSlide()).toHaveTextContent(PROMO_SLIDES[2].title);
});

it("exposes the dots as a tablist and marks the current one", () => {
  render(<PromoCarousel />);
  const tablist = screen.getByRole("tablist");
  const dots = within(tablist).getAllByRole("tab");
  expect(dots).toHaveLength(PROMO_SLIDES.length);
  expect(dots[0]).toHaveAttribute("aria-selected", "true");
  fireEvent.click(dots[2]);
  expect(dots[2]).toHaveAttribute("aria-selected", "true");
  expect(dots[0]).toHaveAttribute("aria-selected", "false");
});

// The dots say where you are; the arrows are how you move. Below 640px they
// sit on the dots' row, above it at the band's edges -- one pair of buttons
// either way, so there is one accessible name per direction.
it("steps with the visible arrows, wrapping at both ends", () => {
  render(<PromoCarousel />);
  fireEvent.click(screen.getByTestId("promo-next"));
  expect(currentSlide()).toHaveTextContent(PROMO_SLIDES[1].title);
  fireEvent.click(screen.getByTestId("promo-prev"));
  expect(currentSlide()).toHaveTextContent(PROMO_SLIDES[0].title);
  fireEvent.click(screen.getByTestId("promo-prev"));
  expect(currentSlide()).toHaveTextContent(PROMO_SLIDES[PROMO_SLIDES.length - 1].title);
  fireEvent.click(screen.getByTestId("promo-next"));
  expect(currentSlide()).toHaveTextContent(PROMO_SLIDES[0].title);
});

it("gives both arrows an accessible name, routed through i18n", () => {
  const { unmount } = render(<PromoCarousel />);
  expect(screen.getByRole("button", { name: "Previous slide" })).toBe(
    screen.getByTestId("promo-prev")
  );
  expect(screen.getByRole("button", { name: "Next slide" })).toBe(
    screen.getByTestId("promo-next")
  );
  unmount();

  mockTMode = "echo";
  render(<PromoCarousel />);
  expect(screen.getByTestId("promo-prev")).toHaveAttribute("aria-label", "growth.promo.prev");
  expect(screen.getByTestId("promo-next")).toHaveAttribute("aria-label", "growth.promo.next");
});

// Steering by hand outranks the timer, the same way hovering does -- and the
// same mouseleave hands the rotation back.
it("pauses the rotation while a visitor is stepping by hand", () => {
  render(<PromoCarousel />);
  fireEvent.click(screen.getByTestId("promo-next"));
  act(() => { jest.advanceTimersByTime(12000); });
  expect(currentSlide()).toHaveTextContent(PROMO_SLIDES[1].title);
  fireEvent.mouseLeave(screen.getByTestId("promo-carousel"));
  act(() => { jest.advanceTimersByTime(6000); });
  expect(currentSlide()).toHaveTextContent(PROMO_SLIDES[2].title);
});

it("moves with the arrow keys, wrapping at both ends", () => {
  render(<PromoCarousel />);
  const carousel = screen.getByTestId("promo-carousel");
  fireEvent.keyDown(carousel, { key: "ArrowRight" });
  expect(currentSlide()).toHaveTextContent(PROMO_SLIDES[1].title);
  fireEvent.keyDown(carousel, { key: "ArrowLeft" });
  expect(currentSlide()).toHaveTextContent(PROMO_SLIDES[0].title);
  fireEvent.keyDown(carousel, { key: "ArrowLeft" });
  expect(currentSlide()).toHaveTextContent(PROMO_SLIDES[PROMO_SLIDES.length - 1].title);
});

it("disappears when dismissed, and stays gone on remount", () => {
  const { unmount } = render(<PromoCarousel />);
  fireEvent.click(screen.getByTestId("promo-dismiss"));
  expect(screen.queryByTestId("promo-carousel")).not.toBeInTheDocument();
  unmount();
  render(<PromoCarousel />);
  expect(screen.queryByTestId("promo-carousel")).not.toBeInTheDocument();
});

// Both stores on a real screen, where we cannot know which one the visitor
// wants; one "get the app" button below 640px, where /download makes the hop.
it("offers both stores, tagged as the promo carousel", () => {
  render(<PromoCarousel />);
  const links = screen.getAllByTestId(/^store-link-/);
  expect(links.filter((a) => a.getAttribute("data-testid") === "store-link-ios")).toHaveLength(
    PROMO_SLIDES.length
  );
  links.forEach((a) =>
    expect(a.getAttribute("href")).toContain("utm_campaign=promo-carousel")
  );
});

// A slide that says "get the app" means the store, not a page about the store:
// `go=1` is what DownloadApp reads to make the hop (spec 5.3).
it("sends the compact CTA to the download page with the redirect flag", () => {
  render(<PromoCarousel />);
  const ctas = screen.getAllByTestId("promo-cta");
  expect(ctas).toHaveLength(PROMO_SLIDES.length);
  ctas.forEach((a, i) => {
    expect(a).toHaveAttribute("href", "/download?go=1");
    expect(a).toHaveTextContent(PROMO_SLIDES[i].cta);
  });
});

// Every visible string is a translation key with an English fallback, so the
// 18 locales can pick this up without the component changing again.
it("routes every slide string through i18n", () => {
  mockTMode = "echo";
  render(<PromoCarousel />);
  PROMO_SLIDES.forEach((slide, i) => {
    const el = slides()[i];
    ["eyebrow", "title", "body", "cta"].forEach((field) =>
      expect(el).toHaveTextContent(promoKey(slide.key, field))
    );
    const titleId = within(el).getByRole("img", { hidden: true }).getAttribute("aria-labelledby") || "";
    expect(document.getElementById(titleId)!.textContent).toBe(promoKey(slide.key, "alt"));
  });
});

it("carries no emoji and no inline colour", () => {
  const { container } = render(<PromoCarousel />);
  expect(container.innerHTML).not.toMatch(/style="[^"]*#[0-9a-f]{3}/i);
  expect(container.textContent || "").not.toMatch(
    /[\u{1F300}-\u{1FAFF}\u{2700}-\u{27BF}]/u
  );
});
