// lib/pages/community/rooms/room_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/models/room.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/rooms_provider.dart';
import 'package:bananatalk_app/pages/chat/input/chat_input_bar.dart';
import 'package:bananatalk_app/pages/chat/message/messages_list.dart';
import 'package:bananatalk_app/pages/community/rooms/room_members_screen.dart';
import 'package:bananatalk_app/pages/community/rooms/room_requests_screen.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:bananatalk_app/services/report_service.dart';
import 'package:bananatalk_app/utils/haptic_utils.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Hub chat screen — Workstream D (Task 10 + Task 11).
///
/// On open: REST-joins the hub if the caller isn't already a member, joins
/// the socket room, and loads message history (paginated). Renders the
/// pinned daily-prompt system message at the top, then chronological
/// messages via the shared `ChatMessagesList` in its new multi-sender
/// (`isGroup`) mode. Composing reuses `ChatInputBar` unchanged. On dispose,
/// only the socket room is left (`chatSocket.leaveRoom`) — REST membership
/// persists across app sessions until the user explicitly leaves the hub
/// from the overflow menu.
///
/// Task 11 adds: per-message report (reusing the existing lightweight
/// `ReportService.reportMessage` path, `type:'message'`) and an
/// owner/admin-only "view members" entry that opens `RoomMembersScreen`
/// for remove/mute moderation.
class RoomScreen extends ConsumerStatefulWidget {
  const RoomScreen({super.key, required this.room});

  final Room room;

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  final ChatSocketService _chatSocket = ChatSocketService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  StreamSubscription? _roomMessageSub;
  StreamSubscription? _roomTypingSub;
  StreamSubscription? _roomPresenceSub;
  Timer? _typingStopTimer;

  String? _currentUserId;
  late Room _room; // Local copy so member/online counts can update live.

  bool _isLoading = true;
  String _error = '';
  bool _isSending = false;
  bool _isRequestingJoin = false;
  final List<Message> _messages = [];

  /// The pinned daily-prompt message, if the history contains one. Backend
  /// sends this as a `messageType:'system'` message (see workstream plan,
  /// Task 6). Rendered as a distinct card above the message list rather
  /// than inline, and excluded from `_messages` to avoid double-rendering.
  Message? _dailyPrompt;

  // Typing — a set because multiple hub members can type at once, unlike
  // the single "other user" typing flag in 1-on-1 chat.
  final Set<String> _typingUserNames = {};

