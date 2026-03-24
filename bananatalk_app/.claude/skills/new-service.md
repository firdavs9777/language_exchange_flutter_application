# New Service

Create a new API service for the BananaTalk app.

## Instructions

When creating a new service:

1. **File Location:** Place in `lib/services/<feature>_service.dart`
2. **API Client:** Use the singleton `ApiClient` from `lib/services/api_client.dart` — never create raw HTTP clients
3. **Endpoints:** Define endpoint URLs in `lib/service/endpoints.dart`
4. **Error Handling:** Use try/catch with meaningful error messages; ApiClient handles token refresh and 401s automatically
5. **Provider:** Create a corresponding provider in `lib/providers/provider_root/` to expose the service to widgets

## Service Template

```dart
import 'dart:convert';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/service/endpoints.dart';

class FeatureService {
  final ApiClient _apiClient = ApiClient();

  Future<List<FeatureModel>> getItems() async {
    final response = await _apiClient.get(Endpoints.featureList);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['items'] as List)
          .map((json) => FeatureModel.fromJson(json))
          .toList();
    }
    throw Exception('Failed to load items');
  }

  Future<FeatureModel> createItem(Map<String, dynamic> body) async {
    final response = await _apiClient.post(Endpoints.featureCreate, body: body);
    if (response.statusCode == 201) {
      return FeatureModel.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to create item');
  }
}
```

## Provider Template

```dart
// In lib/providers/provider_root/feature_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final featureServiceProvider = Provider((ref) => FeatureService());

final featureListProvider = FutureProvider<List<FeatureModel>>((ref) async {
  final service = ref.read(featureServiceProvider);
  return service.getItems();
});
```

## Checklist
- [ ] Service class in `lib/services/`
- [ ] Endpoints added to `lib/service/endpoints.dart`
- [ ] Provider created in `lib/providers/provider_root/`
- [ ] Model created/updated in `lib/models/`
