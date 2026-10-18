/**
 * `linkDetector` was dead code the chat never imported, and it showed: the
 * module-level `/g` regexes carried `lastIndex` between calls, so the same
 * text answered `true` then `false` from `hasLinks`. Now that a message bubble
 * renders a card for the first link in a message, the detector is on the hot
 * path and every one of these cases is something a person types.
 */
import { firstLink } from "./linkDetector";

describe("firstLink", () => {
  it("finds a full https URL", () => {
    const link = firstLink("look at https://example.com/posts/7 please");
    expect(link).not.toBeNull();
    expect(link!.url).toBe("https://example.com/posts/7");
    expect(link!.text).toBe("https://example.com/posts/7");
    expect(link!.host).toBe("example.com");
  });

  it("gives a scheme-less www address one to open with", () => {
    const link = firstLink("www.example.com is the place");
    expect(link!.url).toBe("https://www.example.com");
    expect(link!.text).toBe("www.example.com");
    expect(link!.host).toBe("example.com");
  });

  it("finds a bare domain with a path", () => {
    const link = firstLink("read bananatalk.app/blog/hello today");
    expect(link!.url).toBe("https://bananatalk.app/blog/hello");
    expect(link!.host).toBe("bananatalk.app");
  });

  it("leaves the sentence's full stop out of the link", () => {
    const link = firstLink("It is at https://example.com/page.");
    expect(link!.url).toBe("https://example.com/page");
    expect(link!.text).toBe("https://example.com/page");
  });

  it("drops a closing bracket the URL never opened", () => {
    const link = firstLink("(see https://en.wikipedia.org/wiki/Kimchi)");
    expect(link!.url).toBe("https://en.wikipedia.org/wiki/Kimchi");
  });

  it("keeps a bracket pair that belongs to the URL", () => {
    const link = firstLink("https://en.wikipedia.org/wiki/Kimchi_(food)");
    expect(link!.url).toBe("https://en.wikipedia.org/wiki/Kimchi_(food)");
  });

  it("returns the first of several", () => {
    const link = firstLink("https://one.com and https://two.com");
    expect(link!.url).toBe("https://one.com");
  });

  it("is null for a message with no link", () => {
    expect(firstLink("no links here, just words.")).toBeNull();
    expect(firstLink("")).toBeNull();
  });

  it("does not turn an email address into a link card", () => {
    expect(firstLink("write to ada@example.com")).toBeNull();
  });

  // A link has to START somewhere: after whitespace or an opening bracket, or
  // at the start of the message. The old check asked the opposite question
  // with an ASCII-only class, so a non-ASCII letter read as a boundary and the
  // card pointed at a domain that was not the one in the message.
  it("never cards a truncated host after an accented letter", () => {
    expect(firstLink("besuche m\u00fcnchen.de heute")).toBeNull();
    expect(firstLink("Gr\u00fc\u00dfe.com")).toBeNull();
  });

  it("finds a link right after an opening bracket or a quote", () => {
    expect(firstLink('he said "https://example.com/x" loudly')!.url).toBe(
      "https://example.com/x"
    );
    expect(firstLink("[https://example.com]")!.url).toBe("https://example.com");
  });

  it("answers the same way every time it is asked", () => {
    const text = "see https://example.com/x";
    expect(firstLink(text)!.url).toBe("https://example.com/x");
    expect(firstLink(text)!.url).toBe("https://example.com/x");
    expect(firstLink(text)!.url).toBe("https://example.com/x");
  });

  it("ignores a sentence whose words happen to touch a full stop", () => {
    expect(firstLink("I went.Then I came back")).toBeNull();
  });
});
