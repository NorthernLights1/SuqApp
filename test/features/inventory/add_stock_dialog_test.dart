import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suq/core/constants/setting_keys.dart';
import 'package:suq/domain/models/product.dart';
import 'package:suq/features/auth/presentation/providers/permissions_provider.dart';
import 'package:suq/features/inventory/data/inventory_remote.dart';
import 'package:suq/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:suq/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:suq/features/settings/presentation/providers/shop_type_provider.dart';

class _RejectingStockAdjustmentNotifier extends StockAdjustmentNotifier {
  static int addBatchCalls = 0;

  @override
  Future<bool> addStockBatch({
    required String productId,
    required Decimal quantity,
    String? batchNumber,
    DateTime? expiryDate,
  }) async {
    addBatchCalls++;
    return true;
  }
}

void main() {
  testWidgets('wholesale Add Stock rejects a blank batch/lot number', (
    tester,
  ) async {
    _RejectingStockAdjustmentNotifier.addBatchCalls = 0;
    final product = Product(
      id: 'p-1',
      shopId: 'shop-1',
      name: 'Aspirin',
      measurementUnitId: 'mu-1',
      measurementUnitAbbr: 'box',
      lowStockThreshold: Decimal.parse('5'),
      isActive: true,
    );
    final stock = StockEntry(
      productId: 'p-1',
      productName: 'Aspirin',
      measurementUnitId: 'mu-1',
      quantity: Decimal.parse('10'),
      lowStockThreshold: Decimal.parse('5'),
      unitAbbr: 'box',
      updatedAt: DateTime(2026, 6, 23),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productsProvider.overrideWith((ref) async => [product]),
          stockLevelsProvider.overrideWith((ref) async => [stock]),
          productCategoriesProvider.overrideWith((ref) async => []),
          permissionsProvider.overrideWith((ref) async => {'inventory.adjust'}),
          shopTypeProvider.overrideWith((ref) async => ShopType.wholesale),
          stockAdjustmentProvider.overrideWith(
            _RejectingStockAdjustmentNotifier.new,
          ),
        ],
        child: const MaterialApp(home: InventoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aspirin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Stock'));
    await tester.pumpAndSettle();

    expect(find.text('Batch / lot number'), findsOneWidget);
    expect(find.text('Batch / lot number (optional)'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, 'Quantity received (box)'),
      '5',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a batch / lot number'), findsOneWidget);
    expect(_RejectingStockAdjustmentNotifier.addBatchCalls, 0);
  });
}
