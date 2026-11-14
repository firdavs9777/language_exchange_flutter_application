import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/services/offers/offer.dart';

/// `GET offers`: zero or one offer for the signed-in user (404 while the
/// engine is off).
class OffersApi {
  OffersApi([ApiClient? client]) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// The current offer, or null for none, a failure or a malformed answer.
  Future<Offer?> fetch() async {
    final res = await _client.get(Endpoints.offersURL, deduplicate: true);
    return offerFromResponse(res);
  }
}

/// The offer in a `GET offers` answer; null unless a 200 carries a
/// well-formed first item.
Offer? offerFromResponse(ApiResponse res) {
  if (!res.success || res.statusCode != 200) return null;
  final body = res.data;
  if (body is! Map) return null;
  final offers = body['offers'];
  if (offers is! List || offers.isEmpty) return null;
  return Offer.fromJson(offers.first);
}
