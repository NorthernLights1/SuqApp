import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suq/features/refunds/domain/refund_restock.dart';

Decimal d(String s) => Decimal.parse(s);

void main() {
  group('allocateRestock', () {
    test('sum of returns always equals the requested return qty', () {
      final returns = allocateRestock(
        [(batchId: 'a', depleted: d('3')), (batchId: 'b', depleted: d('5'))],
        d('6'),
      );
      final total = returns.fold(Decimal.zero, (s, r) => s + r.quantity);
      expect(total, d('6'));
    });

    test('partial return fills earliest-drawn lot first', () {
      final returns = allocateRestock(
        [(batchId: 'a', depleted: d('3')), (batchId: 'b', depleted: d('5'))],
        d('2'),
      );
      expect(returns.length, 1);
      expect(returns.first.batchId, 'a');
      expect(returns.first.quantity, d('2'));
    });

    test('return spilling into the second lot is split correctly', () {
      final returns = allocateRestock(
        [(batchId: 'a', depleted: d('3')), (batchId: 'b', depleted: d('5'))],
        d('5'),
      );
      expect(returns.length, 2);
      expect(returns[0], (batchId: 'a', quantity: d('3')));
      expect(returns[1], (batchId: 'b', quantity: d('2')));
    });

    test('surplus beyond total depleted is dropped, not invented onto a lot', () {
      final returns = allocateRestock(
        [(batchId: 'a', depleted: d('2'))],
        d('10'),
      );
      expect(returns.length, 1);
      expect(returns.first.quantity, d('2'));
      // sum < requested — caller detects the shortfall and fails the refund
      final total = returns.fold(Decimal.zero, (s, r) => s + r.quantity);
      expect(total, d('2'));
    });

    test('full return across three lots sums to exact total', () {
      final returns = allocateRestock(
        [
          (batchId: 'a', depleted: d('2')),
          (batchId: 'b', depleted: d('3')),
          (batchId: 'c', depleted: d('5')),
        ],
        d('10'),
      );
      expect(returns.length, 3);
      final total = returns.fold(Decimal.zero, (s, r) => s + r.quantity);
      expect(total, d('10'));
    });

    test('zero return qty produces empty list', () {
      final returns = allocateRestock(
        [(batchId: 'a', depleted: d('5'))],
        Decimal.zero,
      );
      expect(returns, isEmpty);
    });
  });

  group('proportionalRefund', () {
    test('full return gives back exact line total', () {
      expect(proportionalRefund(d('100'), d('4'), d('4')), d('100'));
    });

    test('half return gives half the total', () {
      expect(proportionalRefund(d('100'), d('4'), d('2')), d('50'));
    });

    test('discounted line refunds pro-rata, not full unit price', () {
      expect(proportionalRefund(d('90'), d('3'), d('1')), d('30'));
    });

    test('zero line qty returns zero (guard against division by zero)', () {
      expect(proportionalRefund(d('100'), Decimal.zero, d('2')), Decimal.zero);
    });
  });
}
