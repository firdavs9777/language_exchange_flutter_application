// react-router's static handler takes a Fetch Request. Plain Node has one;
// Jest 27's node environment (what CRA 5 ships) does not expose it, so the
// harness falls back to the minimal shape the handler actually reads:
// url, method, signal and headers. Verified against react-router-dom 6.23.1.
export class MinimalRequest {
  url: string;
  method = "GET";
  headers = new Map<string, string>();
  signal: AbortSignal;
  constructor(url: string) {
    this.url = url;
    this.signal = new AbortController().signal;
  }
}

export function makeRequest(url: string): Request {
  const Ctor: any = (globalThis as any).Request;
  return Ctor ? new Ctor(url) : ((new MinimalRequest(url) as unknown) as Request);
}
