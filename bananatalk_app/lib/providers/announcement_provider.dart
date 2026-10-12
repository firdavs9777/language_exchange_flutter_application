import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/models/announcement.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/services/language_service.dart';

/// Maps `GET announcements/:id` to an announcement. The backend answers
/// 200 `{success, data: PublicAnnouncement}`, and 404 for an unknown,
/// malformed, draft or scheduled id: those return null (gone). Every other
/// failure throws so the screen can offer Retry.
Announcement? announcementFromResponse(ApiResponse res) {
  if (res.statusCode == 404) return null;
  final data = res.data;
  if (!res.success || data is! Map) {
    throw Exception(res.error ?? 'Could not load announcement');
  }
  return Announcement.fromJson(Map<String, dynamic>.from(data));
}

/// One announcement in the user's app language; null when it no longer
/// exists (404) or the id is blank. Other failures throw.
final announcementDetailProvider =
    FutureProvider.family<Announcement?, String>((ref, id) async {
  final clean = id.trim();
  if (clean.isEmpty) return null;
  final lang = await LanguageService.getAppLanguage();
  final res = await ApiClient().get(
    'announcements/${Uri.encodeComponent(clean)}',
    queryParams: {'lang': lang},
  );
  return announcementFromResponse(res);
});
