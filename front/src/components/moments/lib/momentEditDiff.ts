/**
 * The editor's view of a moment, and the update that turns one into another.
 * The editor sends only what changed (as EditProfile does), so a field the
 * reader never touched can never be overwritten with a stale or default value.
 */
export interface MomentLocationValue {
  formattedAddress?: string;
  type?: string;
  coordinates?: number[];
}

export interface EditableMoment {
  title: string;
  description: string;
  mood: string;
  tags: string[];
  category: string;
  language: string;
  privacy: string;
  backgroundColor: string;
  location: MomentLocationValue | null;
  /** ISO instant, or null for "published / post now". */
  scheduledFor: string | null;
}

const hasLocation = (location: any) =>
  Boolean(location && Array.isArray(location.coordinates) && location.coordinates.length === 2);

export function editableFrom(moment: any): EditableMoment {
  const m = moment || {};
  return {
    title: m.title || "",
    description: m.description || "",
    mood: m.mood || "",
    tags: Array.isArray(m.tags) ? m.tags.slice() : [],
    category: m.category || "general",
    language: m.language || "",
    privacy: m.privacy || "public",
    backgroundColor: m.backgroundColor || "",
    location: hasLocation(m.location)
      ? { formattedAddress: m.location.formattedAddress, type: "Point", coordinates: m.location.coordinates.slice() }
      : null,
    scheduledFor: m.scheduledFor ? new Date(m.scheduledFor).toISOString() : null,
  };
}

const same = (a: any, b: any) => JSON.stringify(a) === JSON.stringify(b);

export function momentEditDiff(original: EditableMoment, draft: EditableMoment): Partial<EditableMoment> {
  const out: any = {};
  (["title", "description"] as const).forEach((key) => {
    const value = draft[key].trim();
    if (value !== original[key].trim()) out[key] = value;
  });
  (["mood", "category", "language", "privacy", "backgroundColor"] as const).forEach((key) => {
    if (draft[key] !== original[key]) out[key] = draft[key];
  });
  if (!same(draft.tags, original.tags)) out.tags = draft.tags.slice();
  if (!same(draft.location, original.location)) out.location = draft.location;
  if (draft.scheduledFor !== original.scheduledFor) out.scheduledFor = draft.scheduledFor;
  return out;
}
