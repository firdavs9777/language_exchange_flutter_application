import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/rooms/voice_rooms_entry.dart';
import 'package:bananatalk_app/providers/active_voice_room_count_provider.dart';

/// The Rooms tab's way into voice rooms. It replaced a pill that hid itself
/// when nothing was live, and since creating a room happens inside the voice
/// rooms screen, nobody could ever start one: the entry must show whatever the
/// count says.
Widget _app({required Stream<int> count, required VoidCallback onTap}) =>
    ProviderScope(
      overrides: [
        activeVoiceRoomCountProvider.overrideWith((ref) => count),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: VoiceRoomsEntry(onTap: onTap)),
      ),
    );

void main() {
  testWidgets('shown and tappable with nothing live', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_app(count: Stream.value(0), onTap: () => taps++));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('voice-rooms-entry')), findsOneWidget);
    expect(find.byKey(const Key('voice-rooms-live-badge')), findsNothing);
    await tester.tap(find.byKey(const Key('voice-rooms-entry')));
    expect(taps, 1);
  });

  testWidgets('shown while the count is still loading or failed', (tester) async {
    await tester.pumpWidget(
        _app(count: const Stream<int>.empty(), onTap: () {}));
    await tester.pump();
    expect(find.byKey(const Key('voice-rooms-entry')), findsOneWidget);

    await tester.pumpWidget(
        _app(count: Stream<int>.error('offline'), onTap: () {}));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('voice-rooms-entry')), findsOneWidget);
    expect(find.byKey(const Key('voice-rooms-live-badge')), findsNothing);
  });

  testWidgets('live rooms add the badge', (tester) async {
    await tester.pumpWidget(_app(count: Stream.value(3), onTap: () {}));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('voice-rooms-live-badge')), findsOneWidget);
    expect(find.text('3 live'), findsOneWidget);
  });
}
