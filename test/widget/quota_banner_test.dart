import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gigi/data/services/quota_service.dart';
import 'package:gigi/presentation/widgets/quota/quota_banner.dart';
import 'package:gigi/providers/quota_provider.dart';
import 'package:provider/provider.dart';

import '../helpers/quota_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuotaBanner', () {
    testWidgets('shows backend quota label, remaining count, and period', (
      tester,
    ) async {
      final provider = QuotaProvider.withService(
        FakeQuotaService(
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
        ),
      );

      await tester.pumpWidget(testApp(provider, QuotaAction.recipes));
      await tester.pumpAndSettle();

      expect(find.text('Chef AI'), findsOneWidget);
      expect(find.text('1/4 usati a settimana'), findsOneWidget);
      expect(find.text('3/4'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Sblocca più utilizzi'), findsNothing);
    });

    testWidgets('shows upgrade action when backend says quota is exhausted', (
      tester,
    ) async {
      final provider = QuotaProvider.withService(
        FakeQuotaService(
          statuses: [
            quotaStatus(
              foodDuel: quotaUsage(
                action: 'food_duel',
                label: 'Food Duel AI',
                used: 3,
                limit: 3,
                remaining: 0,
                canUse: false,
              ),
            ),
          ],
        ),
      );

      await tester.pumpWidget(testApp(provider, QuotaAction.foodDuel));
      await tester.pumpAndSettle();

      expect(find.text('Food Duel AI'), findsOneWidget);
      expect(find.text('3/3 usati a settimana'), findsOneWidget);
      expect(find.text('0/3'), findsOneWidget);
      expect(find.text('Sblocca più utilizzi'), findsOneWidget);
    });

    testWidgets('shows unlimited state without progress or upgrade button', (
      tester,
    ) async {
      final provider = QuotaProvider.withService(
        FakeQuotaService(
          statuses: [
            quotaStatus(
              foodDuel: quotaUsage(
                action: 'food_duel',
                label: 'Food Duel AI',
                used: 8,
                limit: -1,
                remaining: -1,
                canUse: true,
                period: 'unlimited',
                periodLabel: 'illimitato',
              ),
            ),
          ],
        ),
      );

      await tester.pumpWidget(testApp(provider, QuotaAction.foodDuel));
      await tester.pumpAndSettle();

      expect(find.text('Food Duel AI'), findsOneWidget);
      expect(find.text('Utilizzi illimitati'), findsOneWidget);
      expect(find.text('∞'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Sblocca più utilizzi'), findsNothing);
    });
  });
}

Widget testApp(QuotaProvider provider, QuotaAction action) {
  return ChangeNotifierProvider<QuotaProvider>.value(
    value: provider,
    child: MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: QuotaBanner(action: action),
        ),
      ),
    ),
  );
}
