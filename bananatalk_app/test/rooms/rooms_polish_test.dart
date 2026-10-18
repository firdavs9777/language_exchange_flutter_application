import 'package:bananatalk_app/l10n/app_localizations_en.dart';
import 'package:bananatalk_app/models/room.dart';
import 'package:bananatalk_app/pages/community/rooms/room_card.dart';
import 'package:bananatalk_app/pages/community/rooms/room_screen.dart';
import 'package:bananatalk_app/services/notification_router.dart';
import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rooms polish (2026-10-18), from the audit after the rooms were seeded.
void main() {
  test('room language chips use the exact flag for the code', () {
    // getFlagByName fuzzy-matched codes: es -> 🇯🇵, ar -> 🇨🇳, pt -> 🇪🇬.
    expect(LanguageFlags.getFlag('es'), '🇪🇸');
    expect(LanguageFlags.getFlag('ar'), '🇸🇦');
    expect(LanguageFlags.getFlag('hi'), '🇮🇳');
  });

  test('only a system message with a promptId is the daily prompt', () {
    expect(isDailyPromptJson({'messageType': 'system', 'promptId': 'p1'}), isTrue);
    expect(isDailyPromptJson({'messageType': 'system', 'message': 'Mina joined'}), isFalse);
    expect(isDailyPromptJson({'messageType': 'text', 'promptId': 'p1'}), isFalse);
    expect(isDailyPromptJson({'type': 'system', 'promptId': 'p1'}), isTrue);
  });

  test('room cards say when the room was last active', () {
    final l10n = AppLocalizationsEn();
    final now = DateTime(2026, 10, 18, 12);
    expect(roomActivityLabel(l10n, null, now: now), isNull);
    expect(roomActivityLabel(l10n, now.subtract(const Duration(minutes: 5)), now: now),
        l10n.chatActiveMinAgo(5));
    expect(roomActivityLabel(l10n, now.subtract(const Duration(hours: 3)), now: now),
        l10n.chatActiveHoursAgo(3));
    final room = Room.fromJson({'_id': 'r1', 'lastActivityAt': '2026-10-18T03:00:00.000Z'});
    expect(room.lastActivityAt, isNotNull);
    expect(room.copyWith(onlineCount: 3).lastActivityAt, room.lastActivityAt);
  });

  test('a room mention push opens the room, not just the Community tab', () {
    expect(NotificationRouter.targetPathForType('room_mention', {'roomId': 'r1'}), '/room/r1');
  });
}
