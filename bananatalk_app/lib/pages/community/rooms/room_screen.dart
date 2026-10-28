// lib/pages/community/rooms/room_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:bananatalk_app/pages/chat/panels/gif_picker_panel.dart';
import 'package:bananatalk_app/widgets/image_preview_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/room.dart';
import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:bananatalk_app/utils/language_names.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/rooms_provider.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/pages/chat/input/chat_input_bar.dart';
import 'package:bananatalk_app/pages/chat/message/messages_list.dart';
import 'package:bananatalk_app/pages/community/rooms/room_members_screen.dart';
import 'package:bananatalk_app/pages/community/rooms/room_requests_screen.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:bananatalk_app/services/report_service.dart';
import 'package:bananatalk_app/utils/haptic_utils.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/pages/community/rooms/club_notice_banner.dart';

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

/// The messages with a `messageReaction` event applied, or null when the
/// event is not about any of them. Reactions are parsed with the same model
/// as chat; a malformed entry is skipped.
List<Message>? applyReactionUpdate(List<Message> messages, Map data) {
  final id = data['messageId']?.toString();
  final raw = data['reactions'];
  if (id == null || raw is! List) return null;
  final index = messages.indexWhere((m) => m.id == id);
  if (index < 0) return null;
  final reactions = <MessageReaction>[];
  for (final r in raw) {
    if (r is! Map) continue;
    try {
      reactions.add(MessageReaction.fromJson(Map<String, dynamic>.from(r)));
    } catch (_) {}
  }
  final next = List<Message>.from(messages);
  next[index] = next[index].copyWith(reactions: reactions);
  return next;
}

/// Whether a room message payload is the daily prompt: a system message
/// with a promptId (backend jobs/dailyRoomPromptJob.js).
bool isDailyPromptJson(Map data) {
  final promptId = data['promptId'];
  return (data['messageType'] ?? data['type']) == 'system' &&
      promptId != null &&
      promptId.toString().isNotEmpty;
}

