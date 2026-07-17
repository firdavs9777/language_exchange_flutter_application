import { LocationInput } from './buildRegisterPayload';

export function normalizeLocationResult(raw: any): LocationInput | null {
  if (!raw || (!raw.city && !raw.country)) return null;
  const out: LocationInput = { city: raw.city || '', country: raw.country || '' };
  const c = raw.coordinates;
  const finite = Array.isArray(c) && c.length === 2 && c.every((n: any) => Number.isFinite(n));
  const isNullIsland = finite && c[0] === 0 && c[1] === 0;
  if (finite && !isNullIsland) out.coordinates = [c[0], c[1]];
  return out;
}
