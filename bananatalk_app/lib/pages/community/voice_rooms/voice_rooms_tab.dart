import 'package:flutter/material.dart';
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

/// Voice Rooms Tab
class VoiceRoomsTab extends ConsumerStatefulWidget {
  const VoiceRoomsTab({super.key});

  @override
  ConsumerState<VoiceRoomsTab> createState() => _VoiceRoomsTabState();
}

class _VoiceRoomsTabState extends ConsumerState<VoiceRoomsTab> {
  late Future<List<VoiceRoom>> _roomsFuture;

  @override
  void initState() {
    super.initState();
    _roomsFuture = ref.read(voiceRoomProvider).fetchRooms();
  }

  Future<void> _refreshRooms() async {
    setState(() {
      _roomsFuture = ref.read(voiceRoomProvider).fetchRooms();
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
            final room = await ref.read(voiceRoomProvider).createRoom(request);
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
              // Navigate to the newly created room
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

  void _joinRoom(VoiceRoom room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoiceRoomScreen(room: room),
      ),
    );
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
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00BFA5),
              ),
            );
          }
          if (snapshot.hasError) {
            return _buildErrorState(l10n, snapshot.error.toString());
          }
          final rooms = snapshot.data ?? [];
          return rooms.isEmpty ? _buildEmptyState() : _buildRoomsList(rooms);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
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

  Widget _buildRoomsList(List<VoiceRoom> rooms) {
    return RefreshIndicator(
      onRefresh: _refreshRooms,
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(rooms.length),
          ),
          // Rooms list
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
                  );
                },
                childCount: rooms.length,
              ),
            ),
          ),
          // Bottom padding for FAB
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
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
            const Color(0xFFE91E63).withOpacity(0.1),
            const Color(0xFF9C27B0).withOpacity(0.05),
          ],
        ),
        borderRadius: AppRadius.borderMD,
        border: Border.all(
          color: const Color(0xFFE91E63).withOpacity(0.2),
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
              color: const Color(0xFFE91E63).withOpacity(0.15),
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
