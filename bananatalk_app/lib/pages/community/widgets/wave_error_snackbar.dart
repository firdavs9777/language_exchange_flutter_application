import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/widgets/community_snackbar.dart';

/// Surfaces a failed `sendWave` to the user, mirroring send_wave_sheet.dart:
/// the backend's own message (e.g. the permanent ALREADY_WAVED text) when
/// there is one, the localized generic otherwise.
void showWaveError(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context)!;
  final backendMessage = error
      .toString()
      .replaceFirst('Exception: ', '')
      .trim();
  showCommunitySnackBar(
    context,
    message: (backendMessage.isEmpty || backendMessage == 'Failed to send wave')
        ? l10n.waveCouldntSend
        : backendMessage,
    type: CommunitySnackBarType.error,
  );
}
