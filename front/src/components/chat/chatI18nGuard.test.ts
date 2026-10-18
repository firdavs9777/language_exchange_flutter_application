import fs from "fs";
import path from "path";

/**
 * Every user-visible English string in these chat files must reach the
 * screen through t(): it may appear in the source ONLY as the `|| "…"`
 * fallback after a t() call. A bare JSX text node, a bare attribute value or
 * a bare string returned to the screen fails here (chat#19).
 */
const GUARDED: { [file: string]: string[] } = {
  "UsersList.tsx": ["just now", "Loading chats...", "Error loading conversations", "An unexpected error occurred", "Try Again"],
  "actions/MessageActionMenu.tsx": ["Reply", "Copy", "Forward", "Pin", "Bookmark", "Listen", "Edit", "Delete for everyone"],
  "actions/PinnedBar.tsx": ["Unpin message", "Photo", "Voice message", "Video", "File"],
  "actions/ReplyComposerBar.tsx": ["Cancel reply", "Photo", "Voice message", "Video", "File"],
  "actions/ForwardDialog.tsx": ["Forward to", "Loading conversations…", "No conversations found.", "Unknown"],
  "components/CorrectionCard.tsx": ["Accept correction", "Accepting…", "Failed to accept correction"],
  "components/TranslationCard.tsx": ["Translating…", "Save phrase", "Saved to study queue", "Failed to translate message", "Failed to save phrase", "Close translation"],
  "components/CorrectionModal.tsx": ["Language Correction", "Original Message", "Your Correction", "Send Correction", "Please provide a correction"],
  "components/CallInAppButtons.tsx": ["Voice call", "Video call", "Calls happen in the BananaTalk app", "Open the app", "Not now"],
  "MediaGallery.tsx": ["Shared Media", "Loading media...", "Error loading media", "Unknown file", "Unknown size"],
};

const escape = (s: string): string => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

Object.keys(GUARDED).forEach((file) => {
  const source = fs.readFileSync(path.join(__dirname, file), "utf8");
  describe(file, () => {
    it("imports useTranslation", () => {
      expect(source).toMatch(/useTranslation/);
    });
    GUARDED[file].forEach((literal) => {
      it(`shows "${literal}" only as a t() fallback`, () => {
        const all = source.match(new RegExp(`["'\`>]\\s*${escape(literal)}\\s*["'\`<]`, "g")) || [];
        const asFallback = source.match(new RegExp(`\\|\\|\\s*["'\`]${escape(literal)}["'\`]`, "g")) || [];
        expect(all.length).toBe(asFallback.length);
      });
    });
  });
});
