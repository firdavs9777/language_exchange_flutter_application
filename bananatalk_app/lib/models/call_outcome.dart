import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/models/call_record_model.dart';

/// How a call ended, as the server stores it (spec §3). One call message is
/// shared by both users; each side renders its own label from this and
/// whether the viewer was the caller.
enum CallOutcome { completed, noAnswer, cancelled, declined, busy }

CallOutcome? callOutcomeFromWire(String? value) {
  switch (value) {
    case 'completed':
      return CallOutcome.completed;
    case 'no_answer':
      return CallOutcome.noAnswer;
    case 'cancelled':
      return CallOutcome.cancelled;
    case 'declined':
      return CallOutcome.declined;
    case 'busy':
      return CallOutcome.busy;
  }
  return null;
}

/// Rows written before `outcome` existed only carry the legacy status.
CallOutcome? legacyCallOutcome(String? status) {
  switch (status) {
    case 'ended':
    case 'answered':
      return CallOutcome.completed;
    case 'missed':
      return CallOutcome.noAnswer;
    case 'rejected':
      return CallOutcome.declined;
    case 'busy':
      return CallOutcome.busy;
  }
  return null;
}

String formatCallDuration(int seconds) {
  final d = Duration(seconds: seconds < 0 ? 0 : seconds);
  final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
  final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
  if (d.inHours > 0) return '${d.inHours}:$mm:$ss';
  return '${d.inMinutes}:$ss';
}

class CallLabels {
  const CallLabels._();

  static String label(
    AppLocalizations l10n, {
    required CallOutcome outcome,
    required bool viewerIsCaller,
    required bool isVideo,
    int duration = 0,
    String otherName = '',
  }) {
    final type = isVideo ? 'video' : 'audio';
    switch (outcome) {
      case CallOutcome.completed:
        final base = viewerIsCaller
            ? l10n.callLabelOutgoing(type)
            : l10n.callLabelIncoming(type);
        return '$base · ${formatCallDuration(duration)}';
      case CallOutcome.noAnswer:
        return viewerIsCaller
            ? l10n.callLabelNoAnswer(type)
            : l10n.callLabelMissed(type);
      case CallOutcome.cancelled:
        return viewerIsCaller
            ? l10n.callLabelCancelled(type)
            : l10n.callLabelMissed(type);
      case CallOutcome.declined:
        return viewerIsCaller
            ? l10n.callLabelDeclinedOutgoing(type)
            : l10n.callLabelDeclinedIncoming(type);
      case CallOutcome.busy:
        return viewerIsCaller
            ? l10n.callLabelBusy(otherName)
            : l10n.callLabelMissed(type);
    }
  }

  /// "Missed" in the §3 sense: red in the UI and counted by the badge.
  static bool isMissedForViewer(CallOutcome outcome,
          {required bool viewerIsCaller}) =>
      !viewerIsCaller &&
      (outcome == CallOutcome.noAnswer ||
          outcome == CallOutcome.cancelled ||
          outcome == CallOutcome.busy);
}

/// Chat-list preview for a call message, from the viewer's perspective.
String callPreviewText(
  AppLocalizations l10n,
  Map<String, dynamic> callData, {
  required String? viewerId,
  required String otherName,
}) {
  final record = CallRecord.fromJson(callData, viewerId ?? '');
  final label = CallLabels.label(
    l10n,
    outcome: record.outcome ?? CallOutcome.completed,
    viewerIsCaller: viewerId != null && record.initiatorId == viewerId,
    isVideo: record.type == CallType.video,
    duration: record.duration ?? 0,
    otherName: otherName,
  );
  return '📞 $label';
}
