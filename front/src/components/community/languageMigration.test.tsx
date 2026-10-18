import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import MemberCard, { CommunityMemberCard } from "./MemberCard";
import { getLanguageFlag } from "./utils";
import LanguageFlagChip from "./tandem/LanguageFlagChip";

const member: CommunityMemberCard = {
  _id: "1",
  name: "Kertu",
  native_language: "Estonian",
  language_to_learn: "Persian",
  imageUrls: [],
};

it("MemberCard renders the corrected flag, not the collision", () => {
  render(<MemberCard user={member} onWave={() => {}} onOpen={() => {}} />);
  // The avatar corner carries the native-language flag.
  expect(screen.getByTitle("Estonian")).toHaveTextContent("🇪🇪");
  expect(screen.getByTitle("Estonian")).not.toHaveTextContent("🇪🇸");
});

it("community/utils getLanguageFlag resolves through the shared module", () => {
  expect(getLanguageFlag("Estonian")).toBe("🇪🇪");
  expect(getLanguageFlag("Persian")).toBe("🇮🇷");
  expect(getLanguageFlag("Chinese (Traditional)")).toBe("🇹🇼");
});

// tandem/LanguageFlagChip carried its own 13-entry map, and Uzbek was one of
// the entries the other three tables (and this one) got wrong: it rendered
// the unresolved-language globe rather than the flag.
it("LanguageFlagChip resolves a language the old 13-entry map missed", () => {
  const { container } = render(<LanguageFlagChip label="NATIVE" language="Uzbek" />);
  expect(container.querySelector(".lang-flag-chip__flag")).toHaveTextContent("🇺🇿");
  expect(container.querySelector(".lang-flag-chip__flag")).not.toHaveTextContent("🌐");
});