  // Pagination
  int _currentPage = 1;
  bool _hasMoreMessages = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    _setupScrollListener();
    _init();
  }

  /// Infinite scroll: load the next page of older messages when the user
  /// scrolls near the top, mirroring the pattern used by the 1-on-1
  /// `ChatScreen`.
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      if (_scrollController.position.pixels <= 100 &&
          !_isLoadingMore &&
          _hasMoreMessages) {
        _loadMoreMessages();
      }
    });
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _currentUserId = prefs.getString('userId');

    // Join membership (REST) if we're not already a member. Safe to call
    // even if already a member — the backend join is idempotent. Topic
    // rooms are OPEN like hubs: any non-banned user auto-joins on open. Only
    // a BANNED user (kicked by the owner) is blocked — they never auto-join
    // and instead see a "Request to join" prompt (see `build`), becoming a
    // member only once the owner/admin approves their request (Task 16).
    if (!_room.isMember && !_room.isBanned) {
      final joined = await ref.read(roomsProvider.notifier).join(_room.id);
      if (joined && mounted) {
        setState(() => _room = _room.copyWith(isMember: true));
      }
    }

    // Refresh room detail — picks up `isOwnerOrAdmin` (gates the member-list
    // moderation entry, Task 11) and the latest member/online counts, which
    // the directory list card may not carry. Best-effort: keep the value
    // passed in from the directory on failure.
    try {
      final detail = await ref.read(roomApiClientProvider).getRoom(_room.id);
      if (detail != null && mounted) {
        setState(() => _room = detail);
      }
    } catch (_) {
      // Non-fatal — the directory's Room is still usable.
    }

    // Socket-side join — presence/broadcast is scoped to the live socket.
    // A banned user only views the request-to-join prompt; don't join live.
    if (_room.isMember) {
      _chatSocket.joinRoom(_room.id);
    }
    _listenToSocket();

    await _loadMessages();
  }

  void _listenToSocket() {
    _roomMessageSub = _chatSocket.onRoomMessage.listen((data) {
      if (!mounted || data is! Map) return;
      try {
        final message = Message.fromJson(Map<String, dynamic>.from(data));
        if (message.type == 'system') {
          setState(() => _dailyPrompt = message);
          return;
        }
        if (_messages.any((m) => m.id == message.id)) return;
        setState(() => _messages.add(message));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToBottom();
        });
      } catch (_) {
        // Malformed payload — ignore rather than crash the room screen.
      }
    });

    _roomTypingSub = _chatSocket.onRoomTyping.listen((data) {
      if (!mounted || data is! Map) return;
      final roomId = data['roomId']?.toString();
      if (roomId != _room.id) return;
      final userId = data['userId']?.toString();
      if (userId == null || userId == _currentUserId) return;
      final isTyping = data['isTyping'] == true;
      final name = data['userName']?.toString() ?? 'Someone';
      setState(() {
        if (isTyping) {
          _typingUserNames.add(name);
        } else {
          _typingUserNames.remove(name);
        }
      });
    });

    _roomPresenceSub = _chatSocket.onRoomPresence.listen((data) {
      if (!mounted) return;
      final roomId = data['roomId']?.toString();
      if (roomId != _room.id) return;
      final online = data['online'];
      if (online is num) {
        setState(() => _room = _room.copyWith(onlineCount: online.toInt()));
      }
    });
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final apiClient = ref.read(roomApiClientProvider);
      final raw = await apiClient.getMessages(_room.id, page: 1);
      if (!mounted) return;

      final parsed = <Message>[];
      Message? dailyPrompt;
      for (final json in raw) {
        try {
          final message = Message.fromJson(json);
          if (message.type == 'system') {
            dailyPrompt ??= message;
          } else {
            parsed.add(message);
          }
        } catch (_) {
          // Skip malformed entries rather than fail the whole load.
        }
      }
      parsed.sort(
        (a, b) => DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt)),
      );

      setState(() {
        _messages
          ..clear()
          ..addAll(parsed);
        _dailyPrompt = dailyPrompt;
        _currentPage = 1;
        // No pagination envelope is available from getMessages' current
        // return shape (raw list) — treat a full page as "there might be
        // more," and an empty/partial page as the end.
        _hasMoreMessages = raw.length >= 30;
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToBottom(animated: false);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load messages';
      });
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages || !mounted) return;
    setState(() => _isLoadingMore = true);
    try {
      final apiClient = ref.read(roomApiClientProvider);
      final nextPage = _currentPage + 1;
      final raw = await apiClient.getMessages(_room.id, page: nextPage);
      if (!mounted) return;

      if (raw.isEmpty) {
        setState(() {
          _hasMoreMessages = false;
          _isLoadingMore = false;
        });
        return;
      }

      final older = <Message>[];
      for (final json in raw) {
        try {
          final message = Message.fromJson(json);
          if (message.type != 'system') older.add(message);
        } catch (_) {}
      }
      older.sort(
        (a, b) => DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt)),
      );

      final seen = _messages.map((m) => m.id).toSet();
      final unique = older.where((m) => !seen.contains(m.id)).toList();

      setState(() {
        _messages.insertAll(0, unique);
        _currentPage = nextPage;
        _hasMoreMessages = raw.length >= 30;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  Future<void> _sendMessage({String? messageText, String? messageType}) async {
    final text = messageText ?? _messageController.text.trim();
    if (text.isEmpty || _isSending || _currentUserId == null) return;

    _messageController.clear();
    _stopTyping();
    setState(() => _isSending = true);

    try {
      _chatSocket.sendRoomMessage(_room.id, {
        'message': text,
        'messageType': messageType ?? 'text',
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _onTyping() {
    _chatSocket.sendRoomTyping(_room.id, true);
    _typingStopTimer?.cancel();
    _typingStopTimer = Timer(const Duration(seconds: 3), _stopTyping);
  }

  void _stopTyping() {
    _typingStopTimer?.cancel();
    _chatSocket.sendRoomTyping(_room.id, false);
  }

  /// Per-message report (Task 11) — long-press → Report in the shared
  /// bubble's context menu invokes this. Reuses the existing lightweight
  /// `ReportService.reportMessage` path (`type:'message'`, reason + optional
  /// details) rather than the full `ReportDialog`, which requires mandatory
  /// evidence uploads that are unnecessary friction for a quick hub report.
  Future<void> _reportMessage(Message message) async {
    HapticUtils.lightImpact();
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.isDarkMode ? AppColors.cardDark : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Report message',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            for (final reason in const [
              'spam',
              'harassment',
              'hate_speech',
              'violence',
              'nudity',
              'false_information',
              'other',
            ])
              ListTile(
                title: Text(_reasonLabel(reason)),
                onTap: () => Navigator.pop(sheetCtx, reason),
              ),
          ],
        ),
      ),
    );
    if (reason == null || !mounted) return;

    final result = await ReportService.reportMessage(
      messageId: message.id,
      reason: reason,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['success'] == true
              ? 'Report submitted'
              : (result['message'] ?? 'Failed to submit report'),
        ),
        backgroundColor: result['success'] == true ? AppColors.success : AppColors.error,
      ),
    );
  }

  String _reasonLabel(String value) {
    switch (value) {
      case 'spam':
        return 'Spam';
      case 'harassment':
        return 'Harassment or Bullying';
      case 'hate_speech':
        return 'Hate Speech';
      case 'violence':
        return 'Violence or Threats';
      case 'nudity':
        return 'Nudity or Sexual Content';
      case 'false_information':
        return 'False Information';
      default:
        return 'Other';
    }
  }

  Future<void> _leaveHub() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave hub?'),
        content: Text(
          'You can rejoin ${_room.title} later from the Rooms directory.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await ref.read(roomsProvider.notifier).leave(_room.id);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to leave hub')),
      );
    }
  }

  /// Owner/admin-only member list (Task 11) — visibility gated on
  /// `_room.isOwnerOrAdmin`, refreshed from `getRoom` in `_init`.
  void _openMembers() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoomMembersScreen(room: _room),
      ),
    );
  }

  /// Owner/admin-only pending join requests (Task 16, client layer C) —
  /// only surfaced in the menu when there's actually something to act on
  /// (`_room.pendingRequestCount > 0`); refetches the room on return so the
  /// badge count and any newly-approved member reflect immediately.
  Future<void> _openRequests() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoomRequestsScreen(room: _room),
      ),
    );
    if (!mounted) return;
    try {
      final detail = await ref.read(roomApiClientProvider).getRoom(_room.id);
      if (detail != null && mounted) setState(() => _room = detail);
    } catch (_) {
      // Non-fatal — stale count until the next natural refresh.
    }
  }

  /// Banned users and non-members of a moderated topic room can't send
  /// messages or join directly — they ask the owner/admin via
  /// `requestJoin` instead (Task 16). Idempotent server-side, but the
  /// button is hidden once `hasPendingRequest` is true so this only really
  /// fires once per ban/non-membership.
  Future<void> _requestToJoin() async {
    if (_isRequestingJoin) return;
    setState(() => _isRequestingJoin = true);
    final ok = await ref.read(roomApiClientProvider).requestJoin(_room.id);
    if (!mounted) return;
    setState(() {
      _isRequestingJoin = false;
      if (ok) _room = _room.copyWith(hasPendingRequest: true);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Request sent — you\'ll be notified if approved' : 'Failed to send request',
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  void dispose() {
    // Socket-only leave — REST membership persists. This lets a member
    // close the screen and keep receiving hub credit/history without
    // resubscribing every time, while presence still correctly reflects
    // that they're no longer actively viewing the room.
    _chatSocket.leaveRoom(_room.id);
    _roomMessageSub?.cancel();
    _roomTypingSub?.cancel();
    _roomPresenceSub?.cancel();
    _typingStopTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// True when the caller can neither join instantly nor message — either
  /// Only a BANNED user needs to request to join — topic rooms are otherwise
  /// open (non-banned users auto-join on open, see initState). Gates the
  /// composer off and swaps in the request-to-join bar for banned users.
  bool get _needsJoinRequest => _room.isBanned;

  /// A banned user must never be able to send messages, even if some stale
  /// `isMember:true` slipped through — membership AND not-banned are both
  /// required.
  bool get _canCompose => _room.isMember && !_room.isBanned;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_room.emojiFlag} ${_room.title}'.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${_room.memberCount} members · ${_room.onlineCount} online',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'requests':
                  _openRequests();
                  break;
                case 'members':
                  _openMembers();
                  break;
                case 'leave':
                  _leaveHub();
                  break;
              }
            },
            itemBuilder: (ctx) => [
              // Owner/admin-only, and only when there's something pending
              // (Task 16) — an empty queue doesn't clutter the menu.
              if (_room.isOwnerOrAdmin && _room.pendingRequestCount > 0)
                PopupMenuItem(
                  value: 'requests',
                  child: Text('Requests (${_room.pendingRequestCount})'),
                ),
              // Only shown to the hub's owner/admin — everyone else can
              // still leave, but member-list moderation stays hidden.
              if (_room.isOwnerOrAdmin)
                const PopupMenuItem(value: 'members', child: Text('View members')),
              // Nothing to leave if we were never a member (or got kicked)
              // — Task 16 topic rooms no longer auto-join a non-member.
              if (_room.isMember)
                const PopupMenuItem(value: 'leave', child: Text('Leave hub')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_dailyPrompt != null) _DailyPromptCard(message: _dailyPrompt!),
          Expanded(
            child: ChatMessagesList(
              isLoading: _isLoading,
              error: _error,
              messages: _messages,
              currentUserId: _currentUserId,
              otherUserName: _room.title,
              otherUserTyping: _typingUserNames.isNotEmpty,
              scrollController: _scrollController,
              onRetry: _loadMessages,
              isLoadingMore: _isLoadingMore,
              hasMoreMessages: _hasMoreMessages,
              isGroup: true,
              onReport: _reportMessage,
            ),
          ),
          if (_needsJoinRequest)
            _RequestToJoinBar(
              isBanned: _room.isBanned,
              hasPendingRequest: _room.hasPendingRequest,
              isRequesting: _isRequestingJoin,
              onRequest: _requestToJoin,
            )
          else if (_canCompose)
            ChatInputBar(
              messageController: _messageController,
              isSending: _isSending,
              showMediaPanel: false,
              showStickerPanel: false,
              onSendMessage: _sendMessage,
              // Media/sticker panels aren't wired for hubs in this batch —
              // hub composing is text-first. Toggling is a no-op rather than
              // a crash; see report notes.
              onToggleMediaPanel: () {},
              onToggleStickerPanel: () {},
              onTogglePhrasesPanel: () {},
              onTyping: _onTyping,
              onStopTyping: _stopTyping,
              onHidePanels: () {},
            ),
        ],
      ),
    );
  }
}

