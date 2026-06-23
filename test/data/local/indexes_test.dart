import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suq/data/local/app_database.dart';

void main() {
  test('fresh DB creates the hot-path performance indexes', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final rows = await db
        .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_local_%'")
        .get();
    final names = rows.map((r) => r.read<String>('name')).toSet();

    // Spot-check a few across the queued tables and FK joins.
    expect(names, contains('idx_local_sales_synced'));
    expect(names, contains('idx_local_refunds_sale'));
    expect(names, contains('idx_local_sib_batch'));
    expect(names, contains('idx_local_credit_payments_synced'));
  });
}
