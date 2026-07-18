import 'package:bananatalk_app/providers/provider_models/message_model.dart';

/// Delivery tick state for one of the current user's own messages, used to
/// pick the check-mark icon + color. Only meaningful when
/// `sendingStatus == MessageSendingStatus.none`.
enum TickRole { none, sent, delivered, read }

TickRole tickRoleFor(Message m) {
  if (m.read) return TickRole.read;
  if (m.delivered) return TickRole.delivered;
  return TickRole.sent;
}
