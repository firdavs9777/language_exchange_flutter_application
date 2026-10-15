/// Whether a message composed while replying should go through the reply
/// API (`POST /messages/:id/reply`).
///
/// That endpoint only stores text: it reads `message` and `receiver` and
/// ignores any type, so a sticker or GIF sent through it arrived as its raw
/// emoji/URL in a plain text bubble. The socket `sendMessage` path keeps
/// `messageType` (text, sticker, gif) but has no reply link. Until the
/// backend accepts a type on replies, a non-text message keeps its type and
/// is sent as a normal message — the reply quote is dropped rather than the
/// sticker/GIF itself.
bool sendViaReplyApi({required bool isReplying, String? messageType}) =>
    isReplying && (messageType == null || messageType == 'text');
