import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/community/voice_room_model.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Voice room card for room listings
class VoiceRoomCard extends StatelessWidget {
  final VoiceRoom room;
  final VoidCallback? onJoin;
  final VoidCallback? onTap;

  const VoiceRoomCard({
    super.key,
    required this.room,
    this.onJoin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with live indicator
              Row(
                children: [
                  if (room.isLive) _buildLiveIndicator(l10n),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      room.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Topic and language
              Row(
                children: [
                  Flexible(child: _buildTag(room.topic, Icons.tag_rounded)),
                  const SizedBox(width: 8),
                  Flexible(child: _buildTag(room.language, Icons.language_rounded)),
                ],
              ),
              const SizedBox(height: 16),
              // Host and participants
              Row(
                children: [
                  _buildHostAvatar(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.hostedBy(room.hostName.isNotEmpty ? room.hostName : '?'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          room.durationText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildParticipantAvatars(),
                ],
              ),
              const SizedBox(height: 16),
              // Footer with participant count and join button
              Row(
                children: [
                  Icon(
                    Icons.people_rounded,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    room.participantCountText,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  _buildJoinButton(l10n),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveIndicator(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE91E63).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PulsingDot(),
          const SizedBox(width: 4),
          Text(
            l10n.liveLabel,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFFE91E63),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF00BFA5), Color(0xFF00ACC1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFE91E63),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BFA5).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: room.hostAvatar.isNotEmpty
            ? Image.network(
                room.hostAvatar,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildAvatarFallback(room.hostName),
              )
            : _buildAvatarFallback(room.hostName),
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Container(
      color: const Color(0xFF00BFA5),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantAvatars() {
    if (room.participants.isEmpty) return const SizedBox.shrink();

    final displayCount = room.participants.length > 3 ? 3 : room.participants.length;
    final remaining = room.participants.length - displayCount;

    return Row(
      children: [
        SizedBox(
          width: displayCount * 24.0 + 8,
          height: 32,
          child: Stack(
            children: [
              for (var i = 0; i < displayCount; i++)
                Positioned(
                  left: i * 20.0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00BFA5),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipOval(
                      child: room.participants[i].avatar.isNotEmpty
                          ? Image.network(
                              room.participants[i].avatar,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildAvatarFallback(room.participants[i].name),
                            )
                          : _buildAvatarFallback(room.participants[i].name),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (remaining > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+$remaining',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildJoinButton(AppLocalizations l10n) {
    final isFull = room.isFull;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isFull ? null : onJoin,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: isFull
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF00BFA5), Color(0xFF00ACC1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: isFull ? Colors.grey[200] : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isFull
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF00BFA5).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isFull ? Icons.block_rounded : Icons.headphones_rounded,
                color: isFull ? Colors.grey[500] : Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                isFull ? l10n.fullLabel : l10n.joinLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isFull ? Colors.grey[500] : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pulsing dot animation for live indicator
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.fromRGBO(233, 30, 99, _animation.value),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(233, 30, 99, _animation.value * 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
