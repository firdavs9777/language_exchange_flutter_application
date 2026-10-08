import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/models/call_record_model.dart';
import 'package:bananatalk_app/services/api_client.dart';

class CallLogPage {
  const CallLogPage(this.items, this.hasMore);
  final List<CallLogEntry> items;
  final bool hasMore;
}

/// GET /calls (30 per page), missed count and mark-seen (spec §4.7).
class CallHistoryService {
  CallHistoryService([ApiClient? client]) : _client = client ?? ApiClient();

  final ApiClient _client;
  static const int pageSize = 30;

  Future<CallLogPage> fetchPage(int page) async {
    final res = await _client.get('calls', queryParams: {'page': '$page', 'limit': '$pageSize'});
    if (!res.success || res.data is! Map) return const CallLogPage([], false);
    final body = Map<String, dynamic>.from(res.data as Map);
    final items = (body['data'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => CallLogEntry.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    final hasMore = (body['pagination'] as Map?)?['hasMore'] == true;
    return CallLogPage(items, hasMore);
  }

  Future<int> missedCount() async {
    final res = await _client.get('calls/missed/count');
    if (!res.success || res.data is! Map) return 0;
    return ((res.data as Map)['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markMissedSeen() async {
    await _client.post('calls/missed/seen');
  }
}

final callHistoryServiceProvider = Provider<CallHistoryService>((ref) => CallHistoryService());
