import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/room.dart';
import 'package:bananatalk_app/pages/community/rooms/create_topic_room_sheet.dart';
import 'package:bananatalk_app/pages/community/rooms/room_card.dart';
import 'package:bananatalk_app/pages/community/rooms/room_screen.dart';
import 'package:bananatalk_app/pages/community/widgets/community_empty_state.dart';
import 'package:bananatalk_app/pages/community/widgets/community_error_state.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/rooms_provider.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:bananatalk_app/widgets/community/user_skeleton.dart';

/// Directory of public Language Rooms ("hubs") plus user-created topic
/// rooms nested under them — Workstream D.
///
/// Lists every hub with member/online counts; the caller's auto-joined hub
/// is pinned first (backend already orders it that way; the provider
/// defensively re-pins client-side too). Rooms are then grouped by
/// `targetLanguage` — each language section shows its seeded hub first,
/// followed by any user-created topic rooms for that language. Tapping any
/// room opens the real `RoomScreen` (Task 10). The "＋ New room" FAB opens
/// `showCreateTopicRoomSheet` to create a topic room, then refreshes the
/// directory and jumps straight into the new room.
class RoomsDirectoryScreen extends ConsumerWidget {
  const RoomsDirectoryScreen({super.key});

  Future<void> _createTopicRoom(BuildContext context, WidgetRef ref) async {
    // Best-effort: prefill the language picker with the caller's learning
    // language so most people don't have to touch the dropdown at all.
    // Falls back to the sheet's own default when the profile hasn't loaded
    // yet or has no learning language set.
    final me = ref.read(userProvider).valueOrNull;
    final presetLanguage =
        (me != null && me.language_to_learn.isNotEmpty)
            ? me.language_to_learn
            : null;

    final room = await showCreateTopicRoomSheet(
      context,
      presetLanguage: presetLanguage,
    );
    if (room == null) return;

    await ref.read(roomsProvider.notifier).refresh();
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RoomScreen(room: room)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      // Lift the FAB above the floating "swimming" tab pill (see TabBarMenu),
      // which sits ~60px tall at the bottom — a default-position FAB overlaps it.
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton.extended(
          heroTag: 'rooms-directory-fab',
          onPressed: () => _createTopicRoom(context, ref),
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.roomsNewRoom),
        ),
      ),
      body: roomsAsync.when(
        loading: () => const UserListSkeleton(count: 6),
        error: (error, _) => CommunityErrorState(
          message: l10n.roomsCouldNotLoad,
          onRetry: () => ref.read(roomsProvider.notifier).refresh(),
          retryLabel: l10n.chatRetry,
        ),
        data: (rooms) {
          if (rooms.isEmpty) {
            return CommunityEmptyState(
              icon: Icons.forum_outlined,
              title: l10n.roomsEmptyTitle,
              subtitle: l10n.roomsEmptySubtitle,
            );
          }
          return _RoomsList(rooms: rooms);
        },
      ),
    );
  }
}

/// A `targetLanguage` section: its hub(s) first, then user-created topic
/// rooms for that language, in the order they first appeared in the
/// (already pinned-first) flat room list.
class _LanguageSection {
  const _LanguageSection({required this.language, required this.rooms});

  final String language;
  final List<Room> rooms;
}

/// Groups [rooms] by `targetLanguage`, preserving first-seen order per
/// language (so the section containing the caller's pinned hub stays
/// first) and putting hubs before topic rooms within each section.
List<_LanguageSection> _groupByLanguage(
  List<Room> rooms, {
  required String otherLabel,
}) {
  final order = <String>[];
  final byLanguage = <String, List<Room>>{};
  for (final room in rooms) {
    final language = room.targetLanguage.isEmpty ? otherLabel : room.targetLanguage;
    final bucket = byLanguage.putIfAbsent(language, () {
      order.add(language);
      return [];
    });
    bucket.add(room);
  }
  return order.map((language) {
    final bucket = byLanguage[language]!;
    final hubs = bucket.where((r) => !r.isTopicRoom).toList();
    final topics = bucket.where((r) => r.isTopicRoom).toList();
    return _LanguageSection(language: language, rooms: [...hubs, ...topics]);
  }).toList();
}

class _RoomsList extends ConsumerStatefulWidget {
  const _RoomsList({required this.rooms});

  final List<Room> rooms;

