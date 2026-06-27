/// One supported language in the Exam Study feature.
///
/// Mirrors the backend `ExamLanguage` collection — Phase 1 ships with
/// English / Spanish / Korean, but the client takes whatever the
/// `/exam-study/languages` endpoint returns so future languages light up
/// without an app release.
class ExamLanguage {
  const ExamLanguage({
    required this.id,
    required this.name,
    required this.code,
    this.icon,
    this.active = true,
  });

  final String id;
  final String name;
  final String code; // ISO 639-1 (en, es, ko, …)
  final String? icon; // emoji flag or asset URL
  final bool active;

  factory ExamLanguage.fromJson(Map<String, dynamic> json) {
    return ExamLanguage(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      icon: json['icon']?.toString(),
      active: json['active'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'code': code,
        if (icon != null) 'icon': icon,
        'active': active,
      };
}
