import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/community/voice_room_model.dart';
import 'package:bananatalk_app/models/community/topic_model.dart';
import 'package:bananatalk_app/widgets/community/voice_room_card.dart';
import 'package:bananatalk_app/pages/community/voice_rooms/voice_room_screen.dart';
import 'package:bananatalk_app/pages/community/voice_rooms/create_room_sheet.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Voice Rooms Tab
class VoiceRoomsTab extends ConsumerStatefulWidget {
  const VoiceRoomsTab({super.key});

  @override
  ConsumerState<VoiceRoomsTab> createState() => _VoiceRoomsTabState();
}

class _VoiceRoomsTabState extends ConsumerState<VoiceRoomsTab> {
  // Mock data for voice rooms (replace with actual provider when backend is ready)
  final List<VoiceRoom> _mockRooms = [
    VoiceRoom(
      id: '1',
      title: 'English Practice - Beginners Welcome!',
      hostId: 'host1',
      hostName: 'Sarah',
      hostAvatar: '',
      topic: 'Language Tips',
      language: 'English',
      participants: [
        RoomParticipant(
          id: 'p1',
          name: 'John',
          avatar: '',
          isSpeaking: true,
          joinedAt: DateTime.now(),
        ),
        RoomParticipant(
          id: 'p2',
          name: 'Maria',
          avatar: '',
          joinedAt: DateTime.now(),
        ),
        RoomParticipant(
          id: 'p3',
          name: 'Kim',
          avatar: '',
          joinedAt: DateTime.now(),
        ),
      ],
      maxParticipants: 8,
      isLive: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    VoiceRoom(
      id: '2',
      title: 'Korean Drama Discussion',
      hostId: 'host2',
      hostName: 'Min-Ji',
      hostAvatar: '',
      topic: 'Movies & TV',
      language: 'Korean',
      participants: [
        RoomParticipant(
          id: 'p4',
          name: 'Alex',
          avatar: '',
          joinedAt: DateTime.now(),
        ),
        RoomParticipant(
          id: 'p5',
          name: 'Emma',
          avatar: '',
          isSpeaking: true,
          joinedAt: DateTime.now(),
        ),
      ],
      maxParticipants: 6,
      isLive: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 32)),
    ),
    VoiceRoom(
      id: '3',
      title: 'Japanese Music Lovers',
      hostId: 'host3',
      hostName: 'Yuki',
      hostAvatar: '',
      topic: 'Music',
      language: 'Japanese',
      participants: [
        RoomParticipant(
          id: 'p6',
          name: 'David',
          avatar: '',
          joinedAt: DateTime.now(),
        ),
      ],
      maxParticipants: 10,
      isLive: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  void _createRoom() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateRoomSheet(
        onCreateRoom: (title, topic, language, maxParticipants) {
          // TODO: Call backend to create room
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Room created! Feature coming soon.'),
              backgroundColor: const Color(0xFF00BFA5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderMD,
              ),
            ),
          );
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _mockRooms.isEmpty ? _buildEmptyState() : _buildRoomsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createRoom,
        backgroundColor: const Color(0xFF00BFA5),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Create Room',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRoomsList() {
    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Refresh rooms from backend
        await Future.delayed(const Duration(seconds: 1));
      },
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),
          // Rooms list
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final room = _mockRooms[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: VoiceRoomCard(
                      room: room,
                      onTap: () => _joinRoom(room),
                      onJoin: () => _joinRoom(room),
                    ),
                  );
                },
                childCount: _mockRooms.length,
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

  Widget _buildHeader() {
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
                    'Voice Rooms',
                    style: context.titleMedium,
                  ),
                  Text(
                    'Join live conversations and practice speaking',
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
                  '${_mockRooms.length} Live',
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
                'No active rooms',
                style: context.titleLarge,
              ),
            ),
            Spacing.gapMD,
            Builder(
              builder: (context) => Text(
                'Be the first to start a voice room and practice speaking with others!',
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
              label: const Text('Start a Room'),
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
