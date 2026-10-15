import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/pages/chat/conversation/reply_routing.dart';

/// The reply endpoint stores text only, so a sticker/GIF sent while
/// replying used to arrive as a plain-text bubble of its emoji/URL.
void main() {
  test('text replies use the reply API', () {
    expect(sendViaReplyApi(isReplying: true), isTrue);
    expect(sendViaReplyApi(isReplying: true, messageType: 'text'), isTrue);
  });

  test('stickers and GIFs keep their type instead of becoming text', () {
    expect(sendViaReplyApi(isReplying: true, messageType: 'sticker'), isFalse);
    expect(sendViaReplyApi(isReplying: true, messageType: 'gif'), isFalse);
  });

  test('nothing goes through the reply API when not replying', () {
    expect(sendViaReplyApi(isReplying: false), isFalse);
    expect(sendViaReplyApi(isReplying: false, messageType: 'gif'), isFalse);
  });
}
