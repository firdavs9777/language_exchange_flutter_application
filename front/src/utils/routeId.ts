const OBJECT_ID = /^[0-9a-fA-F]{24}/;

/**
 * The id a route param actually names, with anything glued onto it dropped.
 *
 * Shared links come back damaged. A share target that merges the Web Share
 * `text` into the `url` turns /card/<id> into /card/<id>%20Practice%20English
 * with me on BananaTalk, and a link pasted into a sentence picks up a ")" or a
 * "." on the end. Every id in these routes is a Mongo ObjectId, so the 24 hex
 * characters at the front are the whole of it and the rest is noise. Anything
 * that is not an ObjectId falls back to its first word.
 */
export default function routeId(raw?: string | null): string {
  const value = (raw || "").trim();
  const objectId = value.match(OBJECT_ID);
  if (objectId) return objectId[0];
  return value.split(/\s+/)[0] || "";
}
