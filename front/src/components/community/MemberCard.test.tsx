import React from "react";
import "@testing-library/jest-dom";
import { render, screen, fireEvent } from "@testing-library/react";
import MemberCard, { CommunityMemberCard } from "./MemberCard";

const baseUser: CommunityMemberCard = {
  _id: "user-1",
  name: "Alice",
  bio: "Love hiking and coffee",
  native_language: "English",
  language_to_learn: "Korean",
  imageUrls: ["https://example.com/alice.jpg"],
  birth_year: "1996",
  gender: "female",
  createdAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(), // 30 days ago
  isVIP: true,
  languageLevel: "B2",
  location: { city: "Seoul", country: "South Korea" },
  lastActive: new Date().toISOString(),
  hasActiveStory: false,
  isOnline: true,
  followersCount: 12,
};

describe("MemberCard", () => {
  it("renders VIP badge, CEFR level, name, and online dot for a fixture user", () => {
    render(<MemberCard user={baseUser} onWave={jest.fn()} onOpen={jest.fn()} />);

    expect(screen.getByTestId("member-card-name")).toHaveTextContent("Alice");
    expect(screen.getByText("B2")).toBeInTheDocument();
    expect(screen.getByTestId("member-card-vip-badge")).toBeInTheDocument();
    expect(screen.getByTestId("member-card-online-dot")).toBeInTheDocument();
  });

  it("renders a story ring when hasActiveStory is true", () => {
    render(
      <MemberCard
        user={{ ...baseUser, hasActiveStory: true }}
        onWave={jest.fn()}
        onOpen={jest.fn()}
      />
    );

    expect(screen.getByTestId("member-card-story-ring")).toBeInTheDocument();
  });

  it("does not render a story ring when hasActiveStory is false", () => {
    render(
      <MemberCard
        user={{ ...baseUser, hasActiveStory: false }}
        onWave={jest.fn()}
        onOpen={jest.fn()}
      />
    );

    expect(screen.queryByTestId("member-card-story-ring")).not.toBeInTheDocument();
  });

  it("does not render an online dot when isOnline is false", () => {
    render(
      <MemberCard
        user={{ ...baseUser, isOnline: false }}
        onWave={jest.fn()}
        onOpen={jest.fn()}
      />
    );

    expect(screen.queryByTestId("member-card-online-dot")).not.toBeInTheDocument();
  });

  it("calls onWave (and not onOpen) when the wave button is clicked", () => {
    const onWave = jest.fn();
    const onOpen = jest.fn();
    render(<MemberCard user={baseUser} onWave={onWave} onOpen={onOpen} />);

    fireEvent.click(screen.getByTestId("member-card-wave"));

    expect(onWave).toHaveBeenCalledWith(baseUser);
    expect(onOpen).not.toHaveBeenCalled();
  });

  it("calls onOpen when the card body is clicked", () => {
    const onOpen = jest.fn();
    render(<MemberCard user={baseUser} onWave={jest.fn()} onOpen={onOpen} />);

    fireEvent.click(screen.getByTestId("member-card-root"));

    expect(onOpen).toHaveBeenCalledWith(baseUser);
  });

  it("shows NEW badge for a recently created user", () => {
    render(<MemberCard user={baseUser} onWave={jest.fn()} onOpen={jest.fn()} />);
    // baseUser.createdAt is 30 days ago -> no NEW badge
    expect(screen.queryByTestId("member-card-new-badge")).not.toBeInTheDocument();
  });

  it("shows NEW badge when createdAt is within 7 days", () => {
    render(
      <MemberCard
        user={{ ...baseUser, createdAt: new Date().toISOString() }}
        onWave={jest.fn()}
        onOpen={jest.fn()}
      />
    );
    expect(screen.getByTestId("member-card-new-badge")).toBeInTheDocument();
  });

  it("shows NEW badge when isNew flag is true regardless of createdAt", () => {
    render(
      <MemberCard
        user={{ ...baseUser, isNew: true }}
        onWave={jest.fn()}
        onOpen={jest.fn()}
      />
    );
    expect(screen.getByTestId("member-card-new-badge")).toBeInTheDocument();
  });

  it("degrades gracefully when optional fields are absent", () => {
    const minimalUser: CommunityMemberCard = {
      _id: "user-2",
      name: "Bob",
      bio: "",
      native_language: "French",
      language_to_learn: "Spanish",
      imageUrls: [],
    };

    render(<MemberCard user={minimalUser} onWave={jest.fn()} onOpen={jest.fn()} />);

    expect(screen.getByText("Bob")).toBeInTheDocument();
    expect(screen.queryByTestId("member-card-vip-badge")).not.toBeInTheDocument();
    expect(screen.queryByTestId("member-card-online-dot")).not.toBeInTheDocument();
    expect(screen.queryByTestId("member-card-story-ring")).not.toBeInTheDocument();
    expect(screen.queryByTestId("member-card-new-badge")).not.toBeInTheDocument();
    expect(screen.queryByTestId("member-card-location")).not.toBeInTheDocument();
    expect(screen.queryByTestId("member-card-level-badge")).not.toBeInTheDocument();
  });

  it("renders location when present", () => {
    render(<MemberCard user={baseUser} onWave={jest.fn()} onOpen={jest.fn()} />);
    expect(screen.getByTestId("member-card-location")).toHaveTextContent("Seoul");
    expect(screen.getByTestId("member-card-location")).toHaveTextContent("South Korea");
  });

  // The card is the row's primary control. Before this it was a bare
  // <div onClick>, so the member list and the suggestion strip on a profile
  // were reachable by pointer only.
  it("is reachable and operable from the keyboard", () => {
    const onOpen = jest.fn();
    render(<MemberCard user={baseUser} onWave={jest.fn()} onOpen={onOpen} />);

    const card = screen.getByTestId("member-card-root");
    expect(card).toHaveAttribute("role", "button");
    expect(card).toHaveAttribute("tabindex", "0");

    fireEvent.keyDown(card, { key: "Enter" });
    expect(onOpen).toHaveBeenCalledWith(baseUser);

    fireEvent.keyDown(card, { key: " " });
    expect(onOpen).toHaveBeenCalledTimes(2);
  });

  it("ignores other keys, and keys pressed on the wave button inside it", () => {
    const onOpen = jest.fn();
    render(<MemberCard user={baseUser} onWave={jest.fn()} onOpen={onOpen} />);

    fireEvent.keyDown(screen.getByTestId("member-card-root"), { key: "a" });
    // A key pressed on the nested button bubbles to the card; opening the
    // profile from it would be the wrong answer to "wave at Alice".
    fireEvent.keyDown(screen.getByTestId("member-card-wave"), { key: "Enter" });

    expect(onOpen).not.toHaveBeenCalled();
  });

  it("renders the age from birth_year", () => {
    render(<MemberCard user={baseUser} onWave={jest.fn()} onOpen={jest.fn()} />);
    const currentYear = new Date().getFullYear();
    const expectedAge = currentYear - 1996;
    expect(screen.getByTestId("member-card-name")).toHaveTextContent(`, ${expectedAge}`);
  });

  it("stacks the card: photo above the details, not beside them", () => {
    const { container } = render(
      <MemberCard user={baseUser} onWave={jest.fn()} onOpen={jest.fn()} />
    );
    const root = screen.getByTestId("member-card-root");
    expect(root.className).toContain("flex-col");
    expect(root.className).not.toContain("items-center");
    expect(container.querySelector("[data-testid='member-card-photo']")).toBeInTheDocument();
  });

  it("gives the photo a reserved 16:10 box so the grid does not reflow", () => {
    render(<MemberCard user={baseUser} onWave={jest.fn()} onOpen={jest.fn()} />);
    const img = screen.getByAltText("Alice") as HTMLImageElement;
    expect(img).toHaveAttribute("width", "320");
    expect(img).toHaveAttribute("height", "200");
    expect(img).toHaveAttribute("loading", "lazy");
    expect(img).toHaveAttribute("decoding", "async");
  });

  it("fills the photo box with an initial when the member has no picture", () => {
    render(
      <MemberCard user={{ ...baseUser, imageUrls: [] }} onWave={jest.fn()} onOpen={jest.fn()} />
    );
    const placeholder = screen.getByTestId("member-card-photo-placeholder");
    expect(placeholder).toHaveTextContent("A");
    expect(placeholder.className).toContain("w-full");
    expect(placeholder.className).toContain("h-full");
  });

  it("falls back to a placeholder mark when the member has no name either", () => {
    render(
      <MemberCard
        user={{ ...baseUser, name: "", imageUrls: [] }}
        onWave={jest.fn()}
        onOpen={jest.fn()}
      />
    );
    expect(screen.getByTestId("member-card-photo-placeholder")).toHaveTextContent("?");
  });

  it("keeps the story ring on the photo corner, not across the middle", () => {
    render(
      <MemberCard
        user={{ ...baseUser, hasActiveStory: true }}
        onWave={jest.fn()}
        onOpen={jest.fn()}
      />
    );
    const ring = screen.getByTestId("member-card-story-ring");
    expect(ring.className).toContain("absolute");
  });

  it("does not let a long name widen its column", () => {
    render(
      <MemberCard
        user={{ ...baseUser, name: "안녕하세요반갑습니다저는한국어를배우고있어요" }}
        onWave={jest.fn()}
        onOpen={jest.fn()}
      />
    );
    const name = screen.getByTestId("member-card-name");
    expect(name.className).toContain("truncate");
    // `truncate` alone cannot shrink a flex item below its content's natural
    // width -- `min-w-0` overrides the flex item's automatic minimum size,
    // which is what actually lets the ellipsis engage instead of the text
    // hard-clipping against the card's `overflow-hidden`.
    expect(name.className).toContain("min-w-0");
  });

  it("gives the wave button the full width of the card foot", () => {
    render(<MemberCard user={baseUser} onWave={jest.fn()} onOpen={jest.fn()} />);
    const wave = screen.getByTestId("member-card-wave");
    expect(wave.className).toContain("w-full");
  });
});

