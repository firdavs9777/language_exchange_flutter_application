import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/report_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myReports2),
        backgroundColor: colorScheme.surface,
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
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(color: context.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
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
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No reports submitted',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Reports you submit will appear here',
                            style: TextStyle(
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadReports,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          final report = _reports[index];
                          final status = report['status']?.toString() ?? 'pending';
                          final statusColor = _getStatusColor(status);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ExpansionTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getStatusColorValue(statusColor).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.flag_outlined,
                                  color: _getStatusColorValue(statusColor),
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                '${_getTypeLabel(report['type'])} Report',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Reason: ${_getReasonLabel(report['reason'])}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.textSecondary,
                                ),
                              ),
                              trailing: Chip(
                                label: Text(
                                  status.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: _getStatusColorValue(statusColor).withOpacity(0.1),
                                labelStyle: TextStyle(
                                  color: _getStatusColorValue(statusColor),
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInfoRow(
                                        'Reported ID',
                                        report['reportId']?.toString() ?? 'N/A',
                                      ),
                                      const SizedBox(height: 8),
                                      _buildInfoRow(
                                        'Status',
                                        status.toUpperCase(),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildInfoRow(
                                        'Reason',
                                        _getReasonLabel(report['reason']),
                                      ),
                                      if (report['description'] != null &&
                                          report['description'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        _buildInfoRow(
                                          'Description',
                                          report['description'].toString(),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      _buildInfoRow(
                                        'Submitted',
                                        report['createdAt'] != null
                                            ? _formatDate(report['createdAt'].toString())
                                            : 'N/A',
                                      ),
                                      if (report['resolvedAt'] != null) ...[
                                        const SizedBox(height: 8),
                                        _buildInfoRow(
                                          'Resolved',
                                          _formatDate(report['resolvedAt'].toString()),
                                        ),
                                      ],
                                      if (report['moderatorNotes'] != null &&
                                          report['moderatorNotes'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 8),
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
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: context.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColorValue(String colorName) {
    switch (colorName) {
      case 'orange':
        return Colors.orange;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'grey':
        return Colors.grey;
      default:
        return Colors.grey;
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

