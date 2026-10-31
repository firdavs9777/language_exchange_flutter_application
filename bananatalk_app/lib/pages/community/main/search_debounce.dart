import 'package:bananatalk_app/services/api_client.dart';

/// Community search applies 350 ms after the last key: the Partners list
/// used to search the server on every keystroke (audit 2026-10-30).
class SearchDebounce {
  SearchDebounce({
    required this.onApply,
    Duration delay = const Duration(milliseconds: 350),
  }) : _debouncer = Debouncer(delay: delay);

  final void Function(String query) onApply;
  final Debouncer _debouncer;

  void typed(String value) => _debouncer.run(() => onApply(value));

  /// Clearing applies at once and drops a pending search.
  void clearNow() {
    _debouncer.cancel();
    onApply('');
  }

  void dispose() => _debouncer.dispose();
}
