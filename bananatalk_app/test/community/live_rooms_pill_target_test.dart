import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/community/main/community_main.dart';

/// The "N live" pill counts live voice rooms. With gatherings on, slot 2 is
/// the Gatherings tab, which lists no voice rooms, so the pill must open the
/// voice-rooms list instead of that tab.
void main() {
  test('gatherings on: the pill opens the voice-rooms list', () {
    expect(
      liveRoomsPillTarget(gatheringsEnabled: true),
      LiveRoomsPillTarget.voiceRoomsScreen,
    );
  });

  test('gatherings off: slot 2 is the voice-rooms tab', () {
    expect(
      liveRoomsPillTarget(gatheringsEnabled: false),
      LiveRoomsPillTarget.voiceRoomsTab,
    );
  });
}
