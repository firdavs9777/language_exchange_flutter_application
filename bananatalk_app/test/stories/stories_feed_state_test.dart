import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/pages/stories/feed/stories_feed_state.dart';

void main() {
  group('storiesFeedError', () {
    test('a successful load clears a banner that was already showing', () {
      // The regression: Retry refetched fine and the row stayed on the error
      // state, because success never touched the field.
      expect(
        storiesFeedError(succeeded: true, error: null, hasCachedStories: false),
        isNull,
      );
    });

    test('a successful load clears it even when the feed came back empty', () {
      expect(
        storiesFeedError(succeeded: true, error: null, hasCachedStories: false),
        isNull,
      );
    });

    test('a failed first load surfaces the error', () {
      expect(
        storiesFeedError(
          succeeded: false,
          error: 'SocketException: Failed host lookup',
          hasCachedStories: false,
        ),
        'SocketException: Failed host lookup',
      );
    });

    test('a failed refresh keeps cached stories instead of the banner', () {
      expect(
        storiesFeedError(
          succeeded: false,
          error: 'SocketException',
          hasCachedStories: true,
        ),
        isNull,
      );
    });

    test('a failure with no message still surfaces something', () {
      expect(
        storiesFeedError(succeeded: false, error: null, hasCachedStories: false),
        isNotNull,
      );
      expect(
        storiesFeedError(succeeded: false, error: '   ', hasCachedStories: false),
        isNotNull,
      );
    });
  });

  group('storiesFeedShowsShimmer', () {
    test('an explicit retry with nothing on screen shows the shimmer', () {
      expect(
        storiesFeedShowsShimmer(explicitLoad: true, hasCachedStories: false),
        isTrue,
      );
    });

    test('a background refresh never flashes the shimmer', () {
      expect(
        storiesFeedShowsShimmer(explicitLoad: false, hasCachedStories: false),
        isFalse,
      );
    });

    test('an explicit refresh over existing stories leaves them in place', () {
      expect(
        storiesFeedShowsShimmer(explicitLoad: true, hasCachedStories: true),
        isFalse,
      );
    });
  });
}
