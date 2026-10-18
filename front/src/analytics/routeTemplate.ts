// Turns a concrete path into its route template, e.g. "/profile/abc123" with
// { userId: "abc123" } -> "/profile/:userId". Analytics must never carry a
// user identifier, so usePageView tracks this instead of the raw pathname.
export function routeTemplate(pathname: string, params: Record<string, string | undefined>): string {
  const entries = Object.entries(params)
    .filter(([key, value]) => key !== "*" && value !== undefined && value !== "")
    // Longer values first, so a value that is itself a prefix/substring of
    // another param's value can't mis-replace a segment meant for the other.
    .sort((a, b) => (b[1] as string).length - (a[1] as string).length);

  const segments = pathname.split("/");
  const templated = segments.map((segment) => {
    const match = entries.find(([, value]) => segment === value);
    return match ? `:${match[0]}` : segment;
  });
  return templated.join("/");
}
