import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/report_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
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
          const SnackBar(
            content: Text('Review started'),
            backgroundColor: Colors.green,
          ),
        );
        _loadReports();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to start review'),
            backgroundColor: Colors.red,
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
          const SnackBar(
            content: Text('Report resolved'),
            backgroundColor: Colors.green,
          ),
        );
        _loadReports();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to resolve report'),
            backgroundColor: Colors.red,
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
          const SnackBar(
            content: Text('Report dismissed'),
            backgroundColor: Colors.green,
          ),
        );
        _loadReports();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to dismiss report'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showResolveDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Action'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('No Violation'),
              onTap: () => Navigator.pop(context, 'no_violation'),
            ),
            ListTile(
              title: const Text('Content Removed'),
              onTap: () => Navigator.pop(context, 'content_removed'),
            ),
            ListTile(
              title: const Text('User Warned'),
              onTap: () => Navigator.pop(context, 'user_warned'),
            ),
            ListTile(
              title: const Text('User Suspended'),
              onTap: () => Navigator.pop(context, 'user_suspended'),
            ),
            ListTile(
              title: const Text('User Banned'),
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
        title: const Text('Add Notes (Optional)'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter moderator notes...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports Management'),
        backgroundColor: colorScheme.surface,
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
                              child: const Text('Retry'),
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
                                  'No reports found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: context.textPrimary,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('Pending', pendingCount, Colors.orange),
          ),
          Expanded(
            child: _buildStatItem('Under Review', underReviewCount, Colors.blue),
          ),
          Expanded(
            child: _buildStatItem('Resolved', resolvedCount, Colors.green),
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
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final status = report['status']?.toString() ?? 'pending';
    final priority = report['priority']?.toString() ?? 'medium';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getPriorityColor(priority).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.flag_outlined,
            color: _getPriorityColor(priority),
            size: 24,
          ),
        ),
        title: Text(
          '${_getTypeLabel(report['type'])} Report',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reason: ${_getReasonLabel(report['reason'])}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    status.toUpperCase(),
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: _getStatusColor(status).withOpacity(0.1),
                  labelStyle: TextStyle(color: _getStatusColor(status)),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    priority.toUpperCase(),
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: _getPriorityColor(priority).withOpacity(0.1),
                  labelStyle: TextStyle(color: _getPriorityColor(priority)),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            if (status == 'pending')
              const PopupMenuItem(
                value: 'review',
                child: Row(
                  children: [
                    Icon(Icons.visibility, size: 20),
                    SizedBox(width: 8),
                    Text('Start Review'),
                  ],
                ),
              ),
            if (status == 'under_review' || status == 'pending')
              const PopupMenuItem(
                value: 'resolve',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 20),
                    SizedBox(width: 8),
                    Text('Resolve'),
                  ],
                ),
              ),
            if (status == 'pending' || status == 'under_review')
              const PopupMenuItem(
                value: 'dismiss',
                child: Row(
                  children: [
                    Icon(Icons.cancel, size: 20),
                    SizedBox(width: 8),
                    Text('Dismiss'),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Report ID', report['_id']?.toString() ?? 'N/A'),
                const SizedBox(height: 8),
                _buildInfoRow('Reported By', report['reportedBy']?['name'] ?? 'N/A'),
                const SizedBox(height: 8),
                _buildInfoRow('Reported User', report['reportedUser']?['name'] ?? 'N/A'),
                const SizedBox(height: 8),
                _buildInfoRow('Type', _getTypeLabel(report['type'])),
                const SizedBox(height: 8),
                _buildInfoRow('Reason', _getReasonLabel(report['reason'])),
                if (report['description'] != null &&
                    report['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Description', report['description'].toString()),
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Reports'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
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
              decoration: const InputDecoration(labelText: 'Type'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
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
              decoration: const InputDecoration(labelText: 'Priority'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
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
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadReports();
            },
            child: const Text('Apply'),
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
        return Colors.orange;
      case 'under_review':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'urgent':
        return Colors.purple;
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

