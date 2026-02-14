import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/report_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
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
    _loadReports();
  }

  Future<void> _loadReports() async {
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
            Row(
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
                Spacing.hGapSM,
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
                _buildInfoRow('Reported By', report['reportedBy']?['name'] ?? 'N/A'),
                Spacing.gapSM,
                _buildInfoRow('Reported User', report['reportedUser']?['name'] ?? 'N/A'),
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