/// What the room's top-bar menu offers. A club's chat offers nothing here:
/// its members and leaving belong to the club page, and the server refuses
/// both through the rooms API.
@visibleForTesting
List<String> roomMenuActions(Room room) {
  if (room.isClubRoom) return const [];
  return [
    // Owner/admin-only, and only when there's something pending (Task 16) —
    // an empty queue doesn't clutter the menu.
    if (room.isOwnerOrAdmin && room.pendingRequestCount > 0) 'requests',
    // Only shown to the hub's owner/admin — everyone else can still leave,
    // but member-list moderation stays hidden.
    if (room.isOwnerOrAdmin) 'members',
    // Nothing to leave if we were never a member (or got kicked) — Task 16
    // topic rooms no longer auto-join a non-member.
    if (room.isMember) 'leave',
  ];
}

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

  /// The message being replied to (swipe / long-press → Reply), as in chat.
  Message? _replyingTo;

  /// A photo upload is in flight (the composer shows its progress state).
  bool _isUploadingPhoto = false;
  StreamSubscription? _roomReactionSub;
  StreamSubscription? _roomDeletedSub;

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
    ref.read(blockedUserIdsProvider); // loads the set used to hide live messages

    // Opening a room no longer joins it (2026-10-18): a visitor reads and
    // watches live, then joins with the "Join Room" bar. Peeking used to add
    // them as a member and bump memberCount. A BANNED user (kicked) sees the
    // "Request to join" prompt instead (Task 16).

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
    // Bail out if the user backed out while the REST calls above were in
    // flight: dispose() has already run, so subscriptions registered now
    // would never be cancelled and _loadMessages would setState on a dead
    // State.
    if (!mounted) return;

    // Members and visitors both watch live (the server lets a non-banned
    // visitor of a language room listen; only members can send).
    if (!_room.isBanned) {
      _chatSocket.joinRoom(_room.id);
    }
    _listenToSocket();

    await _loadMessages();
  }

  void _listenToSocket() {
    _roomMessageSub = _chatSocket.onRoomMessage.listen((data) {
      if (!mounted || data is! Map) return;
      // The socket service is a singleton with one broadcast stream for every
      // room, so scope to ours exactly as the typing/presence listeners below
      // do — otherwise another room's messages render in this history. The
      // `room:message` payload is the Message document, which carries the
      // room as `conversationId` (not `roomId` like the typing/presence
      // events).
      final messageRoomId = data['conversationId']?.toString();
      if (messageRoomId != null && messageRoomId != _room.id) return;
      try {
        final message = Message.fromJson(Map<String, dynamic>.from(data));
        // Only the daily prompt (it carries a promptId) takes the prompt
        // card; any other system line ("X joined") stays in the history.
        if (isDailyPromptJson(data)) {
          setState(() => _dailyPrompt = message);
          return;
        }
        if (_messages.any((m) => m.id == message.id)) return;
        // History already hides people you blocked; do the same live.
        final blocked = ref.read(blockedUserIdsProvider).valueOrNull;
        if (blocked != null && blocked.contains(message.sender.id)) return;
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
      final name = data['userName']?.toString() ??
          AppLocalizations.of(context)!.roomSomeoneFallback;
      setState(() {
        if (isTyping) {
          _typingUserNames.add(name);
        } else {
          _typingUserNames.remove(name);
        }
      });
    });

    _roomDeletedSub = _chatSocket.onRoomMessageDeleted.listen((data) {
      if (!mounted || data is! Map) return;
      if (data['roomId']?.toString() != _room.id) return;
      final id = data['messageId']?.toString();
      if (id != null && _messages.any((m) => m.id == id)) {
        setState(() => _messages.removeWhere((m) => m.id == id));
      }
    });

    // Reactions arrive on the room channel (backend emits messageReaction to
    // room_<id> for room messages); apply them to the messages we show.
    _roomReactionSub = _chatSocket.onMessageReaction.listen((data) {
      if (!mounted || data is! Map) return;
      final updated = applyReactionUpdate(_messages, data);
      if (updated != null) setState(() => _messages..clear()..addAll(updated));
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
          if (isDailyPromptJson(json)) {
            // The newest prompt wins, whatever order the page came in.
            if (dailyPrompt == null ||
                DateTime.parse(message.createdAt)
                    .isAfter(DateTime.parse(dailyPrompt.createdAt))) {
              dailyPrompt = message;
            }
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
        _error = AppLocalizations.of(context)!.roomFailedLoadMessages;
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
      final replyTo = _replyingTo;
      final error = await _chatSocket.sendRoomMessageAcked(_room.id, {
        'message': text,
        'messageType': messageType ?? 'text',
        if (replyTo != null) 'replyTo': replyTo.id,
      });
      if (error == null && mounted && identical(_replyingTo, replyTo)) {
        setState(() => _replyingTo = null);
      }
      if (error != null && mounted) {
        // Not saved (offline, rate limit, not a member): give the text back
        // and say so, instead of letting the message silently vanish.
        if (messageText == null && _messageController.text.isEmpty) {
          _messageController.text = text;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          key: const Key('room-send-failed'),
          content: Text(AppLocalizations.of(context)!.failedToSendMessage),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// Camera / gallery → chat's photo preview with caption → upload to the
  /// room; GIF → sent like chat's GIFs. The message itself arrives through
  /// the room socket broadcast.
  Future<void> _onMediaOption(String option) async {
    if (option == 'gif') {
      final gif = await GifPickerPanel.show(context);
      if (gif != null && mounted) {
        await _sendMessage(messageText: gif.originalUrl, messageType: 'gif');
      }
      return;
    }
    if (option != 'camera' && option != 'gallery') return;
    final picked = await ImagePicker().pickImage(
      source: option == 'camera' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    final file = File(picked.path);
    await ImagePreviewDialog.show(
      context: context,
      imageFile: file,
      onSend: (caption) => _uploadPhoto(file, caption),
    );
  }

  Future<void> _uploadPhoto(File file, String? caption) async {
    final replyTo = _replyingTo;
    setState(() => _isUploadingPhoto = true);
    final ok = await ref.read(roomApiClientProvider).postPhoto(
          _room.id,
          file,
          caption: caption,
          replyTo: replyTo?.id,
        );
    if (!mounted) return;
    setState(() {
      _isUploadingPhoto = false;
      if (ok && identical(_replyingTo, replyTo)) _replyingTo = null;
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        key: const Key('room-photo-failed'),
        content: Text(AppLocalizations.of(context)!.failedToSendMessage),
      ));
    }
  }

  Future<void> _deleteMessage(Message message) async {
    final ok = await ref.read(roomApiClientProvider).deleteMessage(_room.id, message.id);
    if (!mounted) return;
    if (ok) {
      setState(() => _messages.removeWhere((m) => m.id == message.id));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.somethingWentWrong),
      ));
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
    final l10n = AppLocalizations.of(context)!;
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                l10n.roomReportMessageTitle,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
                title: Text(_reasonLabel(l10n, reason)),
                onTap: () => Navigator.pop(sheetCtx, reason),
              ),
          ],
        ),
      ),
    );
    if (reason == null || !mounted) return;

    final result = await ReportService.reportMessage(
      messageId: message.id,
      reportedUserId: message.sender.id,
      reason: reason,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['success'] == true
              ? l10n.roomReportSubmitted
              : l10n.roomReportSubmitFailed,
        ),
        backgroundColor: result['success'] == true ? AppColors.success : AppColors.error,
      ),
    );
  }

  String _reasonLabel(AppLocalizations l10n, String value) {
    switch (value) {
      case 'spam':
        return l10n.reportReasonSpam;
      case 'harassment':
        return l10n.reportReasonHarassment;
      case 'hate_speech':
        return l10n.reportReasonHateSpeech;
      case 'violence':
        return l10n.reportReasonViolence;
      case 'nudity':
        return l10n.reportReasonNudity;
      case 'false_information':
        return l10n.reportReasonFalseInformation;
      default:
        return l10n.other;
    }
  }

  Future<void> _leaveHub() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.roomLeaveHubTitle),
        content: Text(l10n.roomLeaveHubMessage(_room.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.leave),
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
        SnackBar(content: Text(l10n.roomLeaveHubFailed)),
      );
    }
  }

  /// Owner/admin-only member list (Task 11) — visibility gated on
  /// `_room.isOwnerOrAdmin`, refreshed from `getRoom` in `_init`.
  /// Room info: what the room is, who is in it, and what you can do here
  /// (members, edit for moderators, join / leave).
  void _showRoomInfo() {
    final l10n = AppLocalizations.of(context)!;
    final flag = _room.emojiFlag.isNotEmpty
        ? _room.emojiFlag
        : LanguageFlags.getFlag(_room.targetLanguage);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            key: const Key('room-info-sheet'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(flag, style: Theme.of(ctx).textTheme.headlineMedium),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _room.title,
                      style: Theme.of(ctx)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (_room.targetLanguage.isNotEmpty)
                    Chip(
                      avatar: const Icon(Icons.translate_rounded, size: 16),
                      label: Text(LanguageNames.of(ctx, _room.targetLanguage)),
                    ),
                  Chip(
                    avatar: const Icon(Icons.people_alt_rounded, size: 16),
                    label: Text(l10n.roomMemberOnlineCount(
                        _room.memberCount, _room.onlineCount)),
                  ),
                ],
              ),
              if (_room.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_room.description,
                    style: Theme.of(ctx).textTheme.bodyMedium),
              ],
              const SizedBox(height: 16),
              if (_room.isMember && !_room.isClubRoom)
                ListTile(
                  key: const Key('room-info-members'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.groups_rounded),
                  title: Text(l10n.roomViewMembers),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openMembers();
                  },
                ),
              // A club's chat takes its name and members from the club, so
              // it is edited, joined and left there, not here.
              if (_room.isOwnerOrAdmin && !_room.isClubRoom)
                ListTile(
                  key: const Key('room-info-edit'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.edit_rounded),
                  title: Text(l10n.edit),
                  onTap: () {
                    Navigator.pop(ctx);
                    _editRoom();
                  },
                ),
              if (_room.isClubRoom)
                const SizedBox.shrink()
              else if (_showJoinBar)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.login_rounded),
                  title: Text(l10n.joinRoom),
                  onTap: () {
                    Navigator.pop(ctx);
                    _joinFromBar();
                  },
                )
              else if (_room.isMember)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout_rounded, color: AppColors.error),
                  title: Text(l10n.roomLeaveHubMenuItem,
                      style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _leaveHub();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Moderators edit the room's name and description (PUT /rooms/:id).
  Future<void> _editRoom() async {
    final l10n = AppLocalizations.of(context)!;
    final title = TextEditingController(text: _room.title);
    final description = TextEditingController(text: _room.description);
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.edit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('room-edit-title'),
              controller: title,
              maxLength: 60,
              decoration: InputDecoration(labelText: l10n.roomNameLabel),
            ),
            TextField(
              key: const Key('room-edit-description'),
              controller: description,
              maxLength: 300,
              maxLines: 3,
              decoration: InputDecoration(labelText: l10n.roomDescriptionLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.save)),
        ],
      ),
    );
    final newTitle = title.text.trim();
    final newDescription = description.text.trim();
    title.dispose();
    description.dispose();
    if (save != true || newTitle.isEmpty || !mounted) return;
    final ok = await ref.read(roomApiClientProvider).updateRoom(
      _room.id,
      {'title': newTitle, 'description': newDescription},
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _room =
          _room.copyWith(title: newTitle, description: newDescription));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.somethingWentWrong),
      ));
    }
  }

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
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? l10n.roomJoinRequestSent : l10n.roomJoinRequestFailed,
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
    _roomReactionSub?.cancel();
    _roomDeletedSub?.cancel();
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

  /// A visitor (not a member, not banned) sees "Join Room" instead of the
  /// composer.
  bool get _showJoinBar => !_room.isMember && !_room.isBanned;

  /// The label for one of [roomMenuActions].
  String _menuLabel(AppLocalizations l10n, String action) => switch (action) {
        'requests' => l10n.roomRequestsMenuItem(_room.pendingRequestCount),
        'members' => l10n.roomViewMembers,
        _ => l10n.roomLeaveHubMenuItem,
      };

  bool _isJoining = false;

  Future<void> _joinFromBar() async {
    if (_isJoining) return;
    setState(() => _isJoining = true);
    final joined = await ref.read(roomsProvider.notifier).join(_room.id);
    if (!mounted) return;
    setState(() {
      _isJoining = false;
      if (joined) {
        _room = _room.copyWith(isMember: true, memberCount: _room.memberCount + 1);
      }
    });
    if (joined) {
      _chatSocket.joinRoom(_room.id);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.somethingWentWrong),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        // Tapping the title opens the room info sheet (2026-10-18).
        title: GestureDetector(
          key: const Key('room-title-info'),
          behavior: HitTestBehavior.opaque,
          onTap: _showRoomInfo,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_room.emojiFlag.isNotEmpty ? _room.emojiFlag : LanguageFlags.getFlag(_room.targetLanguage)} ${_room.title}'
                  .trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              l10n.roomMemberOnlineCount(_room.memberCount, _room.onlineCount),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        ),
        actions: [
          if (roomMenuActions(_room).isNotEmpty)
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
              for (final action in roomMenuActions(_room))
                PopupMenuItem(
                  value: action,
                  child: Text(_menuLabel(l10n, action)),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_room.isClubRoom) ClubNoticeBanner(notice: _room.clubNotice),
          if (_dailyPrompt != null) _DailyPromptCard(message: _dailyPrompt!),
          Expanded(
            child: ChatMessagesList(
              conversationId: _room.id,
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
              onReply: _canCompose
                  ? (msg) => setState(() => _replyingTo = msg)
                  : null,
              onDelete: _deleteMessage,
              canDeleteOthers: _room.isOwnerOrAdmin,
              // "Tap to say hi" in the empty state — send a 👋 to the room.
              // Gated to members who can compose (banned/pending users can't).
              onSendWave:
                  _canCompose ? () => _sendMessage(messageText: '👋') : null,
            ),
          ),
          if (_needsJoinRequest)
            _RequestToJoinBar(
              isBanned: _room.isBanned,
              hasPendingRequest: _room.hasPendingRequest,
              isRequesting: _isRequestingJoin,
              onRequest: _requestToJoin,
            )
          else if (_showJoinBar)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    key: const Key('room-join-bar'),
                    onPressed: _isJoining ? null : _joinFromBar,
                    child: _isJoining
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.joinRoom),
                  ),
                ),
              ),
            )
          else if (_canCompose)
            ChatInputBar(
              messageController: _messageController,
              isSending: _isSending || _isUploadingPhoto,
              showMediaPanel: false,
              showStickerPanel: false,
              onSendMessage: _sendMessage,
              // Rooms: camera, gallery and GIF from the tools row; no
              // overflow panel, location or phrases.
              roomTools: true,
              onMediaOption: _onMediaOption,
              replyingToMessage: _replyingTo,
              otherUserName: _replyingTo?.sender.name,
              onCancelReply: () => setState(() => _replyingTo = null),
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
    final l10n = AppLocalizations.of(context)!;
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
                  ? l10n.roomBannedRequestMessage
                  : l10n.roomModeratedRequestMessage,
              textAlign: TextAlign.center,
              style: context.bodySmall.copyWith(color: context.textSecondary),
            ),
            const SizedBox(height: Spacing.sm),
            SizedBox(
              width: double.infinity,
              child: hasPendingRequest
                  ? FilledButton(
                      onPressed: null,
                      child: Text(l10n.roomRequestPending),
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
                          : Text(l10n.roomRequestToJoin),
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
                  AppLocalizations.of(context)!.roomDailyPromptLabel,
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
