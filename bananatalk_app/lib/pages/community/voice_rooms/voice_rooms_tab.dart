import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/community/voice_room_model.dart';
import 'package:bananatalk_app/models/community/topic_model.dart';
import 'package:bananatalk_app/widgets/community/voice_room_card.dart';
import 'package:bananatalk_app/widgets/community/user_skeleton.dart';
import 'package:bananatalk_app/pages/community/voice_rooms/voice_room_screen.dart';
import 'package:bananatalk_app/pages/community/voice_rooms/create_room_sheet.dart';
import 'package:bananatalk_app/providers/voice_room_provider.dart';
import 'package:bananatalk_app/providers/voice_room_languages_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/pages/community/widgets/community_snackbar.dart';
import 'package:bananatalk_app/pages/community/widgets/community_filter_chip.dart';
import 'package:bananatalk_app/pages/community/widgets/community_empty_state.dart';
import 'package:bananatalk_app/pages/community/widgets/community_error_state.dart';
import 'package:bananatalk_app/pages/community/voice_rooms/upcoming_section.dart';

/// Voice Rooms Tab
class VoiceRoomsTab extends ConsumerStatefulWidget {
  const VoiceRoomsTab({super.key});

  @override
  ConsumerState<VoiceRoomsTab> createState() => _VoiceRoomsTabState();
}

class _VoiceRoomsTabState extends ConsumerState<VoiceRoomsTab> {
  late Future<List<VoiceRoom>> _roomsFuture;
  List<VoiceRoom> _scheduledRooms = [];

