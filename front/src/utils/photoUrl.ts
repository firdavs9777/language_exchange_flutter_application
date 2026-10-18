import { BASE_URL } from "../constants";

/**
 * The first photo, as a URL a browser can load: an absolute URL as-is, a
 * relative storage path under the API's /uploads (the rule MainNavbar uses).
 * For users that arrive with raw `images` and no `imageUrls`.
 */
export function photoUrl(images: string[] | undefined | null): string | undefined {
  const first = (images || []).find((image) => typeof image === "string" && image.trim());
  if (!first) return undefined;
  return first.startsWith("http") ? first : `${BASE_URL}/uploads/${first}`;
}

/** A user's avatar: the server-built `imageUrls[0]`, else `photoUrl(images)`. */
export function userAvatarUrl(
  user: { imageUrls?: string[]; images?: string[] } | null | undefined
): string | undefined {
  if (!user) return undefined;
  const built = (user.imageUrls || []).find((url) => typeof url === "string" && url.trim());
  return built || photoUrl(user.images);
}
