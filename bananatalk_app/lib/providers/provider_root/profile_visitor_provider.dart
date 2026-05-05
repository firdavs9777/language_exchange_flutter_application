import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/services/profile_visitor_service.dart';

final myVisitorStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await ProfileVisitorService.getMyVisitorStats();
});