  String? _selectedLanguage;
  String? _selectedTopic;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _roomsFuture = _fetchWithFilters();
    _loadScheduled();
  }

  Future<void> _loadScheduled() async {
    try {
      final scheduled = await ref.read(voiceRoomProvider).fetchScheduledRooms();
      if (mounted) setState(() => _scheduledRooms = scheduled);
    } catch (_) {
      // Silent fail — UpcomingSection hides itself when rooms is empty
    }
  }

  Future<List<VoiceRoom>> _fetchWithFilters() {
    return ref
        .read(voiceRoomProvider)
        .fetchRooms(language: _selectedLanguage, topic: _selectedTopic, category: _selectedCategory);
  }

  Future<void> _refreshRooms() async {
    setState(() {
      _roomsFuture = _fetchWithFilters();
    });
    await _loadScheduled();
  }

  void _setLanguageFilter(String? language) {
    setState(() {
      _selectedLanguage = language;
      _roomsFuture = _fetchWithFilters();
    });
  }

  void _setTopicFilter(String? topic) {
    setState(() {
      _selectedTopic = topic;
      _roomsFuture = _fetchWithFilters();
    });
  }

  void _setCategoryFilter(String? category) {
    setState(() {
      _selectedCategory = category;
      _roomsFuture = _fetchWithFilters();
    });
  }

  void _createRoom() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => CreateRoomSheet(
        onCreateRoom: (
          title,
          topic,
          language,
          maxParticipants,
          scheduledFor,
          category,
        ) async {
          Navigator.pop(sheetContext);
          try {
            final request = CreateRoomRequest(
              title: title,
              topic: topic,
              language: language,
              maxParticipants: maxParticipants,
              scheduledFor: scheduledFor,
              category: category,
            );
            final room = await ref.read(voiceRoomProvider).createRoom(request);
            if (mounted) {
              showCommunitySnackBar(
                context,
                message: l10n.roomCreated,
                type: CommunitySnackBarType.success,
              );
              if (scheduledFor != null) {
                await _loadScheduled();
              } else {
                _refreshRooms();
                if (mounted) _joinRoom(room);
              }
            }
          } catch (e) {
            if (mounted) {
              showCommunitySnackBar(
                context,
                message: l10n.failedToCreateRoom,
                type: CommunitySnackBarType.error,
              );
            }
          }
        },
      ),
    );
  }

  void _joinRoom(VoiceRoom room) async {
    await Navigator.push(
      context,
      AppPageRoute(builder: (_) => VoiceRoomScreen(room: room)),
    );
    if (mounted) _refreshRooms();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<List<VoiceRoom>>(
        future: _roomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
              children: [
                _buildFilters(l10n),
                const Expanded(child: UserListSkeleton(count: 5)),
              ],
            );
          }
          if (snapshot.hasError) {
            return CommunityErrorState(
              message: l10n.errorLoadingRooms,
              onRetry: _refreshRooms,
              retryLabel: l10n.tryAgain,
            );
          }
          final rooms = snapshot.data ?? [];
          if (rooms.isEmpty &&
              _selectedLanguage == null &&
              _selectedTopic == null &&
              _selectedCategory == null) {
            return _buildEmptyState(l10n);
          }
          return _buildRoomsList(rooms, l10n);
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton.extended(
          heroTag: 'voice_rooms_tab_create_fab',
          onPressed: _createRoom,
          backgroundColor: const Color(0xFF00BFA5),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text(
            l10n.createRoom,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Language filter
        Consumer(
          builder: (context, ref, _) {
            final asyncLangs = ref.watch(voiceRoomLanguagesProvider);
            return asyncLangs.when(
              data: (languages) => _buildLanguageChips(l10n, languages),
              loading: () => const SizedBox(height: 44),
              error: (_, __) => _buildLanguageChips(l10n, kVoiceRoomLanguagesFallback),
            );
          },
        ),
        const SizedBox(height: 8),
        // Topic filter
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              CommunityFilterChip(
                label: l10n.allTopics,
                icon: Icons.tag_rounded,
                isSelected: _selectedTopic == null,
                onTap: () => _setTopicFilter(null),
              ),
              const SizedBox(width: 8),
              ...Topic.defaultTopics
                  .take(12)
                  .map(
                    (topic) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CommunityFilterChip(
                        label: topic.name,
                        emoji: topic.icon,
                        isSelected: _selectedTopic == topic.id,
                        onTap: () => _setTopicFilter(
                          _selectedTopic == topic.id ? null : topic.id,
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Category filter
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              CommunityFilterChip(
                label: l10n.allCategories,
                isSelected: _selectedCategory == null,
                onTap: () => _setCategoryFilter(null),
              ),
              const SizedBox(width: 8),
              ...['casual', 'language_practice', 'topic', 'qa'].map((cat) {
                final label = switch (cat) {
                  'casual' => l10n.categoryCasual,
                  'language_practice' => l10n.categoryLanguagePractice,
                  'topic' => l10n.categoryTopic,
                  'qa' => l10n.categoryQA,
                  _ => cat,
                };
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CommunityFilterChip(
                    label: label,
                    isSelected: _selectedCategory == cat,
                    onTap: () => _setCategoryFilter(
                      _selectedCategory == cat ? null : cat,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLanguageChips(AppLocalizations l10n, List<String> languages) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          CommunityFilterChip(
            label: l10n.allLanguages,
            icon: Icons.language_rounded,
            isSelected: _selectedLanguage == null,
            onTap: () => _setLanguageFilter(null),
          ),
          const SizedBox(width: 8),
          ...languages.map(
            (lang) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CommunityFilterChip(
                label: lang,
                isSelected: _selectedLanguage == lang,
                onTap: () => _setLanguageFilter(
                  _selectedLanguage == lang ? null : lang,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsList(List<VoiceRoom> rooms, AppLocalizations l10n) {
    return RefreshIndicator(
      onRefresh: _refreshRooms,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(rooms.length)
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(
                  begin: -0.05,
                  end: 0,
                  duration: 300.ms,
                  curve: Curves.easeOutCubic,
                ),
          ),
          SliverToBoxAdapter(
            child: _buildFilters(
              l10n,
            ).animate().fadeIn(duration: 300.ms, delay: 80.ms),
          ),
          SliverToBoxAdapter(
            child: UpcomingSection(
              rooms: _scheduledRooms,
              onRsvpToggle: _loadScheduled,
            ),
          ),
          if (rooms.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: context.textMuted,
                    ),
                    Spacing.gapMD,
                    Text(l10n.noActiveRooms, style: context.titleMedium),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final room = rooms[index];
                  return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: VoiceRoomCard(
                          room: room,
                          onTap: () => _joinRoom(room),
                          onJoin: () => _joinRoom(room),
                        ),
                      )
                      .animate()
                      .fadeIn(
                        duration: 350.ms,
                        delay: Duration(
                          milliseconds: (index * 60).clamp(0, 500),
                        ),
                      )
                      .slideY(
                        begin: 0.05,
                        end: 0,
                        duration: 350.ms,
                        delay: Duration(
                          milliseconds: (index * 60).clamp(0, 500),
                        ),
                        curve: Curves.easeOutCubic,
                      );
                }, childCount: rooms.length),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader(int roomCount) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE91E63).withValues(alpha: 0.1),
            const Color(0xFF9C27B0).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: AppRadius.borderMD,
        border: Border.all(
          color: const Color(0xFFE91E63).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
              ),
              borderRadius: AppRadius.borderMD,
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.white),
          ),
          Spacing.hGapMD,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.voiceRooms, style: context.titleMedium),
                Text(l10n.voiceRoomsDescription, style: context.caption),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE91E63).withValues(alpha: 0.15),
              borderRadius: AppRadius.borderMD,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE91E63),
                    shape: BoxShape.circle,
                  ),
                ),
                Spacing.hGapSM,
                Text(
                  l10n.liveRoomsCount(roomCount),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE91E63),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return CommunityEmptyState(
      icon: Icons.mic_off_rounded,
      title: l10n.noActiveRooms,
      subtitle: l10n.noActiveRoomsDescription,
      action: ElevatedButton.icon(
        onPressed: _createRoom,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.startRoom),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00BFA5),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMD),
        ),
      ),
    );
  }
}
