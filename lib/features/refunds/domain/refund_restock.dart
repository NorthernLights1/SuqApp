import 'package:decimal/decimal.dart';

/// One lot the original sale line drew from, and how many units came off it.
typedef LotDraw = ({String batchId, Decimal depleted});

/// How many units to return to a specific lot on restock.
typedef LotReturn = ({String batchId, Decimal quantity});

/// Distributes [returnQty] returned units back across the lots the sale line
/// originally drew from ([draws], in the order they were drawn — FEFO), capping
/// each lot at what it gave up. A partial refund returns to the earliest-drawn
/// lots first, the natural inverse of FEFO depletion.
///
/// Pure + deterministic so it can be unit-tested without a database. Returns
/// only lots that receive a positive amount. If [returnQty] exceeds the total
/// depleted (shouldn't happen — the caller caps at remaining-refundable), the
/// surplus is dropped rather than invented onto a lot.
List<LotReturn> allocateRestock(List<LotDraw> draws, Decimal returnQty) {
  final out = <LotReturn>[];
  var remaining = returnQty;
  for (final d in draws) {
    if (remaining <= Decimal.zero) break;
    final take = remaining < d.depleted ? remaining : d.depleted;
    if (take > Decimal.zero) {
      out.add((batchId: d.batchId, quantity: take));
      remaining -= take;
    }
  }
  return out;
}

/// Money to refund for returning [refundQty] units of a line whose full
/// [lineTotal] covers [lineQty] units (so any line discount is shared pro-rata).
/// Returning the whole line gives back exactly [lineTotal]; a partial return is
/// proportional, rounded to 2 places.
Decimal proportionalRefund(
    Decimal lineTotal, Decimal lineQty, Decimal refundQty) {
  if (lineQty <= Decimal.zero) return Decimal.zero;
  if (refundQty >= lineQty) return lineTotal;
  return (lineTotal * refundQty / lineQty)
      .toDecimal(scaleOnInfinitePrecision: 2);
}

// ponytail: tiny self-check — run `dart run lib/features/refunds/domain/refund_restock.dart`.
void main() {
  Decimal d(String s) => Decimal.parse(s);

  // Full return gives back the exact line total (no rounding drift).
  assert(proportionalRefund(d('100'), d('4'), d('4')) == d('100'));
  // Half the line → half the money.
  assert(proportionalRefund(d('100'), d('4'), d('2')) == d('50'));
  // Discounted line (total < unit*qty) refunds pro-rata, not full price.
  assert(proportionalRefund(d('90'), d('3'), d('1')) == d('30'));

  // Full return across two lots.
  final r1 = allocateRestock(
      [(batchId: 'a', depleted: d('3')), (batchId: 'b', depleted: d('2'))],
      d('5'));
  assert(r1.length == 2 && r1[0].quantity == d('3') && r1[1].quantity == d('2'));

  // Partial return fills the earliest-drawn lot first.
  final r2 = allocateRestock(
      [(batchId: 'a', depleted: d('3')), (batchId: 'b', depleted: d('2'))],
      d('2'));
  assert(r2.length == 1 && r2[0].batchId == 'a' && r2[0].quantity == d('2'));

  // Partial return spilling into the second lot.
  final r3 = allocateRestock(
      [(batchId: 'a', depleted: d('3')), (batchId: 'b', depleted: d('2'))],
      d('4'));
  assert(r3.length == 2 && r3[0].quantity == d('3') && r3[1].quantity == d('1'));

  // Surplus is dropped, never invented onto a lot.
  final r4 = allocateRestock([(batchId: 'a', depleted: d('1'))], d('5'));
  assert(r4.length == 1 && r4[0].quantity == d('1'));

  // ignore: avoid_print
  print('refund_restock self-check OK');
}
