import { useGetAppConfigQuery } from "../../../store/slices/appConfigSlice";

/**
 * True only once the server has said it enforces scheduling
 * (/app-config momentSchedulingEnforced); false while loading or on error, so
 * nobody schedules a moment that would publish immediately.
 */
export function useMomentSchedulingEnabled(): boolean {
  const { data, isError } = useGetAppConfigQuery();
  return !isError && Boolean(data && data.momentSchedulingEnforced === true);
}
