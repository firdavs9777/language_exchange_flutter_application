import 'package:bananatalk_app/pages/chat/message/message_bubble/story_share_message_view.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Base JSON for a plain DM message. Individual tests override the fields
/// that matter for `StoryShareMessageView.matches`.
Map<String, dynamic> _baseJson({
  String? message,
  String? messageType,
  Map<String, dynamic>? storyReference,
}) {
  return {
    '_id': '1',
    'sender': null,
    'receiver': null,
    'message': message,
    'createdAt': DateTime.now().toIso8601String(),
    '__v': 0,
    'read': false,
    if (messageType != null) 'messageType': messageType,
    if (storyReference != null) 'storyReference': storyReference,
  };
}

void main() {
  test('story reply (text + storyReference) does not match', () {
    final message = Message.fromJson(_baseJson(
      message: 'Shared a story',
      messageType: 'text',
      storyReference: {'storyId': 'story123', 'thumbnail': 'https://example.com/t.jpg'},
    ));

    expect(StoryShareMessageView.matches(message), isFalse);
  });

  test("messageType 'story_share' without a storyReference still matches "
      '(renders as the expired-state card)', () {
    final message = Message.fromJson(_baseJson(
      message: 'Shared a story',
      messageType: 'story_share',
    ));

    expect(message.storyReference, isNull);
    expect(StoryShareMessageView.matches(message), isTrue);
  });

  test('a plain text message whose body happens to be exactly '
      '"Shared a story" does NOT match', () {
    final message = Message.fromJson(_baseJson(
      message: 'Shared a story',
      messageType: 'text',
    ));

    expect(StoryShareMessageView.matches(message), isFalse);
  });
}
