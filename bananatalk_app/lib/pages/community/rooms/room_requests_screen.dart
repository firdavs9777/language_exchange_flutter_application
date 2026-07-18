// lib/pages/community/rooms/room_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/models/room.dart';
import 'package:bananatalk_app/pages/chat/header/user_avatar.dart';
import 'package:bananatalk_app/providers/rooms_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Pending join-request list for a topic room's owner/admin (Task 16,
/// client layer C). Reached from `RoomScreen`'s overflow menu when
/// `room.isOwnerOrAdmin && room.pendingRequestCount > 0`.
///
/// Backend shape (`GET /rooms/:id/requests`, owner/admin only):
/// `{ user: { _id, name, username, images }, requestedAt, status }[]`
/// (`RoomApiClient.getJoinRequests`, per Task 16 backend report). Each row
/// approves or denies via the matching endpoint, then drops out of the
/// list locally so the owner sees the queue shrink in real time.
class RoomRequestsScreen extends ConsumerStatefulWidget {
  const RoomRequestsScreen({super.key, required this.room});

  final Room room;

  @override
  ConsumerState<RoomRequestsScreen> createState() => _RoomRequestsScreenState();
}

class _RoomRequestsScreenState extends ConsumerState<RoomRequestsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _requests = [];

  /// User ids currently mid-approve/deny — disables their row's buttons so
  /// a double-tap can't fire the same action twice.
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apiClient = ref.read(roomApiClientProvider);
      final requests = await apiClient.getJoinRequests(widget.room.id);
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not load join requests';
      });
    }
  }

  Map<String, dynamic> _requestUser(Map<String, dynamic> request) {
    final user = request['user'];
    if (user is Map) return Map<String, dynamic>.from(user);
    return const {};
  }

  String _requestUserId(Map<String, dynamic> request) {
    final user = _requestUser(request);
    return (user['_id'] ?? user['id'])?.toString() ?? '';
  }

  String _requestUserName(Map<String, dynamic> request) =>
      _requestUser(request)['name']?.toString() ?? 'Someone';

  String? _requestUserPicture(Map<String, dynamic> request) {
    final images = _requestUser(request)['images'];
    if (images is List && images.isNotEmpty) return images.first?.toString();
    return null;
  }

  Future<void> _respond(Map<String, dynamic> request, {required bool approve}) async {
    final userId = _requestUserId(request);
    if (userId.isEmpty || _processingIds.contains(userId)) return;

    setState(() => _processingIds.add(userId));
    final apiClient = ref.read(roomApiClientProvider);
    final ok = approve
        ? await apiClient.approveJoinRequest(widget.room.id, userId)
        : await apiClient.denyJoinRequest(widget.room.id, userId);
    if (!mounted) return;

    setState(() {
      _processingIds.remove(userId);
      if (ok) {
        _requests.removeWhere((r) => _requestUserId(r) == userId);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (approve ? 'Request approved' : 'Request denied')
              : 'Failed to ${approve ? 'approve' : 'deny'} request',
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.room.title} · Requests'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _requests.isEmpty
                  ? const Center(child: Text('No pending requests'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(Spacing.md),
                      itemCount: _requests.length,
                      separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
                      itemBuilder: (context, index) {
                        final request = _requests[index];
                        final userId = _requestUserId(request);
                        final isProcessing = _processingIds.contains(userId);
                        return Material(
                          color: context.containerColor,
                          borderRadius: AppRadius.borderMD,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.md,
                              vertical: Spacing.sm,
                            ),
                            child: Row(
                              children: [
                                UserAvatar(
                                  profilePicture: _requestUserPicture(request),
                                  userName: _requestUserName(request),
                                  radius: 20,
                                ),
                                Spacing.hGapMD,
                                Expanded(
                                  child: Text(
                                    _requestUserName(request),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (isProcessing)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                else ...[
                                  IconButton(
                                    tooltip: 'Deny',
                                    onPressed: () => _respond(request, approve: false),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: AppColors.error,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Approve',
                                    onPressed: () => _respond(request, approve: true),
                                    icon: const Icon(
                                      Icons.check_rounded,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
