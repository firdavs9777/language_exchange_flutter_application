import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/service/endpoints.dart';

class AppConfigService {
  static const Duration _timeout = Duration(seconds: 5);

  // Tag the request with the running platform so the backend can return
  // per-platform min/latest versions. App Store / Play Store releases
  // aren't synchronized — iOS review is slow, Android is instant — so
  // without this we used to nag users on the lagging platform to update
  // to a version that didn't exist on their store.
  String get _platformTag {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isIOS) return 'ios';
      if (Platform.isAndroid) return 'android';
    } catch (_) {}
    return '';
  }

  Future<AppConfig?> fetch() async {
    try {
      final base = '${Endpoints.baseURL}${Endpoints.appConfigURL}';
      final tag = _platformTag;
      final url = tag.isEmpty ? base : '$base?platform=$tag';
      final res = await http.get(Uri.parse(url)).timeout(_timeout);
      if (res.statusCode != 200) return null;

      final body = json.decode(res.body) as Map<String, dynamic>;
      final data = body['data'];
      if (data is! Map<String, dynamic>) return null;

      return AppConfig.fromJson(data);
    } catch (e) {
      if (kDebugMode) debugPrint('AppConfigService.fetch failed: $e');
      return null;
    }
  }
}
