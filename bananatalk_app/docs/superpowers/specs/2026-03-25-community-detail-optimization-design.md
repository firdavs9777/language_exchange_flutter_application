# Community Detail Optimization Design

**Date:** 2026-03-25
**Status:** Approved
**Approach:** Incremental Enhancement

## Overview

Enhance the community profile detail screen (`single_community.dart`) and fix dark mode issues in `community_card.dart` to create a more meaningful, engaging user experience that helps users find compatible language exchange partners.

## Goals

1. Fix dark mode issues with hardcoded colors
2. Show language compatibility between users
3. Display engagement signals (online status, response rate, reply speed)
4. Highlight shared interests between users
5. Provide conversation starters to help users break the ice

## Files to Modify

| File | Changes |
|------|---------|
| `lib/pages/community/community_card.dart` | Fix hardcoded colors → theme-aware |
| `lib/pages/community/single_community.dart` | Add 4 new sections, minor dark mode fixes |

## New Widgets

| Widget | Location | Purpose |
|--------|----------|---------|
| `LanguageMatchCard` | `lib/widgets/community/` | Shows language compatibility + levels |
| `EngagementStatsBar` | `lib/widgets/community/` | Online status, response rate, reply speed |
| `ConversationStartersCard` | `lib/widgets/community/` | Smart ice-breaker suggestions |

---

## Section 1: Dark Mode Fixes

### community_card.dart

Replace all hardcoded light-mode colors with theme-aware values.

| Current | Replace With |
|---------|--------------|
| `Colors.white` | `context.surfaceColor` |
| `Colors.grey[50]` | `context.containerColor` |
| `Colors.grey[100]` | `context.containerColor` |
| `Colors.grey[200]` | `context.dividerColor` |
| `Colors.grey[400-700]` | `context.textMuted` / `context.textSecondary` |
| `Colors.black87` | `context.textPrimary` |
| `BoxShadow(...)` always | Conditional: `context.isDarkMode ? [] : AppShadows.sm` |

### Specific Fixes

```dart
// Container gradient (line ~96-101)
// Before:
gradient: LinearGradient(
  colors: [Colors.white, Colors.grey[50]!],
),

// After:
gradient: LinearGradient(
  colors: [context.surfaceColor, context.containerColor],
),
```

```dart
// BoxShadow (line ~102-115)
// Before:
boxShadow: [
  BoxShadow(color: const Color(0xFF00BFA5).withOpacity(0.08), ...),
  BoxShadow(color: Colors.black.withOpacity(0.04), ...),
],

// After:
boxShadow: context.isDarkMode ? [] : AppShadows.md,
```

```dart
// Text colors throughout
// Before:
style: const TextStyle(color: Colors.black87, ...)

// After:
style: TextStyle(color: context.textPrimary, ...)
```

### single_community.dart

Minor fixes needed:
- Error state background: `Colors.red[50]` → `AppColors.errorLight`
- Ensure all new sections use theme extensions

---

## Section 2: Language Match Card

### Purpose
Show language compatibility between the current user and the profile being viewed.

### Placement
Below the hero map header, before action buttons.

### Visual Design

```
┌─────────────────────────────────────────────┐
│  🔄 Language Match                          │
├─────────────────────────────────────────────┤
│  ┌──────────┐         ┌──────────┐          │
│  │ 🇰🇷       │   ↔️    │ 🇺🇸       │          │
│  │ Korean   │         │ English  │          │
│  │ Native   │         │ Learning │          │
│  │ ●●●●○ C1 │         │ ●●○○○ A2 │          │
│  └──────────┘         └──────────┘          │
│                                             │
│  ✨ "You're learning what they speak!"      │
│     Perfect for language exchange           │
└─────────────────────────────────────────────┘
```

### Match Logic

| Scenario | Message | Color |
|----------|---------|-------|
| You learn their native | "You're learning what they speak!" | Green (success) |
| They learn your native | "They're learning what you speak!" | Green |
| Both directions match | "Perfect language exchange match!" | Gold/accent |
| Same native language | "You share the same native language" | Blue (info) |
| No overlap | Show languages without match message | Neutral |

### Widget Implementation

