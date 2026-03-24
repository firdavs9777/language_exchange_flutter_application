# New Provider

Create a new Riverpod provider for the BananaTalk app.

## Instructions

When creating a new provider:

1. **File Location:** Place in `lib/providers/provider_root/<feature>_providers.dart`
2. **Framework:** Flutter Riverpod 2.4.10 — use `ref.watch()` in widgets, `ref.read()` for one-shot actions
3. **Provider Types:**
   - `FutureProvider` — async data fetching (API calls with caching)
   - `StateNotifierProvider` — complex mutable state with actions
   - `ChangeNotifierProvider` — service classes (auth, chat)
   - `Provider` — computed/derived state, service instances
4. **Persistence:** Use `SharedPreferences` for filter/preference state (see `MomentFilterNotifier` pattern)

## FutureProvider (data fetching)

```dart
final featureListProvider = FutureProvider<List<FeatureModel>>((ref) async {
  final service = ref.read(featureServiceProvider);
  return service.getItems();
});

// With family for parameterized queries
final featureDetailProvider = FutureProvider.family<FeatureModel, String>((ref, id) async {
  final service = ref.read(featureServiceProvider);
  return service.getItem(id);
});
```

## StateNotifierProvider (mutable state)

```dart
class FeatureFilterNotifier extends StateNotifier<FeatureFilter> {
  FeatureFilterNotifier() : super(FeatureFilter.defaults());

  void updateCategory(String category) {
    state = state.copyWith(category: category);
  }
}

final featureFilterProvider =
    StateNotifierProvider<FeatureFilterNotifier, FeatureFilter>(
  (ref) => FeatureFilterNotifier(),
);
```

## Derived/Computed Provider

```dart
final filteredFeaturesProvider = Provider<List<FeatureModel>>((ref) {
  final items = ref.watch(featureListProvider).valueOrNull ?? [];
  final filter = ref.watch(featureFilterProvider);
  return items.where((item) => filter.matches(item)).toList();
});
```

## Usage in Widgets

```dart
class FeatureScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(featureListProvider);

    return itemsAsync.when(
      data: (items) => ListView.builder(...),
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

## Checklist
- [ ] Provider in `lib/providers/provider_root/`
- [ ] Uses correct provider type for the use case
- [ ] Widgets use `ref.watch()` for reactive state, `ref.read()` for actions
- [ ] `FutureProvider` uses `.when()` pattern for loading/error states
