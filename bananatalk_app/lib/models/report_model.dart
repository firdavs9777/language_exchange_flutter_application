class Report {
  final String id;
  final String type; // 'user', 'moment', 'comment', 'message', 'story'
  final String reportId; // ID of the reported content
  final String reportedBy; // ID of the user who reported
  final String reportedUser; // ID of the user who owns the content
  final String reason; // 'spam', 'harassment', 'hate_speech', 'violence', 'nudity', 'false_information', 'copyright', 'other'
  final String? description;
  final List<EvidenceFile>? evidence;
  final String status; // 'pending', 'under_review', 'resolved', 'dismissed'
  final String moderatorAction; // 'pending', 'content_removed', 'user_warned', 'user_suspended', 'user_banned', 'no_violation'
  final String? moderatedBy; // ID of the moderator
  final String? moderatorNotes;
  final DateTime? reviewedAt;
  final DateTime? resolvedAt;
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final bool contentHidden;
  final DateTime createdAt;
  final DateTime updatedAt;

  Report({
    required this.id,
    required this.type,
    required this.reportId,
    required this.reportedBy,
    required this.reportedUser,
    required this.reason,
    this.description,
    this.evidence,
    this.status = 'pending',
    this.moderatorAction = 'pending',
    this.moderatedBy,
    this.moderatorNotes,
    this.reviewedAt,
    this.resolvedAt,
    this.priority = 'medium',
    this.contentHidden = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['_id']?.toString() ?? '',
      type: json['type'] ?? '',
      reportId: json['reportId']?.toString() ?? '',
      reportedBy: json['reportedBy']?.toString() ?? '',
      reportedUser: json['reportedUser']?.toString() ?? '',
      reason: json['reason'] ?? '',
      description: json['description'],
      evidence: json['evidence'] != null
          ? List<EvidenceFile>.from(
              (json['evidence'] as List?)?.map(
                (e) => EvidenceFile.fromJson(e as Map<String, dynamic>),
              ) ?? [],
            )
          : null,
      status: json['status'] ?? 'pending',
      moderatorAction: json['moderatorAction'] ?? 'pending',
      moderatedBy: json['moderatedBy']?.toString(),
      moderatorNotes: json['moderatorNotes'],
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'])
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'])
          : null,
      priority: json['priority'] ?? 'medium',
      contentHidden: json['contentHidden'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'reportId': reportId,
      'reportedBy': reportedBy,
      'reportedUser': reportedUser,
      'reason': reason,
      'description': description,
      if (evidence != null) 'evidence': evidence!.map((e) => e.toJson()).toList(),
      'status': status,
      'moderatorAction': moderatorAction,
      'moderatedBy': moderatedBy,
      'moderatorNotes': moderatorNotes,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'priority': priority,
      'contentHidden': contentHidden,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Report copyWith({
    String? id,
    String? type,
    String? reportId,
    String? reportedBy,
    String? reportedUser,
    String? reason,
    String? description,
    List<EvidenceFile>? evidence,
    String? status,
    String? moderatorAction,
    String? moderatedBy,
    String? moderatorNotes,
    DateTime? reviewedAt,
    DateTime? resolvedAt,
    String? priority,
    bool? contentHidden,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Report(
      id: id ?? this.id,
      type: type ?? this.type,
      reportId: reportId ?? this.reportId,
      reportedBy: reportedBy ?? this.reportedBy,
      reportedUser: reportedUser ?? this.reportedUser,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      evidence: evidence ?? this.evidence,
      status: status ?? this.status,
      moderatorAction: moderatorAction ?? this.moderatorAction,
      moderatedBy: moderatedBy ?? this.moderatedBy,
      moderatorNotes: moderatorNotes ?? this.moderatorNotes,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      priority: priority ?? this.priority,
      contentHidden: contentHidden ?? this.contentHidden,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class EvidenceFile {
  final String filename;
  final String url;
  final String type; // 'image' or 'text'
  final int size;    // bytes
  final DateTime uploadedAt;

  EvidenceFile({
    required this.filename,
    required this.url,
    required this.type,
    required this.size,
    required this.uploadedAt,
  });

  factory EvidenceFile.fromJson(Map<String, dynamic> json) {
    return EvidenceFile(
      filename: json['filename'] ?? '',
      url: json['url'] ?? '',
      type: json['type'] ?? 'image',
      size: json['size'] ?? 0,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'url': url,
      'type': type,
      'size': size,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}
