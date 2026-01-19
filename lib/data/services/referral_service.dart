import '../services/api_client.dart';

class ReferralService {
  final ApiClient _apiClient;

  ReferralService(this._apiClient);

  /// Get referral stats for current user
  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _apiClient.get('/referral/stats');
      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Claim the referral reward (3 invites = 1 month premium)
  Future<Map<String, dynamic>> claimReward() async {
    try {
      final response = await _apiClient.post('/referral/claim');
      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
