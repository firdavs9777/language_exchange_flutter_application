import "@testing-library/jest-dom";
import { render } from "@testing-library/react";
import { renderWithMentions } from "./mentionText";

const html = (nodes: any) => render(<p>{nodes}</p>).container.querySelector("p")!;

it("highlights each mention by offset and length, keeping the rest as text", () => {
  const p = html(renderWithMentions("hi @ann and @bo!", [
    { user: "u2", username: "bo", offset: 12, length: 3 },
    { user: "u1", username: "ann", offset: 3, length: 4 },
  ]));
  const marks = p.querySelectorAll('[data-testid="comment-mention"]');
  expect(Array.from(marks).map((m) => m.textContent)).toEqual(["@ann", "@bo"]);
  expect(p.textContent).toBe("hi @ann and @bo!");
});

it("ignores out-of-range, negative and overlapping mentions", () => {
  const p = html(renderWithMentions("hello", [
    { offset: -1, length: 2 },
    { offset: 99, length: 2 },
    { offset: 0, length: 3 },
    { offset: 1, length: 3 },
  ]));
  expect(p.querySelectorAll('[data-testid="comment-mention"]')).toHaveLength(1);
  expect(p.textContent).toBe("hello");
});

it("no mentions is just the text", () => {
  const p = html(renderWithMentions("plain", undefined));
  expect(p.textContent).toBe("plain");
  expect(p.querySelector('[data-testid="comment-mention"]')).toBeNull();
});
