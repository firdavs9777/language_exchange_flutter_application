# New Model

Create a new data model for the BananaTalk app.

## Instructions

When creating a new model:

1. **File Location:** Place in `lib/models/<feature>/` for domain models or `lib/providers/provider_models/` for state models
2. **Immutability:** All fields must be `final`
3. **Safe Parsing:** Always handle nullable fields with defaults — use helper functions like `_safeInt()` for numeric parsing
4. **JSON Keys:** Backend uses `_id` for MongoDB IDs — map to `id` in the model
5. **copyWith:** Include a `copyWith()` method for state models that need updates

## Model Template

```dart
class FeatureModel {
  final String id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final bool isActive;

  FeatureModel({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    this.isActive = true,
  });

  factory FeatureModel.fromJson(Map<String, dynamic> json) {
    return FeatureModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      isActive: json['isActive'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'isActive': isActive,
  };

  FeatureModel copyWith({
    String? title,
    String? description,
    bool? isActive,
  }) {
    return FeatureModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
```

## Safe Parsing Helpers

```dart
int _safeInt(dynamic value, [int defaultValue = 0]) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}
```

## Checklist
- [ ] All fields are `final`
- [ ] `fromJson` handles null/missing fields safely
- [ ] MongoDB `_id` mapped to `id`
- [ ] `toJson` excludes server-generated fields (id, createdAt)
- [ ] `copyWith` included if model is used in state management