describe("MemberCard match reasons", () => {
  const withReasons = (reasons: string[]) =>
    render(
      <MemberCard
        user={baseUser}
        reasons={reasons}
        onWave={jest.fn()}
        onOpen={jest.fn()}
      />
    );

  it("leads with the language reason and mutes the rest", () => {
    withReasons(["Active today", "Native Korean speaker", "Same country"]);
    const chips = screen.getAllByTestId(/^member-card-reason-/);
    expect(chips).toHaveLength(3);
    expect(chips[0]).toHaveTextContent("Native Korean speaker");
    expect(chips[0].getAttribute("data-testid")).toBe("member-card-reason-primary");
    expect(chips[1].getAttribute("data-testid")).toBe("member-card-reason-secondary");
  });

  it("shows presence reasons on their own when there is no language match", () => {
    withReasons(["Active today", "Same country"]);
    expect(screen.queryByTestId("member-card-reason-primary")).not.toBeInTheDocument();
    expect(screen.getAllByTestId("member-card-reason-secondary")).toHaveLength(2);
  });

  it("renders no chip row at all when there are no reasons", () => {
    withReasons([]);
    expect(screen.queryByTestId("member-card-reasons")).not.toBeInTheDocument();
  });

  it("renders no chip row when the prop is absent", () => {
    render(<MemberCard user={baseUser} onWave={jest.fn()} onOpen={jest.fn()} />);
    expect(screen.queryByTestId("member-card-reasons")).not.toBeInTheDocument();
  });

  it("drops empty strings rather than rendering a blank chip", () => {
    withReasons(["", "Active today", ""]);
    expect(screen.getAllByTestId(/^member-card-reason-/)).toHaveLength(1);
  });

  it("re-renders when only the reasons change", () => {
    // Same user object and same handlers, so every other field the memo
    // comparator looks at is identical. If it does not compare reasons -- or
    // compares them after its `user === user` fast path -- this keeps the old
    // chip.
    const onWave = jest.fn();
    const onOpen = jest.fn();
    const { rerender } = render(
      <MemberCard user={baseUser} reasons={["Active today"]} onWave={onWave} onOpen={onOpen} />
    );
    rerender(
      <MemberCard user={baseUser} reasons={["Same country"]} onWave={onWave} onOpen={onOpen} />
    );
    expect(screen.getByText("Same country")).toBeInTheDocument();
    expect(screen.queryByText("Active today")).not.toBeInTheDocument();
  });

});

