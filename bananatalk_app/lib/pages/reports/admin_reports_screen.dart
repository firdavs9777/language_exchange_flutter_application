import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/report_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/widgets/report_evidence_section.dart';
import 'package:bananatalk_app/models/report_model.dart';
import 'package:intl/intl.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  final ReportService _reportService = ReportService();
  List<dynamic> _reports = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedStatus;
  String? _selectedType;
  String? _selectedPriority;

  final List<String> _statusFilters = ['pending', 'under_review', 'resolved', 'dismissed'];
  final List<String> _typeFilters = ['user', 'moment', 'comment', 'message', 'story'];
  final List<String> _priorityFilters = ['low', 'medium', 'high', 'urgent'];

  @override
  void initState() {
    super.initState();
    // Step 14 (safety wave): client-side defense-in-depth role gate.
    // Backend authorize('admin') is still the actual security boundary;
    // this just keeps the UI clean when a non-admin somehow navigates here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = ref.read(userProvider).valueOrNull;
      if (user?.isAdmin != true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const _NotAuthorizedScreen()),
        );
        return;
      }
      _loadReports();
    });
  }

  Future<void> _loadReports() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _reportService.getAllReports(
        status: _selectedStatus,
        type: _selectedType,
        priority: _selectedPriority,
      );

      if (result['success'] == true) {
        setState(() {
          _reports = result['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['error'] ?? 'Failed to load reports';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _startReview(String reportId) async {
    final result = await _reportService.startReview(reportId);

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.reviewStarted),
            backgroundColor: AppColors.success,
          ),
        );
        _loadReports();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to start review'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _resolveReport(String reportId) async {
    final action = await _showResolveDialog();
    if (action == null) return;

    final notes = await _showNotesDialog();

    final result = await _reportService.resolveReport(
      reportId: reportId,
      action: action,
      notes: notes,
    );

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.reportResolved),
            backgroundColor: AppColors.success,
          ),
        );
        _loadReports();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to resolve report'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _dismissReport(String reportId) async {
    final notes = await _showNotesDialog();

    final result = await _reportService.dismissReport(
      reportId: reportId,
      notes: notes,
    );

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.reportDismissed),
            backgroundColor: AppColors.success,
          ),
        );
        _loadReports();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to dismiss report'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<String?> _showResolveDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLG),
        title: Text(
          AppLocalizations.of(context)!.selectAction,
          style: context.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                AppLocalizations.of(context)!.noViolation,
                style: context.bodyMedium,
              ),
              onTap: () => Navigator.pop(context, 'no_violation'),
            ),
            ListTile(
              title: Text(
                AppLocalizations.of(context)!.contentRemoved,
                style: context.bodyMedium,
              ),
              onTap: () => Navigator.pop(context, 'content_removed'),
            ),
            ListTile(
              title: Text(
                AppLocalizations.of(context)!.userWarned,
                style: context.bodyMedium,
              ),
              onTap: () => Navigator.pop(context, 'user_warned'),
            ),
            ListTile(
              title: Text(
                AppLocalizations.of(context)!.userSuspended,
                style: context.bodyMedium,
              ),
              onTap: () => Navigator.pop(context, 'user_suspended'),
            ),
            ListTile(
              title: Text(
                AppLocalizations.of(context)!.userBanned,
                style: context.bodyMedium,
              ),
              onTap: () => Navigator.pop(context, 'user_banned'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showNotesDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLG),
        title: Text(
          AppLocalizations.of(context)!.addNotesOptional,
          style: context.titleLarge,
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: context.bodyMedium,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.enterModeratorNotes,
            hintStyle: context.bodyMedium.copyWith(color: context.textHint),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(
              AppLocalizations.of(context)!.skip,
              style: context.labelLarge.copyWith(color: context.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(AppLocalizations.of(context)!.add2),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.reportsManagement,
          style: context.titleLarge,
        ),
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Summary
          _buildStatsSummary(),

          // Reports List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AppColors.error,
                            ),
                            Spacing.gapLG,
                            Text(
                              _error!,
                              style: context.bodyMedium.copyWith(
                                color: context.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Spacing.gapXXL,
                            ElevatedButton(
                              onPressed: _loadReports,
                              child: Text(AppLocalizations.of(context)!.retry),
                            ),
                          ],
                        ),
                      )
                    : _reports.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.flag_outlined,
                                  size: 64,
                                  color: context.textHint,
                                ),
                                Spacing.gapLG,
                                Text(
                                  'No reports found',
                                  style: context.titleLarge.copyWith(
                                    color: context.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadReports,
                            child: ListView.builder(
                              padding: Spacing.screenPadding,
                              itemCount: _reports.length,
                              itemBuilder: (context, index) {
                                final report = _reports[index];
                                return _buildReportCard(report);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary() {
    final pendingCount = _reports.where((r) => r['status'] == 'pending').length;
    final underReviewCount = _reports.where((r) => r['status'] == 'under_review').length;
    final resolvedCount = _reports.where((r) => r['status'] == 'resolved').length;

    return Container(
      padding: Spacing.paddingLG,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: context.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('Pending', pendingCount, AppColors.warning),
          ),
          Expanded(
            child: _buildStatItem('Under Review', underReviewCount, AppColors.info),
          ),
          Expanded(
            child: _buildStatItem('Resolved', resolvedCount, AppColors.success),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: context.displayMedium.copyWith(
            color: color,
          ),
        ),
        Spacing.gapXS,
        Text(
          label,
          style: context.caption,
        ),
      ],
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final status = report['status']?.toString() ?? 'pending';
    final priority = report['priority']?.toString() ?? 'medium';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: context.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderMD,
      ),
      child: ExpansionTile(
        leading: Container(
          padding: Spacing.paddingSM,
          decoration: BoxDecoration(
            color: _getPriorityColor(priority).withOpacity(0.1),
            borderRadius: AppRadius.borderSM,
          ),
          child: Icon(
            Icons.flag_outlined,
            color: _getPriorityColor(priority),
            size: 24,
          ),
        ),
        title: Text(
          '${_getTypeLabel(report['type'])} Report',
          style: context.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reason: ${_getReasonLabel(report['reason'])}',
              style: context.bodySmall,
            ),
            Spacing.gapXS,
            // Wrap, not Row — the ListTile subtitle is ~201px wide on
            // narrow viewports and two Chips overflow horizontally.
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  label: Text(
                    status.toUpperCase(),
                    style: context.captionSmall.copyWith(
                      color: _getStatusColor(status),
                    ),
                  ),
                  backgroundColor: _getStatusColor(status).withOpacity(0.1),
                ),
                Chip(
                  label: Text(
                    priority.toUpperCase(),
                    style: context.captionSmall.copyWith(
                      color: _getPriorityColor(priority),
                    ),
                  ),
                  backgroundColor: _getPriorityColor(priority).withOpacity(0.1),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            if (status == 'pending')
              PopupMenuItem(
                value: 'review',
                child: Row(
                  children: [
                    const Icon(Icons.visibility, size: 20),
                    Spacing.hGapSM,
                    Text(
                      AppLocalizations.of(context)!.startReview,
                      style: context.bodyMedium,
                    ),
                  ],
                ),
              ),
            if (status == 'under_review' || status == 'pending')
              PopupMenuItem(
                value: 'resolve',
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 20),
                    Spacing.hGapSM,
                    Text(
                      AppLocalizations.of(context)!.resolve,
                      style: context.bodyMedium,
                    ),
                  ],
                ),
              ),
            if (status == 'pending' || status == 'under_review')
              PopupMenuItem(
                value: 'dismiss',
                child: Row(
                  children: [
                    const Icon(Icons.cancel, size: 20),
                    Spacing.hGapSM,
                    Text(
                      AppLocalizations.of(context)!.dismiss,
                      style: context.bodyMedium,
                    ),
                  ],
                ),
              ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'review':
                _startReview(report['_id'].toString());
                break;
              case 'resolve':
                _resolveReport(report['_id'].toString());
                break;
              case 'dismiss':
                _dismissReport(report['_id'].toString());
                break;
            }
          },
        ),
        children: [
          Padding(
            padding: Spacing.paddingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Report ID', report['_id']?.toString() ?? 'N/A'),
                Spacing.gapSM,
                _buildUserCard('Reported By', report['reportedBy']),
                Spacing.gapSM,
                _buildUserCard('Reported User', report['reportedUser']),
                Spacing.gapSM,
                _buildInfoRow('Type', _getTypeLabel(report['type'])),
                Spacing.gapSM,
                _buildInfoRow('Reason', _getReasonLabel(report['reason'])),
                if (report['description'] != null &&
                    report['description'].toString().isNotEmpty) ...[
                  Spacing.gapSM,
                  _buildInfoRow('Description', report['description'].toString()),
                ],
                Spacing.gapSM,
                _buildInfoRow(
                  'Submitted',
                  report['createdAt'] != null
                      ? _formatDate(report['createdAt'].toString())
                      : 'N/A',
                ),
                if (report['resolvedAt'] != null) ...[
                  Spacing.gapSM,
                  _buildInfoRow(
                    'Resolved',
                    _formatDate(report['resolvedAt'].toString()),
                  ),
                ],
                if (report['moderatorNotes'] != null &&
                    report['moderatorNotes'].toString().isNotEmpty) ...[
                  Spacing.gapSM,
                  _buildInfoRow('Moderator Notes', report['moderatorNotes'].toString()),
                ],
                if ((report['evidence'] as List?)?.isNotEmpty ?? false) ...[
                  Spacing.gapSM,
                  ReportEvidenceSection(
                    evidence: (report['evidence'] as List)
                        .map((e) => EvidenceFile.fromJson(e as Map<String, dynamic>))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: context.labelSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: context.bodySmall,
          ),
        ),
      ],
    );
  }

  /// Rich user card used for "Reported By" and "Reported User" in the
  /// admin report detail view. Renders avatar + name + email + language
  /// pair + location + joined date + banned pill. Falls back to a
  /// "(deleted account)" row when the populated ref is null (the user
  /// was deleted between when the report was filed and now).
  Widget _buildUserCard(String label, dynamic user) {
    // Defensive: populate may yield null (deleted account) or a non-Map
    // value (raw ObjectId from pre-populate writes).
    if (user is! Map) {
      return _buildInfoRow(label, '(deleted account)');
    }

    final name = user['name']?.toString() ?? '(unknown)';
    final email = user['email']?.toString();
    final native = user['native_language']?.toString();
    final learning = user['language_to_learn']?.toString();
    final loc = user['location'] is Map ? user['location'] as Map : null;
    final city = loc?['city']?.toString();
    final country = loc?['country']?.toString();
    final createdAt = user['createdAt']?.toString();
    final isBanned = user['isBanned'] == true;

    // Prefer imageUrls (CDN absolute), fall back to images.
    final List<String> imgList = [
      ...((user['imageUrls'] is List)
          ? List<String>.from(user['imageUrls']).whereType<String>()
          : const <String>[]),
      ...((user['images'] is List)
          ? List<String>.from(user['images']).whereType<String>()
          : const <String>[]),
    ];
    final avatarUrl = imgList.firstWhere(
      (u) => u.isNotEmpty && u.startsWith('http'),
      orElse: () => '',
    );

    final languagePair = (native != null && native.isNotEmpty)
        ? (learning != null && learning.isNotEmpty
            ? '$native → $learning'
            : native)
        : null;
    final locationStr = [city, country]
        .where((x) => x != null && x.isNotEmpty)
        .join(', ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: context.labelSmall.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    backgroundImage:
                        avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              name,
                              style: context.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (isBanned)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'BANNED',
                                  style: context.captionSmall.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (email != null && email.isNotEmpty)
                          Text(
                            email,
                            style: context.captionSmall.copyWith(
                              color: context.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (languagePair != null ||
                  locationStr.isNotEmpty ||
                  (createdAt != null && createdAt.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 46),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (languagePair != null)
                        Text(
                          languagePair,
                          style: context.captionSmall,
                        ),
                      if (locationStr.isNotEmpty)
                        Text(
                          locationStr,
                          style: context.captionSmall.copyWith(
                            color: context.textMuted,
                          ),
                        ),
                      if (createdAt != null && createdAt.isNotEmpty)
                        Text(
                          'Joined ${_formatDate(createdAt)}',
                          style: context.captionSmall.copyWith(
                            color: context.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLG),
        title: Text(
          AppLocalizations.of(context)!.filterReports,
          style: context.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                labelStyle: context.bodyMedium,
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(AppLocalizations.of(context)!.all)),
                ..._statusFilters.map((s) => DropdownMenuItem(value: s, child: Text(s))),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Type',
                labelStyle: context.bodyMedium,
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(AppLocalizations.of(context)!.all)),
                ..._typeFilters.map((t) => DropdownMenuItem(value: t, child: Text(t))),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                });
              },
            ),
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: InputDecoration(
                labelText: 'Priority',
                labelStyle: context.bodyMedium,
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(AppLocalizations.of(context)!.all)),
                ..._priorityFilters.map((p) => DropdownMenuItem(value: p, child: Text(p))),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedStatus = null;
                _selectedType = null;
                _selectedPriority = null;
              });
              Navigator.pop(context);
              _loadReports();
            },
            child: Text(
              AppLocalizations.of(context)!.clear,
              style: context.labelLarge.copyWith(color: context.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadReports();
            },
            child: Text(AppLocalizations.of(context)!.apply),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String? type) {
    switch (type?.toLowerCase()) {
      case 'user':
        return 'User';
      case 'moment':
        return 'Moment';
      case 'comment':
        return 'Comment';
      case 'message':
        return 'Message';
      case 'story':
        return 'Story';
      default:
        return type ?? 'Unknown';
    }
  }

  String _getReasonLabel(String? reason) {
    switch (reason?.toLowerCase()) {
      case 'spam':
        return 'Spam';
      case 'harassment':
        return 'Harassment';
      case 'hate_speech':
        return 'Hate Speech';
      case 'violence':
        return 'Violence';
      case 'nudity':
        return 'Nudity';
      case 'false_information':
        return 'False Information';
      case 'copyright':
        return 'Copyright';
      case 'other':
        return 'Other';
      default:
        return reason ?? 'Unknown';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'under_review':
        return AppColors.info;
      case 'resolved':
        return AppColors.success;
      case 'dismissed':
        return AppColors.gray500;
      default:
        return AppColors.gray500;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'high':
        return AppColors.error;
      case 'urgent':
        return AppColors.accent;
      default:
        return AppColors.gray500;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      return dateString; // Return original string if parsing fails
    }
  }
}

/// Step 14 — landing screen for non-admins who somehow reach AdminReportsScreen
/// (deep link, stale build, etc.). Backend authorize('admin') still enforces
/// the actual gate; this just keeps the UI honest.
class _NotAuthorizedScreen extends StatelessWidget {
  const _NotAuthorizedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, size: 56, color: Colors.black45),
              SizedBox(height: 16),
              Text(
                "This page isn't available.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
