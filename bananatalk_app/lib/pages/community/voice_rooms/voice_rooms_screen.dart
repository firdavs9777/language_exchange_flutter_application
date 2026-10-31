import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/voice_rooms/voice_rooms_tab.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:flutter/material.dart';

/// The live voice-rooms list as its own screen (Rooms' "Live now" row, deep
/// links, and the matches panel open it).
void openVoiceRoomsScreen(BuildContext context) {
  Navigator.push(
    context,
    AppPageRoute<void>(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.voiceRooms)),
        body: const VoiceRoomsTab(),
      ),
    ),
  );
}
