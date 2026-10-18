import { makeStore } from "../../store";
import { momentsApiSlice } from "./momentsSlice";
import { MOMENTS_URL } from "../../constants";

function mockFetch(): string[] {
  const urls: string[] = [];
  (global as any).fetch = jest.fn(async (req: any) => {
    urls.push(req.url);
    return new Response(JSON.stringify({ moments: [] }), {
      status: 200,
      headers: { "content-type": "application/json" },
    });
  });
  return urls;
}

const endpoints = momentsApiSlice.endpoints as any;

describe("feed queries carry the server filters", () => {
  it.each([
    ["getMoments", "", { feed: "following" }],
    ["getTrendingMoments", "/trending", {}],
    ["getExploreMoments", "/explore", {}],
  ])("%s sends category, language, mood, tags and q", async (name, path, extra) => {
    const urls = mockFetch();
    await makeStore().dispatch(
      endpoints[name].initiate({
        page: 2, limit: 10, ...extra,
        filters: { category: "food", language: "ko", mood: "happy", tag: "kimchi", q: "서울" },
      })
    );
    const url = new URL(urls[0]);
    expect(url.pathname).toBe(`${MOMENTS_URL}${path}`);
    expect(url.searchParams.get("page")).toBe("2");
    expect(url.searchParams.get("category")).toBe("food");
    expect(url.searchParams.get("language")).toBe("ko");
    expect(url.searchParams.get("mood")).toBe("happy");
    expect(url.searchParams.get("tags")).toBe("kimchi");
    expect(url.searchParams.get("q")).toBe("서울");
  });

  it("an unfiltered getMoments keeps today's exact URL (the prerender cache key)", async () => {
    const urls = mockFetch();
    await makeStore().dispatch(endpoints.getMoments.initiate({ page: 1, limit: 10 }));
    expect(new URL(urls[0]).search).toBe("?page=1&limit=10");
  });

  it("explore keeps its category argument", async () => {
    const urls = mockFetch();
    await makeStore().dispatch(endpoints.getExploreMoments.initiate({ page: 1, limit: 10, category: "music" }));
    expect(new URL(urls[0]).searchParams.get("category")).toBe("music");
  });
});
