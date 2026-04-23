import 'package:flutter_test/flutter_test.dart';
import 'package:gigi/data/services/quota_service.dart';
import 'package:gigi/providers/quota_provider.dart';

import '../helpers/quota_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuotaProvider', () {
    test('refresh loads quota status from service', () async {
      final service = FakeQuotaService(
        statuses: [
          quotaStatus(
            recipes: quotaUsage(
              action: 'recipes',
              label: 'Chef AI',
              used: 1,
              limit: 4,
              remaining: 3,
            ),
          ),
        ],
      );
      final provider = QuotaProvider.withService(service);

      await provider.refresh();

      expect(provider.hasStatus, isTrue);
      expect(provider.error, isNull);
      expect(provider.usageFor(QuotaAction.recipes)?.label, 'Chef AI');
      expect(provider.usageFor(QuotaAction.recipes)?.remaining, 3);
      expect(service.statusCalls, 1);
    });

    test('optimisticConsume updates cached finite quota immediately', () async {
      final provider = QuotaProvider.withService(
        FakeQuotaService(
          statuses: [
            quotaStatus(
              recipes: quotaUsage(
                action: 'recipes',
                used: 3,
                limit: 4,
                remaining: 1,
              ),
            ),
          ],
        ),
      );
      await provider.refresh();

      provider.optimisticConsume(QuotaAction.recipes);

      final usage = provider.usageFor(QuotaAction.recipes);
      expect(usage?.used, 4);
      expect(usage?.remaining, 0);
      expect(usage?.canUse, isFalse);
    });

    test('optimisticConsume leaves unlimited quota unchanged', () async {
      final provider = QuotaProvider.withService(
        FakeQuotaService(
          statuses: [
            quotaStatus(
              foodDuel: quotaUsage(
                action: 'food_duel',
                used: 12,
                limit: -1,
                remaining: -1,
                canUse: true,
              ),
            ),
          ],
        ),
      );
      await provider.refresh();

      provider.optimisticConsume(QuotaAction.foodDuel);

      final usage = provider.usageFor(QuotaAction.foodDuel);
      expect(usage?.used, 12);
      expect(usage?.remaining, -1);
      expect(usage?.canUse, isTrue);
    });

    test(
      'syncAfterSuccess optimistically consumes then refetches backend truth',
      () async {
        final service = FakeQuotaService(
          statuses: [
            quotaStatus(
              recipes: quotaUsage(
                action: 'recipes',
                used: 0,
                limit: 4,
                remaining: 4,
              ),
            ),
            quotaStatus(
              recipes: quotaUsage(
                action: 'recipes',
                used: 2,
                limit: 4,
                remaining: 2,
              ),
            ),
          ],
        );
        final provider = QuotaProvider.withService(service);
        await provider.refresh();

        await provider.syncAfterSuccess(QuotaAction.recipes);

        final usage = provider.usageFor(QuotaAction.recipes);
        expect(usage?.used, 2);
        expect(usage?.remaining, 2);
        expect(service.statusCalls, 2);
      },
    );

    test('canPerform refreshes status when backend blocks action', () async {
      final service = FakeQuotaService(
        statuses: [
          quotaStatus(
            formAnalysis: quotaUsage(
              action: 'form_analysis',
              used: 20,
              limit: 20,
              remaining: 0,
              canUse: false,
            ),
          ),
        ],
        checkResult: QuotaCheckResult(
          canPerform: false,
          reason: 'Quota exhausted',
          upgradeNeeded: true,
          subscriptionTier: 'pro',
        ),
      );
      final provider = QuotaProvider.withService(service);

      final result = await provider.canPerform(QuotaAction.formAnalysis);

      expect(result.canPerform, isFalse);
      expect(provider.usageFor(QuotaAction.formAnalysis)?.remaining, 0);
      expect(service.statusCalls, 1);
    });
  });
}