// --- The compact variant ---------------------------------------------------
//
// This card was reshaped into a cell for the three-column community grid. The
// profile page's suggestion strip reuses it in a horizontal carousel, where a
// ~400px photo-on-top card is the wrong shape entirely -- it went from a row
// carousel to something four times taller. `compact` gives that caller the row
// back without the grid losing its cell.

describe("MemberCard compact", () => {
  it("lays out as a row, with an avatar rather than a full-width photo", () => {
    render(<MemberCard user={baseUser} compact onWave={jest.fn()} onOpen={jest.fn()} />);

    const root = screen.getByTestId("member-card-root");
    expect(root.className).toContain("flex-row");
    expect(root.className).not.toContain("flex-col");
    expect(screen.queryByTestId("member-card-photo")).not.toBeInTheDocument();
    expect(screen.getByTestId("member-card-avatar")).toBeInTheDocument();
  });

  it("keeps the wave control at or above the 40px tap target", () => {
    render(<MemberCard user={baseUser} compact onWave={jest.fn()} onOpen={jest.fn()} />);
    expect(screen.getByTestId("member-card-wave").className).toContain("h-11");
  });

  it("stays a cell by default, so the community grid is unaffected", () => {
    render(<MemberCard user={baseUser} onWave={jest.fn()} onOpen={jest.fn()} />);

    expect(screen.getByTestId("member-card-photo")).toBeInTheDocument();
    expect(screen.getByTestId("member-card-root").className).toContain("flex-col");
  });

  it("re-renders when only compact changes", () => {
    const onWave = jest.fn();
    const onOpen = jest.fn();
    const { rerender } = render(
      <MemberCard user={baseUser} onWave={onWave} onOpen={onOpen} />
    );
    rerender(<MemberCard user={baseUser} compact onWave={onWave} onOpen={onOpen} />);

    expect(screen.queryByTestId("member-card-photo")).not.toBeInTheDocument();
  });
});

