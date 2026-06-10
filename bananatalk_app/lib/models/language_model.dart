import 'package:bananatalk_app/utils/language_flags.dart';

/// Language model class
class Language {
  final String id;
  final String code;
  final String name;
  final String nativeName;
  final String? _backendFlag;

  Language({
    required this.id,
    required this.code,
    required this.name,
    required this.nativeName,
    String? backendFlag,
  }) : _backendFlag = backendFlag;

  /// Get the flag emoji for this language. Prefers the client-side map (so
  /// region overrides like zh-CN/zh-TW work), falls back to the backend's
  /// `flag` field for anything the client doesn't know (e.g. sign languages).
  String get flag {
    final clientFlag = LanguageFlags.getFlag(code);
    if (clientFlag != '🌐') return clientFlag;
    final backend = _backendFlag;
    if (backend != null && backend.isNotEmpty) return backend;
    return '🌐';
  }

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
      backendFlag: json['flag']?.toString(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'code': code,
      'name': name,
      'nativeName': nativeName,
      if (_backendFlag != null) 'flag': _backendFlag,
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

