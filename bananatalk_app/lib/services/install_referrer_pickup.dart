import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/services/deep_link_parser.dart';
import 'package:bananatalk_app/services/referral_service.dart';

/// Set once Play has answered (with or without a code), so the lookup runs
/// once per install.
const installReferrerCheckedPrefsKey = 'install_referrer_checked';

/// The web invite page links to Play with `&referrer=code%3D<CODE>`; Play
/// returns the decoded value, e.g. `code=ABCD2345`, possibly next to utm_*
/// pairs. Returns the invite code or null.
String? inviteCodeFromInstallReferrer(String? referrer) {
  if (referrer == null || referrer.trim().isEmpty) return null;
  try {
    return normalizeInviteCode(Uri.splitQueryString(referrer.trim())['code']);
  } catch (_) {
    return null; // malformed percent-encoding
  }
}

typedef InstallReferrerReader = Future<String?> Function();

/// Throws on iOS and when Google Play services are unavailable.
Future<String?> readPlayInstallReferrer() async {
  final details = await PlayInstallReferrer.installReferrer;
  return details.installReferrer;
}

/// Fresh Android installs from an invite link keep the code (links#10):
/// it is stored as the pending referral, which registration claims
/// (`claimPendingReferral`) once the profile is complete. A code from a
/// tapped `/i/` link is never overwritten. Never throws.
Future<void> pickUpInstallReferrer({
  required InstallReferrerReader read,
  required bool isAndroid,
}) async {
  if (!isAndroid) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(installReferrerCheckedPrefsKey) == true) return;
    String? raw;
    try {
      raw = await read();
    } catch (_) {
      return; // Play unavailable or not ready: try again next launch
    }
    await prefs.setBool(installReferrerCheckedPrefsKey, true);
    final code = inviteCodeFromInstallReferrer(raw);
    if (code == null) return;
    final existing = prefs.getString(pendingReferralPrefsKey);
    if (existing != null && existing.isNotEmpty) return;
    await prefs.setString(pendingReferralPrefsKey, code);
  } catch (_) {}
}
