import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suq/features/inventory/domain/batch_allocation.dart';

Decimal d(String s) => Decimal.parse(s);
final asOf = DateTime(2026, 6, 21);

void main() {
  group('allocateFefo', () {
    test('a single batch that covers the need yields one allocation', () {
      final r = allocateFefo(
        [BatchAvailability('a', d('10'), DateTime(2027, 1, 1))],
        d('4'),
        asOf,
      );
      expect(r.allocations.length, 1);
      expect(r.allocations.first.batchId, 'a');
      expect(r.allocations.first.quantity, d('4'));
      expect(r.usedExpired, isFalse);
    });

    test('spills across batches in soonest-expiry-first order', () {
      final r = allocateFefo(
        [
          BatchAvailability('late', d('10'), DateTime(2027, 12, 1)),
          BatchAvailability('soon', d('3'), DateTime(2026, 9, 1)),
        ],
        d('5'),
        asOf,
      );
      // Draws the soonest batch fully (3), then 2 from the later one.
      expect(r.allocations.length, 2);
      expect(r.allocations[0].batchId, 'soon');
      expect(r.allocations[0].quantity, d('3'));
      expect(r.allocations[1].batchId, 'late');
      expect(r.allocations[1].quantity, d('2'));
    });

    test('non-perishable (null expiry) batches are drawn last', () {
      final r = allocateFefo(
        [
          BatchAvailability('noexp', d('10'), null),
          BatchAvailability('dated', d('2'), DateTime(2026, 8, 1)),
        ],
        d('5'),
        asOf,
      );
      expect(r.allocations[0].batchId, 'dated'); // dated first
      expect(r.allocations[1].batchId, 'noexp');
    });

    test('skips batches with non-positive remaining', () {
      final r = allocateFefo(
        [
          BatchAvailability('empty', d('0'), DateTime(2026, 7, 1)),
          BatchAvailability('full', d('8'), DateTime(2026, 8, 1)),
        ],
        d('5'),
        asOf,
      );
      expect(r.allocations.length, 1);
      expect(r.allocations.first.batchId, 'full');
    });

    test('flags usedExpired when a drawn batch is past its expiry', () {
      final r = allocateFefo(
        [BatchAvailability('old', d('10'), DateTime(2026, 1, 1))], // expired
        d('3'),
        asOf,
      );
      expect(r.usedExpired, isTrue);
    });

    test('oversell piles the shortfall on the last drawn batch (goes negative)',
        () {
      final r = allocateFefo(
        [
          BatchAvailability('soon', d('3'), DateTime(2026, 9, 1)),
          BatchAvailability('late', d('4'), DateTime(2027, 1, 1)),
        ],
        d('10'), // only 7 available
        asOf,
      );
      // 3 + 4 drawn, remaining 3 dumped on the last batch (late): 4 + 3 = 7.
      final total = r.allocations.fold(Decimal.zero, (s, a) => s + a.quantity);
      expect(total, d('10'));
      final late = r.allocations.firstWhere((a) => a.batchId == 'late');
      expect(late.quantity, d('7'));
    });

    test('oversell with zero batches yields no allocation', () {
      final r = allocateFefo(const [], d('5'), asOf);
      expect(r.allocations, isEmpty);
    });
  });
}
