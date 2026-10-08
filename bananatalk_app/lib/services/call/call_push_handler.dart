import 'package:bananatalk_app/services/call_manager.dart';

/// Foreground FCM for calls. Returns true when [data] was a call push and
/// has been handled — the caller must then show nothing else for it.
///
/// incoming_call used to be dropped in the foreground on the assumption that
/// the socket had it; after a socket replacement it often had not.
Future<bool> handleCallPush(Map<String, dynamic> data, {CallManager? manager}) async {
  final m = manager ?? CallManager();
  switch (data['type']?.toString().toLowerCase()) {
    case 'incoming_call':
      await m.handleIncoming(data, source: IncomingSource.push);
      return true;
    case 'call_cancelled':
      await m.handleCallCancelled(data);
      return true;
  }
  return false;
}
