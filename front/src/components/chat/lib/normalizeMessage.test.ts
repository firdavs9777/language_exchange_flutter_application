import { normalizeMessage, senderIdOf, idOf } from "./normalizeMessage";

describe("normalizeMessage", () => {
  it("turns a bare sender id into the {_id} shape every reader expects", () => {
    const msg: any = { _id: "m1", message: "x", sender: "me", receiver: "u2" };
    const out: any = normalizeMessage(msg);
    expect(out.sender).toEqual({ _id: "me", name: "" });
    expect(out.receiver).toBe("u2");
  });
  it("hands a populated message back untouched (same object)", () => {
    const msg: any = { _id: "m1", sender: { _id: "me", name: "Me" }, receiver: { _id: "u2", name: "Ada" } };
    expect(normalizeMessage(msg)).toBe(msg);
  });
  it("survives a message with no sender at all", () => {
    const out: any = normalizeMessage({ _id: "m1" } as any);
    expect(out.sender).toEqual({ _id: "", name: "" });
  });
});

describe("senderIdOf / idOf", () => {
  it("reads either shape", () => {
    expect(senderIdOf({ sender: "me" } as any)).toBe("me");
    expect(senderIdOf({ sender: { _id: "me" } } as any)).toBe("me");
    expect(senderIdOf({} as any)).toBe("");
    expect(idOf({ _id: 42 })).toBe("42");
  });
});
