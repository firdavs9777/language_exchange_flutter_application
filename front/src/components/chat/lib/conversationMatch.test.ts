import { isConversationWith, findConversationWith } from "./conversationMatch";

it("prefers the otherParticipant the backend already computed", () => {
  const conversation = {
    _id: "c1",
    otherParticipant: { _id: "u2" },
    // A group-ish document that happens to contain u3 as well: matching on
    // `participants` alone would call this "the conversation with u3".
    participants: [{ _id: "me" }, { _id: "u2" }, { _id: "u3" }],
  };
  expect(isConversationWith(conversation, "u2")).toBe(true);
  expect(isConversationWith(conversation, "u3")).toBe(false);
});

it("falls back to participants when otherParticipant is absent", () => {
  const conversation = { _id: "c1", participants: [{ _id: "me" }, { _id: "u2" }] };
  expect(isConversationWith(conversation, "u2")).toBe(true);
  expect(isConversationWith(conversation, "u9")).toBe(false);
});

it("reads raw ids as well as populated ones", () => {
  expect(isConversationWith({ participants: ["me", "u2"] }, "u2")).toBe(true);
  expect(isConversationWith({ otherParticipant: "u2" }, "u2")).toBe(true);
});

it("answers false rather than throwing on a half-formed record", () => {
  expect(isConversationWith({}, "u2")).toBe(false);
  expect(isConversationWith({ participants: [null, undefined] } as any, "u2")).toBe(false);
  expect(isConversationWith(null as any, "u2")).toBe(false);
  expect(isConversationWith({ participants: [{ _id: "u2" }] }, "")).toBe(false);
});

it("finds the conversation in a list, and nothing in a list without it", () => {
  const list = [
    { _id: "c9", otherParticipant: { _id: "u7" } },
    { _id: "c1", otherParticipant: { _id: "u2" } },
  ];
  expect(findConversationWith(list, "u2")!._id).toBe("c1");
  expect(findConversationWith(list, "u5")).toBeNull();
  // Not loaded yet is not the same as not there -- callers tell the two
  // apart by the query's own isLoading, never by this returning null.
  expect(findConversationWith(undefined, "u2")).toBeNull();
});
