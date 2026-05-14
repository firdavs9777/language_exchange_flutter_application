import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/admin_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Step 15 follow-up — admin analytics screen.
///
/// One-page snapshot of user-base composition: total + gender + role +
/// mode + ban/admin/VIP counters + recent signup velocity + top
/// languages. Single fetch via the GET /admin/stats $facet aggregation.
class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() =>
      _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = ref.read(userProvider).valueOrNull;
      if (user?.isAdmin != true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const _NotAuthorizedScreen()),
        );
        return;
      }
      _load();
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await _adminService.getStats();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _stats = result['data'] as Map<String, dynamic>;
      } else {
        _error = result['error']?.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _load,
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final s = _stats;
    if (s == null) return const SizedBox.shrink();

    final total = (s['total'] as num?)?.toInt() ?? 0;
    final banned = (s['banned'] as num?)?.toInt() ?? 0;
    final admins = (s['admins'] as num?)?.toInt() ?? 0;
    final vip = (s['vip'] as num?)?.toInt() ?? 0;
    final newToday = (s['newToday'] as num?)?.toInt() ?? 0;
    final newThisWeek = (s['newThisWeek'] as num?)?.toInt() ?? 0;
    final activeWeek = (s['activeWeek'] as num?)?.toInt() ?? 0;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeadlineCard(total: total),
          const SizedBox(height: 16),
          _SectionTitle('Snapshot'),
          const SizedBox(height: 8),
          _StatGrid([
            _Stat('VIP', vip, AppColors.secondary, Icons.workspace_premium),
            _Stat('Admins', admins, const Color(0xFF9C27B0), Icons.shield),
            _Stat('Banned', banned, AppColors.error, Icons.block),
            _Stat('Active 7d', activeWeek, AppColors.success, Icons.bolt),
          ]),
          const SizedBox(height: 20),
          _SectionTitle('Signups'),
          const SizedBox(height: 8),
          _StatGrid([
            _Stat('Today', newToday, AppColors.primary, Icons.today),
            _Stat('This week', newThisWeek, AppColors.primary, Icons.date_range),
          ]),
          const SizedBox(height: 20),
          _SectionTitle('By gender'),
          const SizedBox(height: 8),
          _BreakdownList(
            items: _toBreakdown(s['byGender']),
            total: total,
            colorFn: _genderColor,
          ),
          const SizedBox(height: 20),
          _SectionTitle('By role'),
          const SizedBox(height: 8),
          _BreakdownList(
            items: _toBreakdown(s['byRole']),
            total: total,
            colorFn: _roleColor,
          ),
          const SizedBox(height: 20),
          _SectionTitle('By mode'),
          const SizedBox(height: 8),
          _BreakdownList(
            items: _toBreakdown(s['byMode']),
            total: total,
            colorFn: _modeColor,
          ),
          const SizedBox(height: 20),
          _SectionTitle('Top native languages'),
          const SizedBox(height: 8),
          _BreakdownList(
            items: _toBreakdown(s['topNativeLanguages']),
            total: total,
            colorFn: (_) => AppColors.primary,
          ),
          const SizedBox(height: 20),
          _SectionTitle('Top learning languages'),
          const SizedBox(height: 8),
          _BreakdownList(
            items: _toBreakdown(s['topLearningLanguages']),
            total: total,
            colorFn: (_) => AppColors.secondary,
          ),
          const SizedBox(height: 24),
          if (s['generatedAt'] != null)
            Center(
              child: Text(
                'Updated ${_formatRelative(s['generatedAt'].toString())}',
                style: TextStyle(color: context.textMuted, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  List<_BreakdownItem> _toBreakdown(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map(
          (m) => _BreakdownItem(
            label: m['_id']?.toString() ?? '(unspecified)',
            count: (m['count'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
  }

  Color _genderColor(String label) {
    final l = label.toLowerCase();
    if (l == 'male') return const Color(0xFF2196F3);
    if (l == 'female') return const Color(0xFFE91E63);
    if (l == 'other' || l == 'non-binary') return const Color(0xFF7C4DFF);
    return Colors.black54;
  }

  Color _roleColor(String label) {
    return label == 'admin' ? const Color(0xFF9C27B0) : AppColors.primary;
  }

  Color _modeColor(String label) {
    if (label == 'vip') return AppColors.secondary;
    if (label == 'visitor') return Colors.black54;
    return AppColors.primary;
  }

  String _formatRelative(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return DateFormat('MMM d, HH:mm').format(dt);
    } catch (_) {
      return iso;
    }
  }
}

class _HeadlineCard extends StatelessWidget {
  final int total;
  const _HeadlineCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total users',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            NumberFormat.decimalPattern().format(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
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

class _StatGrid extends StatelessWidget {
  final List<_Stat> stats;
  const _StatGrid(this.stats);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: stats.map((s) => _StatTile(s)).toList(),
    );
  }
}

class _Stat {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  _Stat(this.label, this.value, this.color, this.icon);
}

class _StatTile extends StatelessWidget {
  final _Stat stat;
  const _StatTile(this.stat);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(stat.icon, color: stat.color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  NumberFormat.decimalPattern().format(stat.value),
                  style: TextStyle(
                    color: stat.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                Text(
                  stat.label,
                  style: TextStyle(
                    color: stat.color.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownItem {
  final String label;
  final int count;
  _BreakdownItem({required this.label, required this.count});
}

class _BreakdownList extends StatelessWidget {
  final List<_BreakdownItem> items;
  final int total;
  final Color Function(String label) colorFn;
  const _BreakdownList({
    required this.items,
    required this.total,
    required this.colorFn,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No data.',
          style: TextStyle(color: context.textMuted),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: items.map((item) {
          final color = colorFn(item.label);
          final pct = total == 0 ? 0 : (item.count * 100 / total);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${NumberFormat.decimalPattern().format(item.count)}'
                      '${total > 0 ? "  ·  ${pct.toStringAsFixed(1)}%" : ""}',
                      style: TextStyle(color: color, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : item.count / total,
                    minHeight: 4,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NotAuthorizedScreen extends StatelessWidget {
  const _NotAuthorizedScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(child: Text("This page isn't available.")),
    );
  }
}