```dart
class LanguageMatchCard extends ConsumerWidget {
  final Community profile;

  const LanguageMatchCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(userProvider).valueOrNull;
    if (currentUser == null) return const SizedBox.shrink();

    final matchType = _calculateMatchType(currentUser, profile);

    return Container(
      padding: Spacing.paddingLG,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.borderLG,
        boxShadow: context.isDarkMode ? [] : AppShadows.sm,
      ),
      child: Column(
        children: [
          _buildLanguageComparison(context),
          if (matchType != MatchType.none) ...[
            Spacing.gapMD,
            _buildMatchMessage(context, matchType),
          ],
        ],
      ),
    );
  }

  MatchType _calculateMatchType(User currentUser, Community profile) {
    final iLearnTheirNative = currentUser.language_to_learn == profile.native_language;
    final theyLearnMyNative = profile.language_to_learn == currentUser.native_language;

    if (iLearnTheirNative && theyLearnMyNative) return MatchType.perfect;
    if (iLearnTheirNative) return MatchType.youLearnTheirs;
    if (theyLearnMyNative) return MatchType.theyLearnYours;
    if (currentUser.native_language == profile.native_language) return MatchType.sameNative;
    return MatchType.none;
  }
}

enum MatchType { perfect, youLearnTheirs, theyLearnYours, sameNative, none }
```

### Language Level Display

Display language proficiency using dot indicators:
- A1/A2: 1-2 dots (Beginner)
- B1/B2: 3-4 dots (Intermediate)
- C1/C2: 5 dots (Advanced)

```dart
Widget _buildLevelDots(String? level, BuildContext context) {
  final filledDots = _levelToDotsCount(level);
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (i) => Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.only(right: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: i < filledDots ? AppColors.primary : context.dividerColor,
      ),
    )),
  );
}
```

### Theme Support
- Card background: `context.surfaceColor`
- Language chip bg: `context.containerColor`
- Match message bg: Success/accent color with 0.1 opacity
- Level dots: `AppColors.primary` (filled), `context.dividerColor` (empty)

---

## Section 3: Engagement Stats Bar

### Purpose
Display trust and engagement indicators to help users assess activity level.

### Placement
Below Language Match Card, above action buttons.

### Visual Design

```
┌─────────────────────────────────────────────┐
│  🟢 Online    ⚡ 95%     ⏱️ <1hr    🆕 New   │
│    now       replies    response           │
└─────────────────────────────────────────────┘
```

### Indicators

| Indicator | Field | Display Logic |
|-----------|-------|---------------|
| Online Status | `isOnline`, `lastActive` | 🟢 Online / 🟡 Active Xm ago / ⚫ Active Xd ago |
| Response Rate | `responseRate` | ⚡ X% (green >80%, yellow >50%, gray <50%) |
| Reply Speed | Future field | ⏱️ <1hr / <1day / ~3days |
| New User | `isNewUser` | 🆕 New (if joined <7 days) |

**Note:** The `lastActiveText` getter already exists on the `Community` model and returns formatted strings like "Online now", "Active 5m ago", etc.

### Widget Implementation

```dart
class EngagementStatsBar extends StatelessWidget {
  final Community profile;

  const EngagementStatsBar({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: AppRadius.borderMD,
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildOnlineStatus(context),
          if (profile.responseRate != null) _buildResponseRate(context),
          if (profile.isNewUser) _buildNewBadge(context),
        ],
      ),
    );
  }

  Widget _buildOnlineStatus(BuildContext context) {
    final color = profile.isOnline
        ? AppColors.online
        : _getLastActiveColor(profile.lastActive);
    final text = profile.isOnline
        ? 'Online now'
        : profile.lastActiveText;

    return _StatChip(
      icon: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
      value: text,
    );
  }

  Widget _buildResponseRate(BuildContext context) {
    final rate = profile.responseRate!;
    final color = rate > 80 ? AppColors.success
                : rate > 50 ? AppColors.warning
                : AppColors.gray500;

    return _StatChip(
      icon: Icon(Icons.bolt, size: 14, color: color),
      value: '${rate.round()}% replies',
    );
  }

  Widget _buildNewBadge(BuildContext context) {
    return _StatChip(
      icon: const Text('🆕', style: TextStyle(fontSize: 12)),
      value: 'New',
    );
  }
}

/// Helper widget for displaying stat indicators
class _StatChip extends StatelessWidget {
  final Widget icon;
  final String value;

  const _StatChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        Spacing.hGapXS,
        Text(value, style: context.captionSmall),
      ],
    );
  }
}
```

### Conditional Display
- Only show indicators that have data
- Minimum: always show online/last active status
- Hide response rate if null
- Show new badge only if `isNewUser` is true

### Theme Support
- Container: `context.containerColor`
- Border: `context.dividerColor`
- Online dot: `AppColors.online` / `AppColors.away` / `AppColors.offline`
- Text: `context.textSecondary`

---

## Section 4: Shared Interests Enhancement

### Purpose
Highlight topics the current user shares with the profile being viewed.

