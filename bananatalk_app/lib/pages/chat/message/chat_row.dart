// lib/pages/chat/message/chat_row.dart
import 'package:bananatalk_app/providers/provider_models/message_model.dart';

/// Render model for the chat message list: either a day separator or a
/// message carrying its precomputed grouping flags. Produced by the pure
/// [buildChatRows] so the ListView builder stays dumb and this logic is
/// unit-testable in isolation.
sealed class ChatRow {
  const ChatRow();
}

class DateSeparatorRow extends ChatRow {
  final DateTime day; // local, date-only (midnight)
  const DateSeparatorRow(this.day);
}

class MessageRow extends ChatRow {
  final Message message;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  const MessageRow(
    this.message, {
    required this.isFirstInGroup,
    required this.isLastInGroup,
  });
}

DateTime? _localDay(String iso) {
  try {
    final t = DateTime.parse(iso).toLocal();
    return DateTime(t.year, t.month, t.day);
  } catch (_) {
    return null;
  }
}

bool _groups(Message a, Message b) {
  if (a.sender.id != b.sender.id) return false;
  if (a.type == 'correction' || a.type == 'call') return false;
  if (b.type == 'correction' || b.type == 'call') return false;
  try {
    final ta = DateTime.parse(a.createdAt);
    final tb = DateTime.parse(b.createdAt);
    return tb.difference(ta).inMinutes.abs() < 3;
  } catch (_) {
    return false;
  }
}

/// Builds the ordered render rows: a [DateSeparatorRow] before the first
/// message of each local calendar day, and a [MessageRow] per message with
/// grouping flags (same author + <3 min window) computed once. Grouping
/// always restarts after a day boundary.
List<ChatRow> buildChatRows(List<Message> messages) {
  final rows = <ChatRow>[];
  DateTime? currentDay;

  for (var i = 0; i < messages.length; i++) {
    final msg = messages[i];
    final day = _localDay(msg.createdAt);

    final dayChanged = day != null &&
        (currentDay == null || !day.isAtSameMomentAs(currentDay));
    if (dayChanged) {
      rows.add(DateSeparatorRow(day));
      currentDay = day;
    }

    final prev = i > 0 ? messages[i - 1] : null;
    final next = i < messages.length - 1 ? messages[i + 1] : null;

    final isFirstInGroup = dayChanged || prev == null || !_groups(prev, msg);
    // If the next message opens a new day it will get its own separator, so
    // this message ends its group.
    final nextSameDay = next != null && _localDay(next.createdAt) == day;
    final isLastInGroup = next == null || !nextSameDay || !_groups(msg, next);

    rows.add(MessageRow(msg,
        isFirstInGroup: isFirstInGroup, isLastInGroup: isLastInGroup));
  }
  return rows;
}
