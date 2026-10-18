import { apiSlice } from "./apiSlice";

/**
 * Historically this file held a second, thinner copy of the moment-comment
 * endpoints (`getComments` / `addComment`). `momentsSlice` owns them now --
 * `getMomentComments`, `addMomentComment`, `deleteMomentComment` plus the
 * comment engagement endpoints (like, react, replies, image, translate) --
 * and `src/components/moments/comments/` is their only caller, so the
 * duplicates are gone.
 *
 * The module stays because `src/store/index.ts` registers this reducer under
 * the `comments` key. It is the shared `apiSlice` reducer (injectEndpoints
 * returns the same api object), so removing the key would change the store
 * shape -- and the prerender's preloaded-state snapshot with it -- for no
 * gain. Injecting no endpoints keeps that registration valid and adds nothing.
 */
export const commentsApiSlice = apiSlice.injectEndpoints({
  endpoints: () => ({}),
});

export default commentsApiSlice.reducer;
