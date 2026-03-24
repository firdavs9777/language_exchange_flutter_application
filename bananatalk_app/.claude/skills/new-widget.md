# New Widget

Create a new reusable widget for the BananaTalk app.

## Instructions

When creating a new reusable widget:

1. **File Location:** Place in `lib/widgets/` for app-wide widgets, or `lib/widgets/<feature>/` for feature-specific ones
2. **Theme:** Use `context.isDarkMode` and theme extensions — never hardcode colors
3. **Responsiveness:** Use `MediaQuery.of(context)` for sizing when needed
4. **Riverpod:** Use `ConsumerWidget` only if the widget needs provider access; prefer plain `StatelessWidget` for pure UI
5. **Existing widgets to reuse:** `BananaButton`, `CachedImageWidget`, `VipAvatarFrame`, `VipLockedFeature`

## Widget Template

```dart
import 'package:flutter/material.dart';

class FeatureWidget extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const FeatureWidget({
    super.key,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          style: TextStyle(color: context.textPrimary),
        ),
      ),
    );
  }
}
```

## Checklist
- [ ] Supports dark mode via theme extensions
- [ ] Uses `const` constructors where possible
- [ ] Required params are `required`, optional params have defaults
- [ ] Reuses existing widgets (`CachedImageWidget` for images, `BananaButton` for buttons)
- [ ] No hardcoded colors or sizes — uses theme and MediaQuery