// The dots were positioned and sized for the 16:10 banner. Inside a 56px
// avatar, 12px dots inset 8px sit almost in the middle of the picture.
describe("MemberCard compact indicators", () => {
  it("tucks the online dot into the avatar's corner, not its middle", () => {
    render(
      <MemberCard user={baseUser} compact onWave={jest.fn()} onOpen={jest.fn()} />
    );
    const dot = screen.getByTestId("member-card-online-dot");
    expect(dot.className).toContain("w-2.5");
    expect(dot.className).toContain("right-0");
  });

  it("keeps the banner sizing when it is a cell", () => {
    render(<MemberCard user={baseUser} onWave={jest.fn()} onOpen={jest.fn()} />);
    const dot = screen.getByTestId("member-card-online-dot");
    expect(dot.className).toContain("w-3");
    expect(dot.className).toContain("right-2");
  });

  it("names the placeholder the same way in both modes", () => {
    render(
      <MemberCard
        user={{ ...baseUser, imageUrls: [] }}
        compact
        onWave={jest.fn()}
        onOpen={jest.fn()}
      />
    );
    expect(screen.getByTestId("member-card-avatar-placeholder")).toBeInTheDocument();
  });
});

// Reported from production: every card on /communities was a different
// height, so the grid's rows came out ragged. The optional rows -- location,
// bio, the reason chips -- appeared only when a member had them, and the
// chips wrapped onto as many lines as there were reasons. A grid cell now has
// one shape whatever the member has filled in: the optional lines always take
// their space, the chips stay on one line, and the card fills its cell with
// the wave button on the bottom edge. jsdom cannot measure height, so these
// pin the structure that produces it.
describe("one card shape in the grid", () => {
  const sparse: CommunityMemberCard = { ...baseUser, bio: undefined, location: undefined } as any;
  const full: CommunityMemberCard = {
    ...baseUser,
    bio: "A long bio that would otherwise wrap and push the card taller than its neighbours",
    location: { city: "Seoul", country: "South Korea" },
  } as any;
  const manyReasons = ["Speaks English", "Learning Korean", "Online now", "Nearby", "Shares 3 interests"];

  it("reserves the location and bio lines even when the member has neither", () => {
    render(<MemberCard user={sparse} onOpen={jest.fn()} onWave={jest.fn()} />);
    expect(screen.getByTestId("member-card-line-location")).toBeInTheDocument();
    expect(screen.getByTestId("member-card-line-bio")).toBeInTheDocument();
    // The content itself is still absent, as before.
    expect(screen.queryByTestId("member-card-location")).not.toBeInTheDocument();
  });

  it("gives those lines a fixed height, filled or not", () => {
    const { unmount } = render(<MemberCard user={sparse} onOpen={jest.fn()} onWave={jest.fn()} />);
    const emptyLoc = screen.getByTestId("member-card-line-location").className;
    const emptyBio = screen.getByTestId("member-card-line-bio").className;
    unmount();
    render(<MemberCard user={full} onOpen={jest.fn()} onWave={jest.fn()} />);
    expect(screen.getByTestId("member-card-line-location").className).toBe(emptyLoc);
    expect(screen.getByTestId("member-card-line-bio").className).toBe(emptyBio);
    expect(emptyLoc).toMatch(/\bh-/);
    expect(emptyBio).toMatch(/\bh-/);
  });

  it("keeps the reason chips to one clipped line, and reserves it when there are none", () => {
    const { unmount } = render(
      <MemberCard user={full} reasons={manyReasons} onOpen={jest.fn()} onWave={jest.fn()} />
    );
    const row = screen.getByTestId("member-card-line-reasons");
    expect(row.className).toMatch(/\bh-/);
    expect(row.className).toMatch(/overflow-hidden/);
    expect(screen.getByTestId("member-card-reasons").className).toMatch(/flex-nowrap/);
    unmount();

    render(<MemberCard user={full} onOpen={jest.fn()} onWave={jest.fn()} />);
    expect(screen.getByTestId("member-card-line-reasons")).toBeInTheDocument();
  });

  it("keeps the name row to one line, badges and all", () => {
    render(<MemberCard user={{ ...full, isVIP: true, isNew: true } as any} onOpen={jest.fn()} onWave={jest.fn()} />);
    const nameRow = screen.getByTestId("member-card-name").parentElement!;
    expect(nameRow.className).not.toMatch(/flex-wrap/);
    expect(screen.getByTestId("member-card-name").className).toMatch(/truncate/);
  });

  it("fills its grid cell and pins the wave button to the bottom", () => {
    render(<MemberCard user={full} onOpen={jest.fn()} onWave={jest.fn()} />);
    expect(screen.getByTestId("member-card-root").className).toMatch(/\bh-full\b/);
    expect(screen.getByTestId("member-card-wave").className).toMatch(/\bmt-auto\b/);
  });

  it("leaves the compact row (the suggestion strip) as it was", () => {
    render(<MemberCard user={sparse} compact onOpen={jest.fn()} onWave={jest.fn()} />);
    expect(screen.queryByTestId("member-card-line-location")).not.toBeInTheDocument();
    expect(screen.getByTestId("member-card-root").className).not.toMatch(/\bh-full\b/);
  });
});

