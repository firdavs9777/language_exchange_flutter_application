import 'package:bananatalk_app/pages/community/main/search_debounce.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Partners list searched the server on every keystroke (audit
/// 2026-10-30). Typing now applies once, 350 ms after the last key.
void main() {
  test('typing "abc" one key per 100 ms applies once, after 350 ms', () {
    fakeAsync((async) {
      final applied = <String>[];
      final search = SearchDebounce(onApply: applied.add);
      search.typed('a');
      async.elapse(const Duration(milliseconds: 100));
      search.typed('ab');
      async.elapse(const Duration(milliseconds: 100));
      search.typed('abc');
      async.elapse(const Duration(milliseconds: 349));
      expect(applied, isEmpty);
      async.elapse(const Duration(milliseconds: 1));
      expect(applied, ['abc']);
      search.dispose();
    });
  });

  test('clearNow applies "" at once and drops the pending search', () {
    fakeAsync((async) {
      final applied = <String>[];
      final search = SearchDebounce(onApply: applied.add);
      search.typed('abc');
      search.clearNow();
      async.elapse(const Duration(seconds: 1));
      expect(applied, ['']);
      search.dispose();
    });
  });
}
