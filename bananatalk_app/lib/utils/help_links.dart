/// Targets for the Help Center rows in the profile drawer.
///
/// The support address matches the one the backend puts in every
/// transactional email (`SUPPORT_EMAIL` in utils/emailTemplates.js). The FAQ
/// lives on the public, prerendered https://banatalk.com/support page.
class HelpLinks {
  static const String supportEmail = 'bananatalkmain@gmail.com';

  static final Uri faqUri = Uri.parse('https://banatalk.com/support');

  static Uri supportEmailUri() => Uri(scheme: 'mailto', path: supportEmail);

  /// A pre-filled bug report. [clientInfo] is the map from
  /// `ClientInfo.collect()`; any missing field reads "unknown".
  static Uri bugReportUri({
    required String subject,
    required Map<String, String> clientInfo,
  }) {
    String field(String key) {
      final value = clientInfo[key];
      return (value == null || value.isEmpty) ? 'unknown' : value;
    }

    final version = clientInfo['appBuild']?.isNotEmpty == true
        ? '${field('appVersion')} (${clientInfo['appBuild']})'
        : field('appVersion');
    final body = [
      '',
      '',
      '---',
      'App version: $version',
      'Device: ${field('deviceModel')}',
      'OS: ${field('osVersion')}',
      'Platform: ${field('platform')}',
    ].join('\n');

    // Built by hand: Uri.queryParameters encodes spaces as '+', which most
    // mail apps show literally.
    final query = 'subject=${Uri.encodeComponent('BananaTalk: $subject')}'
        '&body=${Uri.encodeComponent(body)}';
    return Uri.parse('mailto:$supportEmail?$query');
  }
}