  @override
  ConsumerState<_RoomsList> createState() => _RoomsListState();
}

class _RoomsListState extends ConsumerState<_RoomsList> {
  /// Selected language filter; null = "All".
  String? _selectedLanguage;

  Future<void> _refresh() => ref.read(roomsProvider.notifier).refresh();

  void _openRoom(BuildContext context, Room room) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RoomScreen(room: room)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allSections = _groupByLanguage(widget.rooms, otherLabel: l10n.other);
    final languages = allSections.map((s) => s.language).toList();

    // Drop a stale selection (e.g. its last room was deleted / filtered away).
    final selected =
        (_selectedLanguage != null && languages.contains(_selectedLanguage))
            ? _selectedLanguage
            : null;

    final sections = <_LanguageSection>[];
    if (selected == null) {
      // "🔥 Popular" — the most-joined rooms across all languages, on top.
      // They also still appear in their own language section below (featured +
      // browse), which is expected.
      final popular = [...widget.rooms]
        ..sort((a, b) => b.memberCount.compareTo(a.memberCount));
      final top = popular.where((r) => r.memberCount > 0).take(5).toList();
      if (top.length >= 2) {
        sections.add(_LanguageSection(language: '🔥 ${l10n.popular}', rooms: top));
      }
      sections.addAll(allSections);
    } else {
      sections.addAll(allSections.where((s) => s.language == selected));
    }

    return Column(
      children: [
        // Only worth showing the filter bar once there's more than one language.
        if (languages.length > 1)
          _LanguageFilterBar(
            languages: languages,
            selected: selected,
            onSelected: (lang) => setState(() => _selectedLanguage = lang),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            // When filtered to one language the per-section header is
            // redundant (the chip already names it), so hide it.
            child: _buildList(context, sections, hideHeaders: selected != null),
          ),
        ),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    List<_LanguageSection> sections, {
    required bool hideHeaders,
  }) {
    // Flatten sections into a single item list (language header or Room) so
    // the existing staggered fade/slide-in animation keeps working per row.
    final items = <Object>[];
    for (final section in sections) {
      if (!hideHeaders) items.add(section.language);
      items.addAll(section.rooms);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.md,
        Spacing.md,
        80, // keep the last card clear of the FAB
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final delay = Duration(milliseconds: (index * 40).clamp(0, 400));

        if (item is String) {
            return Padding(
              padding: EdgeInsets.only(
                top: index == 0 ? 0 : Spacing.md,
                bottom: Spacing.sm,
                left: 4,
              ),
              child: Text(
                LanguageFlags.displayName(item),
                style: context.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.textSecondary,
                ),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: delay);
          }

          final room = item as Room;
          return Padding(
                padding: EdgeInsets.only(
                  left: room.isTopicRoom ? Spacing.md : 0,
                  bottom: Spacing.sm,
                ),
                child: RoomCard(
                  room: room,
                  isPinned: room.isMember,
                  onTap: () => _openRoom(context, room),
                ),
              )
              .animate()
              .fadeIn(duration: 300.ms, delay: delay)
              .slideY(
                begin: 0.05,
                end: 0,
                duration: 300.ms,
                delay: delay,
                curve: Curves.easeOutCubic,
              );
        },
      );
  }
}

/// Horizontal language filter chips ("All · 🇰🇷 Korean · 🇬🇧 English …") above
/// the rooms directory. `null` value = the "All" chip.
class _LanguageFilterBar extends StatelessWidget {
  const _LanguageFilterBar({
    required this.languages,
    required this.selected,
    required this.onSelected,
  });

  final List<String> languages;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 8),
        children: [
          _chip(
            context,
            label: AppLocalizations.of(context)!.communityTabAll,
            value: null,
          ),
          for (final lang in languages)
            _chip(
              context,
              label:
                  '${LanguageFlags.getFlagByName(lang)} ${LanguageFlags.displayName(lang)}',
              value: lang,
            ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required String? value,
  }) {
    final isSelected = selected == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(value),
        showCheckmark: false,
        backgroundColor: context.containerColor,
        selectedColor: AppColors.primary,
        side: BorderSide(
          color: isSelected ? AppColors.primary : context.dividerColor,
        ),
        labelStyle: context.bodyMedium.copyWith(
          color: isSelected ? Colors.white : context.textPrimary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
