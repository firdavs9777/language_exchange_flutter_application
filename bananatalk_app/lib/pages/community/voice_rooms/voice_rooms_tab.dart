import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/community/voice_room_model.dart';
import 'package:bananatalk_app/models/community/topic_model.dart';
import 'package:bananatalk_app/widgets/community/voice_room_card.dart';
import 'package:bananatalk_app/pages/community/voice_rooms/voice_room_screen.dart';
import 'package:bananatalk_app/pages/community/voice_rooms/create_room_sheet.dart';
import 'package:bananatalk_app/providers/voice_room_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

/// Voice Rooms Tab
class VoiceRoomsTab extends ConsumerStatefulWidget {
  const VoiceRoomsTab({super.key});

  @override
  ConsumerState<VoiceRoomsTab> createState() => _VoiceRoomsTabState();
}

class _VoiceRoomsTabState extends ConsumerState<VoiceRoomsTab> {
  late Future<List<VoiceRoom>> _roomsFuture;

  // Filter state
  String? _selectedLanguage;
  String? _selectedTopic;

  static const List<String> _languages = [
    'English',
    'Korean',
    'Japanese',
    'Chinese',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Russian',
    'Arabic',
    'Hindi',
    'Uzbek',
  ];

  @override
  void initState() {
    super.initState();
    _roomsFuture = _fetchWithFilters();
  }

  Future<List<VoiceRoom>> _fetchWithFilters() {
    return ref.read(voiceRoomProvider).fetchRooms(
          language: _selectedLanguage,
          topic: _selectedTopic,
        );
  }

  Future<void> _refreshRooms() async {
    setState(() {
      _roomsFuture = _fetchWithFilters();
    });
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

  void _createRoom() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => CreateRoomSheet(
        onCreateRoom: (title, topic, language, maxParticipants) async {
          Navigator.pop(sheetContext);
          try {
            final request = CreateRoomRequest(
              title: title,
              topic: topic,
              language: language,
              maxParticipants: maxParticipants,
            );
            final room =
                await ref.read(voiceRoomProvider).createRoom(request);
            _refreshRooms();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.roomCreated),
                  backgroundColor: const Color(0xFF00BFA5),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderMD,
                  ),
                ),
              );
              _joinRoom(room);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.failedToCreateRoom),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderMD,
                  ),
                ),
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
      AppPageRoute(
        builder: (_) => VoiceRoomScreen(room: room),
      ),
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
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00BFA5),
                    ),
                  ),
                ),
              ],
            );
          }
          if (snapshot.hasError) {
            return _buildErrorState(l10n, snapshot.error.toString());
          }
          final rooms = snapshot.data ?? [];
          if (rooms.isEmpty && _selectedLanguage == null && _selectedTopic == null) {
            return _buildEmptyState();
          }
          return _buildRoomsList(rooms, l10n);
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton.extended(
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
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _FilterChip(
                label: l10n.allLanguages,
                icon: Icons.language_rounded,
                isSelected: _selectedLanguage == null,
                onTap: () => _setLanguageFilter(null),
              ),
              const SizedBox(width: 8),
              ..._languages.map((lang) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: lang,
                      isSelected: _selectedLanguage == lang,
                      onTap: () => _setLanguageFilter(
                          _selectedLanguage == lang ? null : lang),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Topic filter
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _FilterChip(
                label: l10n.allTopics,
                icon: Icons.tag_rounded,
                isSelected: _selectedTopic == null,
                onTap: () => _setTopicFilter(null),
              ),
              const SizedBox(width: 8),
              ...Topic.defaultTopics.take(12).map((topic) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: topic.name,
                      emoji: topic.icon,
                      isSelected: _selectedTopic == topic.id,
                      onTap: () => _setTopicFilter(
                          _selectedTopic == topic.id ? null : topic.id),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildErrorState(AppLocalizations l10n, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red,
            ),
            Spacing.gapLG,
            Text(
              l10n.errorLoadingRooms,
              style: context.titleMedium,
              textAlign: TextAlign.center,
            ),
            Spacing.gapMD,
            ElevatedButton.icon(
              onPressed: _refreshRooms,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.tryAgain),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsList(List<VoiceRoom> rooms, AppLocalizations l10n) {
    return RefreshIndicator(
      onRefresh: _refreshRooms,
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(rooms.length)
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: -0.05, end: 0, duration: 300.ms, curve: Curves.easeOutCubic),
          ),
          // Filters
          SliverToBoxAdapter(
            child: _buildFilters(l10n)
                .animate()
                .fadeIn(duration: 300.ms, delay: 80.ms),
          ),
          // Rooms list or filtered empty state
          if (rooms.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    Spacing.gapMD,
                    Text(
                      l10n.noActiveRooms,
                      style: context.titleMedium,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
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
                          delay: Duration(milliseconds: (index * 60).clamp(0, 500)),
                        )
                        .slideY(
                          begin: 0.05,
                          end: 0,
                          duration: 350.ms,
                          delay: Duration(milliseconds: (index * 60).clamp(0, 500)),
                          curve: Curves.easeOutCubic,
                        );
                  },
                  childCount: rooms.length,
                ),
              ),
            ),
          // Bottom padding for FAB
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
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
            child: const Icon(
              Icons.mic_rounded,
              color: Colors.white,
            ),
          ),
          Spacing.hGapMD,
          Expanded(
            child: Builder(
              builder: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.voiceRooms,
                    style: context.titleMedium,
                  ),
                  Text(
                    l10n.voiceRoomsDescription,
                    style: context.caption,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
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

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                ),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.mic_off_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),
            Spacing.gapLG,
            Builder(
              builder: (context) => Text(
                l10n.noActiveRooms,
                style: context.titleLarge,
              ),
            ),
            Spacing.gapMD,
            Builder(
              builder: (context) => Text(
                l10n.noActiveRoomsDescription,
                textAlign: TextAlign.center,
                style: context.bodyMedium.copyWith(
                  color: context.textSecondary,
                ),
              ),
            ),
            Spacing.gapXL,
            ElevatedButton.icon(
              onPressed: _createRoom,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.startRoom),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderMD,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00BFA5).withValues(alpha: 0.15)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00BFA5)
                : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? const Color(0xFF00BFA5)
                    : Colors.grey[600],
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF00BFA5)
                    : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
