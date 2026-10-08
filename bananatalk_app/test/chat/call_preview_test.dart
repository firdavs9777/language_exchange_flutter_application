import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_outcome.dart';
import 'package:bananatalk_app/pages/chat/list/list_socket_handlers.dart';
import 'package:bananatalk_app/pages/chat/models/chat_partner.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';

final _callData = {
  '_id': 'c1', 'callId': 'c1', 'initiator': 'a', 'participants': [], 'type': 'audio',
  'startTime': '2026-10-08T12:00:00.000Z', 'duration': 0, 'status': 'missed', 'outcome': 'cancelled',
};

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  String preview(Map<String, dynamic> d) => callPreviewText(l10n, d, viewerId: 'b', otherName: 'U');

  test('getMessagePreview uses the viewer label for call messages', () {
    final m = Message.fromJson({
      'id': '1', 'sender': {'_id': 'a', 'name': 'U', 'images': []}, 'receiver': {'_id': 'b', 'name': 'O', 'images': []},
      'message': '📞 Cancelled voice call', 'createdAt': '2026-10-08T12:00:00.000Z', 'type': 'call', 'read': false,
      'reactions': [], 'translations': [], 'corrections': [], 'mentions': [],
      'media': {'type': 'call', 'callData': _callData},
    });
    expect(getMessagePreview(m, callPreview: preview), '📞 Missed voice call');
    expect(getMessagePreview(m), '📞 Cancelled voice call', reason: 'without a label builder the server text is used');
  });

  test('socket preview and list-API preview use it too', () {
    expect(extractMessagePreview({'message': '📞 Cancelled voice call', 'media': {'type': 'call', 'callData': _callData}},
        callPreview: preview), '📞 Missed voice call');
    final last = LastMessageData.fromJson({'message': '📞 Cancelled voice call', 'media': {'type': 'call', 'callData': _callData}});
    expect(last.callData?['outcome'], 'cancelled');
  });
}
