import "@testing-library/jest-dom";
import { render, screen, fireEvent } from "@testing-library/react";
import Avatar from "./Avatar";

it("renders the image when a src is given", () => {
  render(<Avatar src="https://example.test/a.jpg" name="Yeonwoo" />);
  expect(screen.getByTestId("avatar-image")).toHaveAttribute(
    "src",
    "https://example.test/a.jpg"
  );
  expect(screen.queryByTestId("avatar-initials")).not.toBeInTheDocument();
});

// The behaviour two of the three current implementations forgot.
it("falls back to an initial when there is no photo", () => {
  render(<Avatar name="yeonwoo" />);
  expect(screen.getByTestId("avatar-initials")).toHaveTextContent("Y");
  expect(screen.queryByTestId("avatar-image")).not.toBeInTheDocument();
});

it("renders a placeholder initial for a nameless user", () => {
  render(<Avatar name="" />);
  expect(screen.getByTestId("avatar-initials")).toHaveTextContent("?");
});

it("renders a placeholder initial for a whitespace-only name", () => {
  render(<Avatar name="   " />);
  expect(screen.getByTestId("avatar-initials")).toHaveTextContent("?");
});

it("shows the story ring only when hasStory is true", () => {
  const { rerender } = render(<Avatar name="Yeonwoo" />);
  expect(screen.queryByTestId("avatar-story-ring")).not.toBeInTheDocument();

  rerender(<Avatar name="Yeonwoo" hasStory />);
  expect(screen.getByTestId("avatar-story-ring")).toBeInTheDocument();
  expect(screen.getByTestId("avatar-initials")).toBeInTheDocument();
});

it("shows the online dot only when isOnline is true", () => {
  const { rerender } = render(<Avatar name="Yeonwoo" />);
  expect(screen.queryByTestId("avatar-online-dot")).not.toBeInTheDocument();

  rerender(<Avatar name="Yeonwoo" isOnline />);
  expect(screen.getByTestId("avatar-online-dot")).toBeInTheDocument();
});

it("shows the flag only when one is given", () => {
  const { rerender } = render(<Avatar name="Yeonwoo" />);
  expect(screen.queryByTestId("avatar-flag")).not.toBeInTheDocument();

  rerender(<Avatar name="Yeonwoo" flag="🇰🇷" />);
  expect(screen.getByTestId("avatar-flag")).toHaveTextContent("🇰🇷");
});

it("applies the requested size", () => {
  render(<Avatar name="Yeonwoo" size={72} />);
  expect(screen.getByTestId("avatar")).toHaveStyle({ width: "72px", height: "72px" });
});

it("gives the initials fallback an accessible name", () => {
  render(<Avatar name="Yeonwoo" />);
  const el = screen.getByTestId("avatar-initials");
  expect(el).toHaveAttribute("role", "img");
  expect(el).toHaveAttribute("aria-label", "Yeonwoo");
});

it("falls back to a sensible accessible name when there is no name", () => {
  render(<Avatar name="" />);
  const el = screen.getByTestId("avatar-initials");
  expect(el).toHaveAttribute("role", "img");
  expect(el.getAttribute("aria-label")).toBeTruthy();
});

it("gives the online dot an img role so its aria-label is announced", () => {
  render(<Avatar name="Yeonwoo" isOnline />);
  expect(screen.getByTestId("avatar-online-dot")).toHaveAttribute("role", "img");
});

// Dark mode swaps the story ring's inner surface rather than the ring itself.
it("carries a dark-mode surface variant on the story ring", () => {
  render(<Avatar name="Yeonwoo" hasStory />);
  expect(screen.getByTestId("avatar-story-ring").firstChild).toHaveClass(
    "dark:bg-cardbg-dark"
  );
});

// A profile picture that cannot be opened is a dead control: people tap it
// expecting to see the photo. Only when a caller supplies a handler — the
// avatar is decoration in a list row, and a button there would be noise.
describe("Avatar as a control", () => {
  it("stays plain decoration when no handler is given", () => {
    render(<Avatar name="Ada" src="a.jpg" />);
    expect(screen.queryByRole("button")).not.toBeInTheDocument();
  });

  it("becomes a real button when one is", () => {
    const onClick = jest.fn();
    render(<Avatar name="Ada" src="a.jpg" onClick={onClick} label="Open Ada's photo" />);

    const button = screen.getByRole("button", { name: "Open Ada's photo" });
    fireEvent.click(button);
    expect(onClick).toHaveBeenCalledTimes(1);
  });

  it("answers the keyboard by being a real button, not a div with a handler", () => {
    // jsdom does not synthesise a click from Enter, so asserting that would
    // test the harness. What delivers keyboard support is the element itself:
    // a native button is focusable and activates on Enter and Space for free,
    // which a div with onClick never does.
    const onClick = jest.fn();
    render(<Avatar name="Ada" src="a.jpg" onClick={onClick} label="Open Ada's photo" />);

    const button = screen.getByRole("button");
    expect(button.tagName).toBe("BUTTON");
    expect(button).toHaveAttribute("type", "button");
    button.focus();
    expect(button).toHaveFocus();
  });
});

// Avatar is the shared face across eight surfaces -- the stories rail, the
// viewers sheet, chat's info panel, the connections list, the profile header.
// Its <img> carried no loading hint, no decoding hint and no dimensions, so
// every list of people fired a burst of eager, unsized requests.
describe("Avatar image loading", () => {
  it("reserves a box from the size it already knows", () => {
    render(<Avatar name="Ada" src="a.jpg" size={54} />);
    const img = screen.getByTestId("avatar-image");

    expect(img).toHaveAttribute("width", "54");
    expect(img).toHaveAttribute("height", "54");
    expect(img).toHaveAttribute("decoding", "async");
  });

  it("is lazy by default, because most of them are in a list", () => {
    render(<Avatar name="Ada" src="a.jpg" />);
    expect(screen.getByTestId("avatar-image")).toHaveAttribute("loading", "lazy");
  });

  it("can be told to load eagerly, for the one above the fold", () => {
    // The profile header's avatar is the page's main subject; deferring it
    // would be the wrong trade.
    render(<Avatar name="Ada" src="a.jpg" size={80} priority />);
    expect(screen.getByTestId("avatar-image")).toHaveAttribute("loading", "eager");
  });
});
