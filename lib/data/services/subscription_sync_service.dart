import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import 'api_client.dart';

class SubscriptionSyncResult {
  final bool success;
  final String message;
  final UserModel? user;
  final String subscriptionTier;

  const SubscriptionSyncResult({
    required this.success,
    required this.message,
    this.user,
    required this.subscriptionTier,
  });
}

class SubscriptionSyncService {
  final ApiClient _apiClient;

  SubscriptionSyncService([ApiClient? apiClient])
    : _apiClient = apiClient ?? ApiClient();

  Future<SubscriptionSyncResult> sync() async {
    debugPrint(
      'SubscriptionDebug[api.subscriptionSync]: POST subscription/sync start',
    );
    final response = await _apiClient.post('subscription/sync');
    final success = response['success'] == true;
    debugPrint(
      'SubscriptionDebug[api.subscriptionSync]: success=$success '
      'tier=${response['subscription_tier']} message="${response['message']}" '
      'hasUser=${response['user'] is Map<String, dynamic>} '
      'hasSubscription=${response['subscription'] is Map<String, dynamic>}',
    );

    return SubscriptionSyncResult(
      success: success,
      message: response['message']?.toString() ?? '',
      user: response['user'] is Map<String, dynamic>
          ? UserModel.fromJson(response['user'] as Map<String, dynamic>)
          : null,
      subscriptionTier: response['subscription_tier']?.toString() ?? 'free',
    );
  }
}
