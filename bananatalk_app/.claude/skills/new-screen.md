# New Screen

Create a new Flutter screen/page for the BananaTalk app.

## Instructions

When creating a new screen:

1. **File Location:** Place in `lib/pages/<feature>/` following the feature-based structure
2. **Widget Type:** Use `ConsumerStatefulWidget` (Riverpod) for screens with state, `ConsumerWidget` for simple screens
3. **Theme:** Use the project's theme extensions: `context.isDarkMode`, `context.textPrimary`, etc. from `ThemeContext`
4. **Localization:** Use `AppLocalizations.of(context)!` for all user-facing strings — add keys to all 18 ARB files in `lib/l10n/`
5. **Navigation:** Register the route in `lib/router/app_router.dart` using GoRouter patterns
6. **State:** Create providers in `lib/providers/provider_root/` using Riverpod patterns (StateNotifierProvider, FutureProvider, etc.)

## Screen Template

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class FeatureScreen extends ConsumerStatefulWidget {
  const FeatureScreen({super.key});

  @override
  ConsumerState<FeatureScreen> createState() => _FeatureScreenState();
}

class _FeatureScreenState extends ConsumerState<FeatureScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenTitle)),
      body: // ...
    );
  }
}
```

## Checklist
- [ ] Screen widget in `lib/pages/<feature>/`
- [ ] Route added in `app_router.dart`
- [ ] Localization keys added to `app_en.arb` (and other ARB files)
- [ ] Provider created if needed in `lib/providers/provider_root/`
- [ ] Uses `context.isDarkMode` for dark mode support
