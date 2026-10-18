import { AppStore } from "../../store";
import { plansApiSlice } from "../../store/slices/plansSlice";
import { publicStatsApiSlice } from "../../store/slices/publicStatsSlice";
import { momentsApiSlice } from "../../store/slices/momentsSlice";

export type Prefetcher = (store: AppStore) => Promise<unknown>;

const PAGES_WITH_PRICING = ["/"];

// RTK Query hooks subscribe in effects, which renderToString never runs, so
// any data a prerendered page should contain is dispatched and awaited here
// before render. iOS prices are prerendered; the client refetches for Android
// after hydration (the two stores charge the same figures today).
export function prefetchersFor(path: string): Prefetcher[] {
  const list: Prefetcher[] = [];
  if (PAGES_WITH_PRICING.includes(path)) {
    // .unwrap() turns a failed query into a rejected promise, so renderRoute's
    // prefetch() can catch it and log a warning -- store.dispatch(...) alone
    // resolves with a rejected *action* and never rejects, which would
    // silently swallow the failure.
    list.push((store) => (store.dispatch(plansApiSlice.endpoints.getVipPlans.initiate("ios")) as any).unwrap());
  }
  if (path === "/") {
    list.push((store) => (store.dispatch(publicStatsApiSlice.endpoints.getPublicStats.initiate()) as any).unwrap());
  }
  if (path === "/moments") {
    // Args must match MainMoments' first anonymous render exactly (page 1,
    // limit 10, activeTab "forYou", no language) -- RTK Query keys its cache
    // on the serialized args, so any mismatch means this prefetch is wasted.
    list.push((store) =>
      (store.dispatch(momentsApiSlice.endpoints.getMoments.initiate({ page: 1, limit: 10 })) as any).unwrap()
    );
    list.push((store) =>
      (store.dispatch(momentsApiSlice.endpoints.getPromptOfDay.initiate({ language: undefined })) as any).unwrap()
    );
  }
  return list;
}