### Current State
Existing `_buildInterestsSection()` shows profile's topics as chips without indicating shared ones.

### Enhanced Design

```
┌─────────────────────────────────────────────┐
│  🎯 Interests                               │
├─────────────────────────────────────────────┤
│  ✨ 3 shared interests                      │
│                                             │
│  [🎵 Music ✓] [🎮 Gaming ✓] [✈️ Travel ✓]   │  ← Highlighted
│  [📚 Reading] [🎬 Movies] [☕ Coffee]        │  ← Normal
└─────────────────────────────────────────────┘
```

### Implementation

Modify existing `_buildInterestsSection()` method:

```dart
Widget _buildInterestsSection() {
  if (_community.topics.isEmpty) return const SizedBox.shrink();

  // Get current user's topics
  final currentUser = ref.watch(userProvider).valueOrNull;
  final myTopics = currentUser?.topics.toSet() ?? {};
  final theirTopics = _community.topics.toSet();

  // Calculate shared vs unique
  final sharedTopics = myTopics.intersection(theirTopics).toList();
  final uniqueTopics = theirTopics.difference(myTopics).toList();

  // Sort: shared first
  final sortedTopics = [...sharedTopics, ...uniqueTopics];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header with shared count
      Row(
        children: [
          // ... existing header icon ...
          Text('Interests', style: context.titleMedium),
          if (sharedTopics.isNotEmpty) ...[
            Spacing.hGapSM,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: AppRadius.borderRound,
              ),
              child: Text(
                '${sharedTopics.length} shared',
                style: context.captionSmall.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
      Spacing.gapSM,
      // Topic chips
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: sortedTopics.map((topicId) {
          final isShared = sharedTopics.contains(topicId);
          return _buildTopicChip(context, topicId, isShared: isShared);
        }).toList(),
      ),
    ],
  );
}

Widget _buildTopicChip(BuildContext context, String topicId, {bool isShared = false}) {
  final topic = Topic.defaultTopics.firstWhere(
    (t) => t.id == topicId,
    orElse: () => Topic(id: topicId, name: topicId, icon: '🏷️', category: 'other'),
  );

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: isShared
          ? AppColors.primary.withOpacity(0.1)
          : context.containerColor,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: isShared ? AppColors.primary : context.dividerColor,
        width: isShared ? 1.5 : 1,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(topic.icon, style: const TextStyle(fontSize: 14)),
        Spacing.hGapXS,
        Text(topic.name, style: context.labelMedium.copyWith(
          color: isShared ? AppColors.primary : null,
        )),
        if (isShared) ...[
          Spacing.hGapXS,
          Icon(Icons.check, size: 14, color: AppColors.primary),
        ],
      ],
    ),
  );
}
```

### Edge Cases
- Current user has no topics → show all as normal
- No shared topics → show "Explore their interests" subheader
- Profile has no topics → hide section entirely

---

## Section 5: Conversation Starters

### Purpose
Provide smart suggestions to help users start conversations.

### Placement
After Bio/Languages section, before Moments grid.

### Visual Design

```
┌─────────────────────────────────────────────┐
│  💡 Conversation Starters                   │
├─────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────┐│
│  │ 🎵 "Ask about their favorite K-pop     ││
│  │     artists - you both love Music!"    ││
│  │                          [Copy] [Send] ││
│  └─────────────────────────────────────────┘│
└─────────────────────────────────────────────┘
```

### Starter Generation Priority

| Priority | Source | Template |
|----------|--------|----------|
| 1 | Shared topics | "You both love {topic} - ask about their favorite..." |
| 2 | Recent moment | "They shared about {topic} - great conversation opener!" |
| 3 | Language match | "You're learning {their native} - ask for tips!" |
| 4 | Location | "They're from {city} - ask about local culture!" |
| 5 | MBTI match | "You're both {MBTI} - compare personality insights!" |

### Widget Implementation

