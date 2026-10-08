import 'package:flutter_test/flutter_test.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:bananatalk_app/services/chat_socket_service.dart';

import '../helpers/call_fakes.dart';

io.Socket _offlineSocket() => io.io(
      'http://127.0.0.1:9',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .build(),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('call listeners follow the chat socket across replacements', () async {
    final h = CallHarness();
    final service = ChatSocketService();
    final first = _offlineSocket();
    final second = _offlineSocket();

    service.debugInstallSocket(first);
    h.manager.attachSocketService(service);
    expect(first.hasListeners('call:incoming'), isTrue);
    expect(first.hasListeners('call:state'), isTrue);

    service.debugInstallSocket(second); // resume / token refresh / login
    await pumpEventQueue();
    expect(second.hasListeners('call:incoming'), isTrue);
    expect(second.hasListeners('call:state'), isTrue);
    expect(first.hasListeners('call:state'), isFalse);

    first.dispose();
    second.dispose();
  });
}