/// Replaces the composer for a banned user or a non-member of a moderated
/// topic room (Task 16, client layer C). Copy distinguishes "you were
/// removed" from "this room is moderated" so the user understands why
/// they can't just start typing.
class _RequestToJoinBar extends StatelessWidget {
  const _RequestToJoinBar({
    required this.isBanned,
    required this.hasPendingRequest,
    required this.isRequesting,
    required this.onRequest,
  });

  final bool isBanned;
  final bool hasPendingRequest;
  final bool isRequesting;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: context.containerColor,
          border: Border(top: BorderSide(color: context.dividerColor)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isBanned
                  ? 'You were removed from this room. Send a request to rejoin — the owner needs to approve it.'
                  : 'This is a moderated room. Request to join to start chatting.',
              textAlign: TextAlign.center,
              style: context.bodySmall.copyWith(color: context.textSecondary),
            ),
            const SizedBox(height: Spacing.sm),
            SizedBox(
              width: double.infinity,
              child: hasPendingRequest
                  ? const FilledButton(
                      onPressed: null,
                      child: Text('Request pending'),
                    )
                  : FilledButton(
                      onPressed: isRequesting ? null : onRequest,
                      child: isRequesting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text('Request to join'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pinned daily-prompt card — the backend posts one `messageType:'system'`
/// message per hub per day (Task 6, backend phase). Rendered distinctly
/// from regular chat bubbles, always pinned above the scrollable history.
class _DailyPromptCard extends StatelessWidget {
  const _DailyPromptCard({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(Spacing.md),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: AppRadius.borderMD,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wb_sunny_rounded, color: AppColors.primary, size: 20),
          Spacing.hGapSM,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's prompt",
                  style: context.captionSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.message ?? '',
                  style: context.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
