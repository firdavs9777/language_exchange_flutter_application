import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/report_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class MyReportsScreen extends ConsumerStatefulWidget {
  const MyReportsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends ConsumerState<MyReportsScreen> {
  final ReportService _reportService = ReportService();
  List<dynamic> _reports = [];
  bool _isLoading = true;
  String? _error;

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
      final result = await _reportService.getMyReports();

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

  String _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'orange';
      case 'under_review':
        return 'blue';
      case 'resolved':
        return 'green';
      case 'dismissed':
        return 'grey';
      default:
        return 'grey';
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.myReports2,
          style: context.titleLarge,
        ),
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
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
                            'No reports submitted',
                            style: context.titleLarge.copyWith(
                              color: context.textPrimary,
                            ),
                          ),
                          Spacing.gapSM,
                          Text(
                            'Reports you submit will appear here',
                            style: context.bodyMedium.copyWith(
                              color: context.textSecondary,
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
                          final status = report['status']?.toString() ?? 'pending';
                          final statusColor = _getStatusColor(status);

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
                                  color: _getStatusColorValue(statusColor).withOpacity(0.1),
                                  borderRadius: AppRadius.borderSM,
                                ),
                                child: Icon(
                                  Icons.flag_outlined,
                                  color: _getStatusColorValue(statusColor),
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                '${_getTypeLabel(report['type'])} Report',
                                style: context.titleMedium,
                              ),
                              subtitle: Text(
                                'Reason: ${_getReasonLabel(report['reason'])}',
                                style: context.caption,
                              ),
                              trailing: Chip(
                                label: Text(
                                  status.toUpperCase(),
                                  style: context.captionSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColorValue(statusColor),
                                  ),
                                ),
                                backgroundColor: _getStatusColorValue(statusColor).withOpacity(0.1),
                              ),
                              children: [
                                Padding(
                                  padding: Spacing.paddingLG,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInfoRow(
                                        'Reported ID',
                                        report['reportId']?.toString() ?? 'N/A',
                                      ),
                                      Spacing.gapSM,
                                      _buildInfoRow(
                                        'Status',
                                        status.toUpperCase(),
                                      ),
                                      Spacing.gapSM,
                                      _buildInfoRow(
                                        'Reason',
                                        _getReasonLabel(report['reason']),
                                      ),
                                      if (report['description'] != null &&
                                          report['description'].toString().isNotEmpty) ...[
                                        Spacing.gapSM,
                                        _buildInfoRow(
                                          'Description',
                                          report['description'].toString(),
                                        ),
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
                                        _buildInfoRow(
                                          'Moderator Notes',
                                          report['moderatorNotes'].toString(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
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

  Color _getStatusColorValue(String colorName) {
    switch (colorName) {
      case 'orange':
        return AppColors.warning;
      case 'blue':
        return AppColors.info;
      case 'green':
        return AppColors.success;
      case 'grey':
        return AppColors.gray500;
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
