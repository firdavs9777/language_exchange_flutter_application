import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/widgets/community_snackbar.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/widgets/limit_exceeded_dialog.dart';

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

/// What a failed wave should surface.
enum WaveErrorAction {
  /// Today's 429 handling (the legacy "too many waves" text).
  legacyMessage,

  /// The daily wave cap: [LimitExceededDialog] with coin / rewarded unlock.
  limitDialog,

  /// Any other failure: today's generic / backend-message snackbar.
  genericError,
}

/// Body code the backend puts on the daily wave-cap 429.
const waveCapErrorCode = 'wave_cap';

/// A wave 429 is the daily cap only when the server says the cap is on
/// (`appConfig.waveCapEnabled`) AND the body carries `code: 'wave_cap'`. Any
/// other 429 (the route's rate limiter, an older server) keeps the legacy
/// message, so the limiter can never open the dialog. With the flag off every
/// outcome is what it was before the cap existed.
WaveErrorAction waveErrorAction({
  required int? status,
  required bool waveCapEnabled,
  String? code,
}) {
  if (status == 429) {
    return (waveCapEnabled && code == waveCapErrorCode)
        ? WaveErrorAction.limitDialog
        : WaveErrorAction.legacyMessage;
  }
  return WaveErrorAction.genericError;
}

/// HTTP status of a failed wave, when the error carries one.
int? waveErrorStatus(Object error) =>
    error is WaveSendException ? error.statusCode : null;

/// Machine-readable body code of a failed wave, when the error carries one.
String? waveErrorCode(Object error) =>
    error is WaveSendException ? error.code : null;

/// The single place every wave surface routes its failure through.
///
/// * Cap on + 429 (and [allowLimitDialog]): shows [LimitExceededDialog]
///   (`limitType: 'wave'`); on `'unlocked'` runs [retry] once. A failing
///   retry falls back to [showWaveError] — never a second dialog.
/// * Otherwise: [onFallback] when given (the caller's own pre-existing
///   handling), else [showWaveError] — byte-identical to the old path.
///
/// Returns true when the limit dialog was shown (whatever its result).
Future<bool> handleWaveError(
  BuildContext context,
  WidgetRef ref,
  Object error, {
  Future<void> Function()? retry,
  FutureOr<void> Function()? onFallback,
  bool allowLimitDialog = true,
}) async {
  final capOn =
      ref.read(appConfigProvider).valueOrNull?.waveCapEnabled ?? false;
  final action = waveErrorAction(
    status: waveErrorStatus(error),
    waveCapEnabled: capOn,
    code: waveErrorCode(error),
  );
  if (action != WaveErrorAction.limitDialog || !allowLimitDialog) {
    if (onFallback != null) {
      await onFallback();
    } else if (context.mounted) {
      showWaveError(context, error);
    }
    return false;
  }
  if (!context.mounted) return false;
  final userId = ref.read(userProvider).valueOrNull?.id ?? '';
  final result = await LimitExceededDialog.show(
    context: context,
    limitType: 'wave',
    userId: userId,
  );
  if (result != 'unlocked' || retry == null) return true;
  try {
    await retry();
  } catch (e) {
    if (context.mounted) showWaveError(context, e);
  }
  return true;
}
