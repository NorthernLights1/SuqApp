import 'package:decimal/decimal.dart';

/// One batch's contribution to a sale line.
class BatchAllocation {
  const BatchAllocation(this.batchId, this.quantity);
  final String batchId;
  final Decimal quantity;

  @override
  String toString() => 'BatchAllocation($batchId, $quantity)';
}

/// Minimal batch view for FEFO: id, remaining quantity, expiry (null = never
/// expires). "Remaining" = received − already-depleted, computed by the caller.
class BatchAvailability {
  const BatchAvailability(this.id, this.remaining, this.expiryDate);
  final String id;
  final Decimal remaining;
  final DateTime? expiryDate;
}

class FefoResult {
  const FefoResult(this.allocations, this.usedExpired);

  /// (batchId, qty) draws that sum to the requested quantity.
  final List<BatchAllocation> allocations;

  /// True if any drawn batch was expired as of the sale date — the caller warns
  /// (warn-but-allow), it does not block.
  final bool usedExpired;
}

/// Allocates [needed] across [batches] First-Expiry-First-Out.
///
/// [batches] need not be pre-sorted — they're ordered here by expiry ascending
/// (soonest first), nulls (non-perishable) last. Each batch contributes up to
/// its remaining quantity; batches with non-positive remaining are skipped.
///
/// If the batches don't cover [needed] (an offline oversell), the shortfall is
/// piled onto the last drawn batch (or the soonest-expiry batch if none were
/// drawable) so that batch goes negative on the server — the existing
/// stock-conflict detector then surfaces the reconciliation.
FefoResult allocateFefo(
  List<BatchAvailability> batches,
  Decimal needed,
  DateTime asOf,
) {
  final sorted = [...batches]..sort((a, b) {
      final ae = a.expiryDate;
      final be = b.expiryDate;
      if (ae == null && be == null) return 0;
      if (ae == null) return 1; // nulls (non-perishable) sort last
      if (be == null) return -1;
      return ae.compareTo(be);
    });
  final today = DateTime(asOf.year, asOf.month, asOf.day);

  final allocs = <BatchAllocation>[];
  var remaining = needed;
  var usedExpired = false;
  String? lastDrawn;

  for (final b in sorted) {
    if (remaining <= Decimal.zero) break;
    if (b.remaining <= Decimal.zero) continue;
    final take = b.remaining < remaining ? b.remaining : remaining;
    allocs.add(BatchAllocation(b.id, take));
    if (_isExpired(b.expiryDate, today)) usedExpired = true;
    remaining -= take;
    lastDrawn = b.id;
  }

  // Offline oversell: dump the shortfall on the last drawn batch (or the
  // soonest-expiry batch when nothing was drawable) so it goes negative → the
  // server's stock-conflict trigger fires on the rollup.
  if (remaining > Decimal.zero) {
    final targetId = lastDrawn ?? (sorted.isNotEmpty ? sorted.first.id : null);
    if (targetId != null) {
      final idx = allocs.indexWhere((a) => a.batchId == targetId);
      if (idx >= 0) {
        allocs[idx] =
            BatchAllocation(targetId, allocs[idx].quantity + remaining);
      } else {
        allocs.add(BatchAllocation(targetId, remaining));
        final tb = sorted.firstWhere((b) => b.id == targetId);
        if (_isExpired(tb.expiryDate, today)) usedExpired = true;
      }
    }
  }

  return FefoResult(allocs, usedExpired);
}

bool _isExpired(DateTime? expiry, DateTime today) =>
    expiry != null && expiry.isBefore(today);
