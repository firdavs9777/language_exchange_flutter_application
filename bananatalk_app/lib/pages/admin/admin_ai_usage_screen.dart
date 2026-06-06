import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/admin_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/pages/admin/admin_user_detail_screen.dart';
import 'package:intl/intl.dart';

const _orange = Color(0xFFFF6D00);

class AdminAIUsageScreen extends ConsumerStatefulWidget {
  const AdminAIUsageScreen({super.key});

  @override
  ConsumerState<AdminAIUsageScreen> createState() => _AdminAIUsageScreenState();
}

class _AdminAIUsageScreenState extends ConsumerState<AdminAIUsageScreen> {
  final AdminService _adminService = AdminService();

  // 0 = 7d, 1 = 30d, 2 = 90d
  int _rangeIndex = 1;
  static const _rangeDays = [7, 30, 90];

  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _logs = [];
  int _logTotal = 0;
  bool _hasMore = false;
  int _logPage = 1;

  bool _loadingSummary = true;
  bool _loadingLogs = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime get _from =>
      DateTime.now().subtract(Duration(days: _rangeDays[_rangeIndex]));

  Future<void> _load() async {
    setState(() {
      _loadingSummary = true;
      _loadingLogs = true;
      _logs = [];
      _logPage = 1;
      _error = null;
    });
    await Future.wait([_loadSummary(), _loadLogs(reset: true)]);
  }

  Future<void> _loadSummary() async {
    final result = await _adminService.getAIUsage(from: _from);
    if (!mounted) return;
    setState(() {
      _loadingSummary = false;
      if (result['success'] == true) {
        _summary = result['data'] as Map<String, dynamic>;
      } else {
        _error = result['error']?.toString();
      }
    });
  }

  Future<void> _loadLogs({bool reset = false}) async {
    if (reset) _logPage = 1;
    final result = await _adminService.getAIUsageLogs(
      from: _from,
      page: _logPage,
      limit: 50,
    );
    if (!mounted) return;
    setState(() {
      _loadingLogs = false;
      _loadingMore = false;
      if (result['success'] == true) {
        final entries = (result['data'] as List?)
                ?.whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [];
        if (reset) {
          _logs = entries;
        } else {
          _logs = [..._logs, ...entries];
        }
        final pag = result['pagination'] as Map?;
        _logTotal = (pag?['total'] as num?)?.toInt() ?? _logs.length;
        _hasMore = pag?['hasMore'] == true;
      } else {
        _error ??= result['error']?.toString();
      }
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      _logPage++;
    });
    await _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Usage Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: (_loadingSummary || _loadingLogs) ? null : _load,
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_error != null && _summary == null && _logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRangeChips(),
          const SizedBox(height: 16),
          _buildSummaryCard(),
          const SizedBox(height: 20),
          _buildByFeature(),
          const SizedBox(height: 20),
          _buildLogsSection(),
          const SizedBox(height: 16),
          if (_hasMore)
            Center(
              child: _loadingMore
                  ? const CircularProgressIndicator()
                  : OutlinedButton(
                      onPressed: _loadMore,
                      child: const Text('Load more'),
                    ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRangeChips() {
    const labels = ['7 days', '30 days', '90 days'];
    return Row(
      children: List.generate(3, (i) {
        final selected = _rangeIndex == i;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(labels[i]),
            selected: selected,
            onSelected: (_) {
              if (_rangeIndex == i) return;
              setState(() => _rangeIndex = i);
              _load();
            },
            selectedColor: _orange.withValues(alpha: 0.15),
            checkmarkColor: _orange,
            labelStyle: TextStyle(
              color: selected ? _orange : context.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            side: BorderSide(
              color: selected ? _orange : Colors.transparent,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSummaryCard() {
    if (_loadingSummary) {
      return Container(
        height: 90,
        decoration: BoxDecoration(
          color: _orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    final total = (_summary?['total'] as num?)?.toInt() ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_orange, _orange.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total AI calls',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            NumberFormat.decimalPattern().format(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'in the last ${_rangeDays[_rangeIndex]} days',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildByFeature() {
    final byFeature = (_summary?['byFeature'] as List?)
            ?.whereType<Map>()
            .toList() ??
        [];
    final total = (_summary?['total'] as num?)?.toInt() ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('By feature'),
        const SizedBox(height: 8),
        if (_loadingSummary)
          const Center(child: CircularProgressIndicator())
        else if (byFeature.isEmpty)
          Text('No data.', style: TextStyle(color: context.textMuted))
        else
          Container(
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              children: byFeature.map((f) {
                final name = f['feature']?.toString() ?? '?';
                final count = (f['count'] as num?)?.toInt() ?? 0;
                final pct = total == 0 ? 0.0 : count / total;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _humanizeFeature(name),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            '${NumberFormat.decimalPattern().format(count)}  ·  ${(pct * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: _orange,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 4,
                          backgroundColor: _orange.withValues(alpha: 0.12),
                          valueColor: const AlwaysStoppedAnimation<Color>(_orange),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildLogsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionTitle('Recent activity'),
            if (_logTotal > 0) ...[
              const SizedBox(width: 8),
              Text(
                '(${NumberFormat.decimalPattern().format(_logTotal)} total)',
                style: TextStyle(color: context.textMuted, fontSize: 12),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (_loadingLogs && _logs.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (_logs.isEmpty)
          Text('No entries.', style: TextStyle(color: context.textMuted))
        else
          Container(
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _logs.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
              itemBuilder: (_, i) => _LogTile(entry: _logs[i]),
            ),
          ),
      ],
    );
  }

  String _humanizeFeature(String f) {
    final map = {
      'aiConversation': 'AI Conversation',
      'grammarFeedback': 'Grammar Check',
      'aiTranslation': 'Translation',
      'aiQuiz': 'AI Quiz',
      'aiLessonAssistant': 'Lesson Assistant',
      'speech': 'Speech',
      'pronunciation': 'Pronunciation',
      'tts': 'Text-to-Speech',
      'recommendations': 'Recommendations',
      'lessonBuilder': 'Lesson Builder',
    };
    return map[f] ?? f;
  }
}

class _LogTile extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _LogTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final user = entry['user'] as Map?;
    final name = user?['name']?.toString() ?? 'Unknown';
    final email = user?['email']?.toString() ?? '';
    final feature = entry['feature']?.toString() ?? '?';
    final ts = entry['timestamp'];
    String timeStr = '';
    if (ts != null) {
      try {
        final dt = DateTime.parse(ts.toString()).toLocal();
        timeStr = DateFormat('MMM d, HH:mm').format(dt);
      } catch (_) {}
    }

    final userId = (entry['user'] as Map?)?['id']?.toString();

    return InkWell(
      onTap: userId == null
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminUserDetailScreen(userId: userId),
                ),
              ),
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _orange.withValues(alpha: 0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: _orange,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: TextStyle(color: context.textMuted, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _humanizeFeature(feature),
                  style: const TextStyle(
                    color: _orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                timeStr,
                style: TextStyle(color: context.textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  String _humanizeFeature(String f) {
    const map = {
      'aiConversation': 'Conversation',
      'grammarFeedback': 'Grammar',
      'aiTranslation': 'Translation',
      'aiQuiz': 'Quiz',
      'aiLessonAssistant': 'Lesson Assist',
      'speech': 'Speech',
      'pronunciation': 'Pronunciation',
      'tts': 'TTS',
      'recommendations': 'Recommend',
      'lessonBuilder': 'Lesson Builder',
    };
    return map[f] ?? f;
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: context.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}
