import 'package:bananatalk_app/pages/comments/comments_main.dart';
import 'package:flutter_test/flutter_test.dart';

/// The backend lets a moment's owner delete any comment on it, but the app
/// offered Delete only on your own comments.
void main() {
  test('the comment author may delete', () {
    expect(
      canDeleteComment(
          currentUserId: 'a', commentAuthorId: 'a', momentOwnerId: 'o'),
      isTrue,
    );
  });

  test("the moment owner may delete anyone's comment on it", () {
    expect(
      canDeleteComment(
          currentUserId: 'o', commentAuthorId: 'a', momentOwnerId: 'o'),
      isTrue,
    );
  });

  test('anyone else may not', () {
    expect(
      canDeleteComment(
          currentUserId: 'x', commentAuthorId: 'a', momentOwnerId: 'o'),
      isFalse,
    );
    expect(
      canDeleteComment(
          currentUserId: null, commentAuthorId: 'a', momentOwnerId: null),
      isFalse,
    );
    expect(
      canDeleteComment(
          currentUserId: 'x', commentAuthorId: 'a', momentOwnerId: null),
      isFalse,
    );
  });
}
