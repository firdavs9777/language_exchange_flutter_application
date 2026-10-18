const mockSetupListeners = jest.fn();
jest.mock("@reduxjs/toolkit/query", () => ({
  ...jest.requireActual("@reduxjs/toolkit/query"),
  setupListeners: (...args: any[]) => mockSetupListeners(...args),
}));

it("wires RTK Query's online/focus listeners to the store, so refetchOnReconnect does something", () => {
  jest.isolateModules(() => {
    const store = require("./index").default;
    expect(mockSetupListeners).toHaveBeenCalledWith(store.dispatch);
  });
});
