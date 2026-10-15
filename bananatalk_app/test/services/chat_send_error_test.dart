import 'package:flutter_test/flutter_test.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:bananatalk_app/services/chat_socket_service.dart';

/// When the server rate-limits `sendMessage` it emits `messageSendError`
/// and never calls the ack (backend socket/socketHandler.js, the
/// consumeMessageToken guard). Without a listener the bubble sat on
/// "Sending..." until the 10 s ack timeout.
///
/// The event carries only `{ error }`, no message id, so the service has to
/// decide which in-flight send it belongs to. The rate-limit check runs
/// synchronously before any await on the server, so the refused send is
/// answered before earlier, accepted sends finish their database writes:
/// the newest in-flight send is the refused one.
class _FakeSocket extends io.Socket {
  _FakeSocket()
      : super(
          io
              .io(
                'http://127.0.0.1:9',
                io.OptionBuilder()
                    .setTransports(['websocket'])
                    .disableAutoConnect()
                    .enableForceNew()
                    .build(),
              )
              .io,
          '/',
          {},
        ) {
    connected = true;
  }

  final sent = <String, Function?>{};

  @override
  void emitWithAck(String event, dynamic data,
      {Function? ack, bool binary = false}) {
    if (event == 'sendMessage') {
      sent[(data as Map)['message'] as String] = ack;
    }
  }

  /// Deliver a server event to the app's listeners.
  void serverEmits(String event, dynamic data) =>
      onevent({'data': [event, data]});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChatSocketService service;
  late _FakeSocket socket;

  setUp(() {
    service = ChatSocketService();
    socket = _FakeSocket();
    service.debugInstallSocket(socket);
  });

  test('messageSendError fails the in-flight send immediately', () async {
    final watch = Stopwatch()..start();
    final pending = service.sendMessage(receiverId: 'p', message: 'eleventh');
    await Future<void>.delayed(Duration.zero);

    socket.serverEmits(
      'messageSendError',
      {'error': 'Too many messages — slow down.'},
    );
    final result = await pending;

    expect(result['status'], 'error');
    expect(result['code'], ChatSocketService.rateLimitedCode);
    expect(result['error'], 'Too many messages — slow down.');
    expect(watch.elapsed, lessThan(const Duration(seconds: 1)));
  });

  test('the refused send is the newest one; earlier sends still succeed',
      () async {
    final accepted = service.sendMessage(receiverId: 'p', message: 'tenth');
    final refused = service.sendMessage(receiverId: 'p', message: 'eleventh');
    await Future<void>.delayed(Duration.zero);

    socket.serverEmits('messageSendError', {'error': 'slow down'});
    expect((await refused)['code'], ChatSocketService.rateLimitedCode);

    // The accepted send's ack arrives after its DB write.
    socket.sent['tenth']!({'status': 'success', 'message': {'_id': 'm10'}});
    expect((await accepted)['status'], 'success');
  });

  test('a stray messageSendError with nothing in flight is ignored', () {
    expect(
      () => socket.serverEmits('messageSendError', {'error': 'slow down'}),
      returnsNormally,
    );
  });

  test('an acked send is no longer a target for a later error', () async {
    final first = service.sendMessage(receiverId: 'p', message: 'one');
    await Future<void>.delayed(Duration.zero);
    socket.sent['one']!({'status': 'success', 'message': {'_id': 'm1'}});
    expect((await first)['status'], 'success');

    final second = service.sendMessage(receiverId: 'p', message: 'two');
    await Future<void>.delayed(Duration.zero);
    socket.serverEmits('messageSendError', {'error': 'slow down'});
    expect((await second)['code'], ChatSocketService.rateLimitedCode);
  });
}
