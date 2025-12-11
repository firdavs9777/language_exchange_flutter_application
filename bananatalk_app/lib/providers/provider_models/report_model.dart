class Report {
  final String id;
  final String type;
  final String reportedId;
  final ReportUser reportedBy;
  final ReportUser reportedUser;
  final String reason;
  final String? description;
  final String status;
  final String moderatorAction;
  final ReportUser? moderatedBy;
  final String? moderatorNotes;
  final DateTime? reviewedAt;
  final DateTime? resolvedAt;
  final String priority;
  final bool contentHidden;
  final DateTime createdAt;
  final DateTime updatedAt;

  Report({
    required this.id,
    required this.type,
    required this.reportedId,
    required this.reportedBy,
    required this.reportedUser,
    required this.reason,
    this.description,
    required this.status,
    required this.moderatorAction,
    this.moderatedBy,
    this.moderatorNotes,
    this.reviewedAt,
    this.resolvedAt,
    required this.priority,
    required this.contentHidden,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['_id'] ?? '',
      type: json['type'] ?? '',
      reportedId: json['reportedId'] ?? '',
      reportedBy: ReportUser.fromJson(json['reportedBy'] ?? {}),
      reportedUser: ReportUser.fromJson(json['reportedUser'] ?? {}),
      reason: json['reason'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'pending',
      moderatorAction: json['moderatorAction'] ?? 'none',
      moderatedBy: json['moderatedBy'] != null
          ? ReportUser.fromJson(json['moderatedBy'])
          : null,
      moderatorNotes: json['moderatorNotes'],
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'])
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'])
          : null,
      priority: json['priority'] ?? 'medium',
      contentHidden: json['contentHidden'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'reportedId': reportedId,
      'reportedBy': reportedBy.toJson(),
      'reportedUser': reportedUser.toJson(),
      'reason': reason,
      'description': description,
      'status': status,
      'moderatorAction': moderatorAction,
      'moderatedBy': moderatedBy?.toJson(),
      'moderatorNotes': moderatorNotes,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'priority': priority,
      'contentHidden': contentHidden,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper methods for status checking
  bool get isPending