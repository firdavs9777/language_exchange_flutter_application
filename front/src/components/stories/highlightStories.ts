import { Story } from "./types";

/**
 * Reading a highlight the way the backend actually sends it.
 *
 * `models/StoryHighlight.js` stores `stories: [{ story, addedAt }]` and
 * `getUserHighlights` populates `stories.story` with a *narrow* projection --
 * `mediaUrls mediaType text backgroundColor createdAt viewCount` and nothing
 * else. Two consequences the UI has to live with:
 *
 *  1. There is no `user` on a highlight's story. Anything that wants an
 *     author's name or avatar has to be told whose profile it is on; it
 *     cannot read it off the story.
 *  2. The mutations (`POST/DELETE /highlights/:id/stories`, `PUT /highlights/:id`)
 *     return the highlight *unpopulated*, so `stories[i].story` is then a bare
 *     id string. `storiesOf` drops those rather than rendering a tile with no
 *     media -- the list query refetches on the same tag and fills them back in.
 *
 * `src/components/stories/types.ts` declares `StoryHighlight.stories` as
 * `Story[]`, which is what a hand-built fixture tends to look like, so both
 * shapes are accepted.
 */
export function storiesOf(highlight: any): Story[] {
  const raw = highlight && highlight.stories;
  if (!Array.isArray(raw)) return [];
  const out: Story[] = [];
  for (let i = 0; i < raw.length; i += 1) {
    const entry = raw[i];
    if (!entry) continue;
    const story = entry.story !== undefined ? entry.story : entry;
    // An unpopulated ref is a string; there is nothing to draw from it.
    if (story && typeof story === "object" && story._id) out.push(story as Story);
  }
  return out;
}

/** First usable media URL of a story, or `""` for a text story. */
export function mediaOf(story: any): string {
  if (!story) return "";
  const urls = story.mediaUrls;
  if (Array.isArray(urls)) {
    for (let i = 0; i < urls.length; i += 1) {
      const url = typeof urls[i] === "string" ? urls[i].trim() : "";
      if (url) return url;
    }
  }
  return typeof story.mediaUrl === "string" ? story.mediaUrl.trim() : "";
}

/**
 * The cover to draw: the explicit one the owner chose, else the first story's
 * media -- which is what `addStory` picks server-side when a highlight gets
 * its first story, so the two agree.
 */
export function coverOf(highlight: any): string {
  const explicit =
    highlight && typeof highlight.coverImage === "string"
      ? highlight.coverImage.trim()
      : "";
  if (explicit) return explicit;
  const stories = storiesOf(highlight);
  for (let i = 0; i < stories.length; i += 1) {
    const url = mediaOf(stories[i]);
    if (url) return url;
  }
  return "";
}

/** How many stories a highlight claims, preferring the server's counter. */
export function countOf(highlight: any): number {
  if (highlight && typeof highlight.storyCount === "number" && isFinite(highlight.storyCount)) {
    return highlight.storyCount;
  }
  return storiesOf(highlight).length;
}