// Reason chips may arrive as { text, primary } entries -- localised text the
// English /^Speaks |^Native / test cannot read -- and the card must take the
// flag as given.
describe("localised reason chips", () => {
  it("draws a primary entry in the primary style, first, whatever its language", () => {
    render(
      <MemberCard
        user={baseUser}
        reasons={[
          { text: "지금 온라인", primary: false },
          { text: "한국어 원어민", primary: true },
        ]}
        onOpen={jest.fn()}
        onWave={jest.fn()}
      />
    );
    const chips = screen.getByTestId("member-card-reasons").children;
    expect(chips[0]).toHaveTextContent("한국어 원어민");
    expect(chips[0]).toHaveAttribute("data-testid", "member-card-reason-primary");
    expect(chips[1]).toHaveAttribute("data-testid", "member-card-reason-secondary");
  });

  it("still reads plain English strings the old way", () => {
    render(<MemberCard user={baseUser} reasons={["Online now", "Native Korean speaker"]} onOpen={jest.fn()} onWave={jest.fn()} />);
    const chips = screen.getByTestId("member-card-reasons").children;
    expect(chips[0]).toHaveTextContent("Native Korean speaker");
    expect(chips[0]).toHaveAttribute("data-testid", "member-card-reason-primary");
  });

  it("redraws when an entry's text changes, even if the user object is reused", () => {
    const { rerender } = render(
      <MemberCard user={baseUser} reasons={[{ text: "A", primary: false }]} onOpen={jest.fn()} onWave={jest.fn()} />
    );
    rerender(<MemberCard user={baseUser} reasons={[{ text: "B", primary: false }]} onOpen={jest.fn()} onWave={jest.fn()} />);
    expect(screen.getByTestId("member-card-reasons")).toHaveTextContent("B");
  });
});
