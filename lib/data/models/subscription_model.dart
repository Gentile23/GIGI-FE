import '../../core/constants/subscription_tiers.dart';

/// Subscription model
class SubscriptionModel {
  final String id;
  final String userId;
  final SubscriptionTier tier;
  final DateTime startDate;
  final DateTime? endDate;
  final SubscriptionStatus status;
  final DateTime? lastPlanGenerated;

  // Added getter for simplified status check
  // isActive is true only if status is active AND tier is not free
  bool get isActive =>
      status == SubscriptionStatus.active && tier != SubscriptionTier.free;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.tier,
    required this.startDate,
    this.endDate,
    required this.status,
    this.lastPlanGenerated,
  });

  bool canGeneratePlan() {
    if (tier != SubscriptionTier.free) {
      return true; // Premium, Gold, Platinum can generate unlimited plans
    }

    // Free tier: check if 2 months have passed since last generation
    if (lastPlanGenerated == null) {
      return true; // First plan
    }

    final daysSinceLastPlan = DateTime.now()
        .difference(lastPlanGenerated!)
        .inDays;
    return daysSinceLastPlan >= 60; // 2 months = ~60 days
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'tier': tier.toString(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status.toString(),
      'lastPlanGenerated': lastPlanGenerated?.toIso8601String(),
    };
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'].toString(),
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      tier: SubscriptionTier.values.firstWhere(
        (e) => e.toString().split('.').last == json['tier'],
        orElse: () => json['tier'] == 'premium'
            ? SubscriptionTier.pro
            : SubscriptionTier.free,
      ),
      startDate: DateTime.parse(json['start_date'] ?? json['startDate']),
      endDate: json['end_date'] != null || json['endDate'] != null
          ? DateTime.parse(json['end_date'] ?? json['endDate'])
          : null,
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => json['tier'] == 'free' || json['tier'] == null
            ? SubscriptionStatus
                  .expired // Free tier doesn't have an "active" subscription object typically
            : SubscriptionStatus.active,
      ),
      lastPlanGenerated:
          json['last_plan_generated'] != null ||
              json['lastPlanGenerated'] != null
          ? DateTime.parse(
              json['last_plan_generated'] ?? json['lastPlanGenerated'],
            )
          : null,
    );
  }

  SubscriptionModel copyWith({
    String? id,
    String? userId,
    SubscriptionTier? tier,
    DateTime? startDate,
    DateTime? endDate,
    SubscriptionStatus? status,
    DateTime? lastPlanGenerated,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tier: tier ?? this.tier,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      lastPlanGenerated: lastPlanGenerated ?? this.lastPlanGenerated,
    );
  }
}

enum SubscriptionStatus { active, expired, cancelled }
