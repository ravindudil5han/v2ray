import 'package:http/http.dart' as http;
import 'profile_service.dart';

/// Service for downloading and updating V2Ray subscriptions.
class SubscriptionService {
  final ProfileService _profileService;

  SubscriptionService(this._profileService);

  Future<int> updateFromUrl(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'NetMod/1.0.0 (Windows NT 10.0; Win64; x64) v2ray',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final count = await _profileService.importFromText(response.body);
        return count;
      }
    } catch (_) {}
    return 0;
  }
}
