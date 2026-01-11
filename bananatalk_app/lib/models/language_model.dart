import 'package:bananatalk_app/utils/language_flags.dart';

/// Language model class
class Language {
  final String id;
  final String code;
  final String name;
  final String nativeName;

  Language({
    required this.id,
    required this.code,
    required this.name,
    required this.nativeName,
  });

  /// Get the flag emoji for this language
  String get flag => LanguageFlags.getFlag(code);
  
  /// Check if this language is in the recommended list
  bool get isRecommended => LanguageFlags.isRecommended(code);

  /// Parse from JSON (from your backend)
  factory Language.fromJson(Map<String, dynamic> json) {
    String id = '';
    if (json['_id'] != null) {
      if (json['_id'] is Map) {
        id = (json['_id'] as Map)['\$oid']?.toString() ?? '';
      } else {
        id = json['_id'].toString();
      }
    }
    
    return Language(
      id: id,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nativeName: json['nativeName']?.toString() ?? '',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'code': code,
      'name': name,
      'nativeName': nativeName,
    };
  }

  @override
  String toString() => '$name ($nativeName)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Language &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

