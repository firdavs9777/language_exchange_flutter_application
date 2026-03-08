// lib/utils/provider_utils.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Extension methods for optimized provider watching
extension ProviderSelectExtensions on WidgetRef {
  /// Watch only a specific field from a provider to minimize rebuilds
  /// Usage: ref.watchSelect(userProvider, (user) => user.name)
  T watchSelect<S, T>(
    ProviderListenable<S> provider,
    T Function(S) selector,
  ) {
    return watch(provider.select(selector));
  }

  /// Watch AsyncValue and select from data
  /// Returns null if loading or error
  T? watchAsyncSelect<S, T>(
    ProviderListenable<AsyncValue<S>> provider,
    T Function(S) selector,
  ) {
    final asyncValue = watch(provider);
    return asyncValue.whenOrNull(data: selector);
  }

  /// Watch only if AsyncValue has data (reduces rebuilds during loading)
  bool watchHasData<T>(ProviderListenable<AsyncValue<T>> provider) {
    return watch(provider.select((v) => v.hasValue));
  }

  /// Watch only the loading state of an AsyncValue
  bool watchIsLoading<T>(ProviderListenable<AsyncValue<T>> provider) {
    return watch(provider.select((v) => v.isLoading));
  }

  /// Watch only the error state of an AsyncValue
  bool watchHasError<T>(ProviderListenable<AsyncValue<T>> provider) {
    return watch(provider.select((v) => v.hasError));
  }
}

/// Memoization helper for expensive computations in providers
class Memoizer<T> {
  T? _cachedValue;
  Object? _lastKey;

  T call(Object key, T Function() compute) {
    if (_lastKey != key) {
      _lastKey = key;
      _cachedValue = compute();
    }
    return _cachedValue as T;
  }

  void invalidate() {
    _lastKey = null;
    _cachedValue = null;
  }
}

/// Cache with expiration for provider data
class TimedCache<T> {
  T? _value;
  DateTime? _cachedAt;
  final Duration maxAge;

  TimedCache({this.maxAge = const Duration(minutes: 5)});

  T? get value {
    if (_value != null && _cachedAt != null) {
      if (DateTime.now().difference(_cachedAt!) < maxAge) {
        return _value;
      }
    }
    return null;
  }

  set value(T? newValue) {
    _value = newValue;
    _cachedAt = DateTime.now();
  }

  bool get isExpired {
    if (_cachedAt == null) return true;
    return DateTime.now().difference(_cachedAt!) >= maxAge;
  }

  void invalidate() {
    _value = null;
    _cachedAt = null;
  }
}

/// Helper to batch multiple provider updates
class ProviderBatch {
  final WidgetRef _ref;
  final List<void Function()> _updates = [];

  ProviderBatch(this._ref);

  void add<T>(StateProvider<T> provider, T value) {
    _updates.add(() => _ref.read(provider.notifier).state = value);
  }

  void execute() {
    for (final update in _updates) {
      update();
    }
    _updates.clear();
  }
}