```dart
class ConversationStartersCard extends ConsumerWidget {
  final Community profile;

  const ConversationStartersCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(userProvider).valueOrNull;
    final starters = _generateStarters(currentUser, profile);

    if (starters.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: AppRadius.borderSM,
              ),
              child: const Icon(Icons.lightbulb_outline,
                color: AppColors.secondary, size: 18),
            ),
            Spacing.hGapSM,
            Text('Conversation Starters', style: context.titleMedium),
          ],
        ),
        Spacing.gapSM,
        // Starters list (max 3)
        ...starters.take(3).map((starter) => _buildStarterCard(context, starter)),
      ],
    );
  }

  List<StarterSuggestion> _generateStarters(User? currentUser, Community profile) {
    final starters = <StarterSuggestion>[];

    if (currentUser != null) {
      // 1. Shared topics
      final shared = currentUser.topics.toSet().intersection(profile.topics.toSet());
      for (final topicId in shared.take(1)) {
        final topic = Topic.defaultTopics.firstWhere((t) => t.id == topicId);
        starters.add(StarterSuggestion(
          icon: topic.icon,
          text: 'You both love ${topic.name} - ask about their favorite!',
          actionText: 'Hey! I saw you\'re into ${topic.name} too. What\'s your favorite?',
          type: StarterType.sharedTopic,
        ));
      }

      // 2. Language match
      if (currentUser.language_to_learn == profile.native_language) {
        starters.add(StarterSuggestion(
          icon: '🗣️',
          text: 'You\'re learning ${profile.native_language} - ask for tips!',
          actionText: 'Hi! I\'m learning ${profile.native_language}. Any tips for a beginner?',
          type: StarterType.language,
        ));
      }
    }

    // 3. Location-based
    if (profile.location.city.isNotEmpty) {
      starters.add(StarterSuggestion(
        icon: '📍',
        text: 'They\'re from ${profile.location.city} - ask about local culture!',
        actionText: 'Hey! What\'s ${profile.location.city} like? I\'d love to hear about it!',
        type: StarterType.location,
      ));
    }

    // 4. Fallback
    if (starters.isEmpty) {
      starters.add(StarterSuggestion(
        icon: '👋',
        text: 'Say hi and introduce yourself!',
        actionText: 'Hi! I\'d love to practice languages together. How are you?',
        type: StarterType.generic,
      ));
    }

    return starters;
  }

  Widget _buildStarterCard(BuildContext context, StarterSuggestion starter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: Spacing.paddingMD,
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: AppRadius.borderMD,
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(starter.icon, style: const TextStyle(fontSize: 16)),
              Spacing.hGapSM,
              Expanded(
                child: Text(starter.text, style: context.bodyMedium),
              ),
            ],
          ),
          Spacing.gapSM,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _copyToClipboard(context, starter.actionText),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy'),
                style: TextButton.styleFrom(
                  foregroundColor: context.textSecondary,
                ),
              ),
              Spacing.hGapSM,
              TextButton.icon(
                onPressed: () => _sendMessage(context, starter.actionText),
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Send'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StarterSuggestion {
  final String icon;
  final String text;
  final String? actionText;
  final StarterType type;

  const StarterSuggestion({
    required this.icon,
    required this.text,
    this.actionText,
    required this.type,
  });
}

enum StarterType { sharedTopic, recentMoment, language, location, mbti, generic }
```

### Actions
- **Copy**: Copy `actionText` to clipboard, show snackbar confirmation
- **Send**: Navigate to `ChatScreen` with pre-filled message

---

## Final Layout

```
┌────────────────────────────────┐
│ Hero Map + Avatar              │ (existing)
├────────────────────────────────┤
│ Name + VIP Badge               │ (existing)
├────────────────────────────────┤
│ 🔄 Language Match Card         │ ← NEW
├────────────────────────────────┤
│ ⚡ Engagement Stats Bar        │ ← NEW
├────────────────────────────────┤
│ Action Buttons                 │ (existing)
├────────────────────────────────┤
│ Stats (Followers/Following)    │ (existing)
├────────────────────────────────┤
│ 🎯 Shared Interests            │ ← ENHANCED
├────────────────────────────────┤
│ Bio + Languages Cards          │ (existing)
├────────────────────────────────┤
│ Personal Info (MBTI, Blood)    │ (existing)
├────────────────────────────────┤
│ 💡 Conversation Starters       │ ← NEW
├────────────────────────────────┤
│ Moments Grid                   │ (existing)
└────────────────────────────────┘
```

---

## Testing Checklist

- [ ] Light mode: All sections render correctly
- [ ] Dark mode: All sections render correctly with proper contrast
- [ ] Language Match Card shows correct match type
- [ ] Engagement stats hide gracefully when data is missing
- [ ] Shared interests highlight correctly
- [ ] Conversation starters generate based on available data
- [ ] Copy action works and shows snackbar
- [ ] Send action navigates to chat with pre-filled message
- [ ] community_card.dart renders correctly in both themes
- [ ] No hardcoded colors remain

---

## Future Considerations

- Backend: Calculate and store `responseRate` based on message history
- Backend: Add `averageReplyTime` field for reply speed indicator
- Analytics: Track which conversation starters lead to actual conversations
- A/B test: Match card placement (above vs below action buttons)
