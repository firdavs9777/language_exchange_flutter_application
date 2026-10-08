import 'package:uuid/uuid.dart';

/// CallKit identifiers. The plugin force-unwraps `UUID(uuidString:)` on iOS,
/// so a CallKit id must always be a UUID; iOS reports them back uppercase.
class CallKitIds {
  const CallKitIds._();

  static bool same(String? a, String? b) =>
      a != null && b != null && a.isNotEmpty && a.toLowerCase() == b.toLowerCase();

  /// The server's callUuid; for a payload from an old backend that has none,
  /// a deterministic v5 UUID of the Mongo id (never the 24-hex id itself).
  static String uuidFor({required String callId, String? callUuid}) =>
      (callUuid != null && callUuid.isNotEmpty)
          ? callUuid.toLowerCase()
          : const Uuid().v5(Namespace.url.value, 'bananatalk:call:$callId');
}

/// One call the native CallKit / Android call UI currently shows.
class CallKitEntry {
  const CallKitEntry({required this.uuid, required this.accepted, this.extra = const {}});

  factory CallKitEntry.fromPlugin(Map raw) {
    final extra = raw['extra'] is Map
        ? Map<String, dynamic>.from(raw['extra'] as Map)
        : const <String, dynamic>{};
    return CallKitEntry(
      uuid: (raw['id'] ?? '').toString(),
      accepted: raw['accepted'] == true || raw['isAccepted'] == true,
      extra: extra,
    );
  }

  final String uuid;
  final bool accepted;
  final Map<String, dynamic> extra;

  String? get callId {
    final id = extra['callId']?.toString();
    return (id == null || id.isEmpty) ? null : id;
  }
}
