import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:suq/data/local/seed_service.dart';

void main() {
  group('SeedService.partitionDelta', () {
    Map<String, dynamic> row(String id, String updatedAt, {String? deletedAt}) =>
        {'id': id, 'updated_at': updatedAt, 'deleted_at': deletedAt};

    test('empty page yields nothing and a null cursor', () {
      final p = SeedService.partitionDelta([], collectDead: true);
      expect(p.live, isEmpty);
      expect(p.deadIds, isEmpty);
      expect(p.maxSeen, isNull);
    });

    test('splits live rows from soft-deletes and advances cursor to the max',
        () {
      final rows = [
        row('a', '2026-06-14T10:00:00Z'),
        row('b', '2026-06-14T12:00:00Z', deletedAt: '2026-06-14T12:00:00Z'),
        row('c', '2026-06-14T11:00:00Z'),
      ];
      final p = SeedService.partitionDelta(rows, collectDead: true);
      expect(p.live.map((r) => r['id']), ['a', 'c']);
      expect(p.deadIds, ['b']);
      // maxSeen spans ALL rows, including the deleted one.
      expect(p.maxSeen, DateTime.parse('2026-06-14T12:00:00Z'));
    });

    test('collectDead=false drops dead rows from live but still advances cursor',
        () {
      // A soft-delete on a no-removal table must still move the cursor past it,
      // or the delta pull would re-fetch it forever.
      final rows = [
        row('a', '2026-06-14T10:00:00Z'),
        row('b', '2026-06-14T13:00:00Z', deletedAt: '2026-06-14T13:00:00Z'),
      ];
      final p = SeedService.partitionDelta(rows, collectDead: false);
      expect(p.live.map((r) => r['id']), ['a']);
      expect(p.deadIds, isEmpty);
      expect(p.maxSeen, DateTime.parse('2026-06-14T13:00:00Z'));
    });

    test('a malformed updated_at is skipped, never thrown', () {
      // Guards against a poison row stalling a table's pull forever: the bad
      // timestamp is ignored for the cursor, valid rows still advance it.
      final rows = [
        row('a', 'not-a-timestamp'),
        row('b', '2026-06-14T10:00:00Z'),
      ];
      expect(() => SeedService.partitionDelta(rows, collectDead: true),
          returnsNormally);
      final p = SeedService.partitionDelta(rows, collectDead: true);
      expect(p.live.map((r) => r['id']), ['a', 'b']);
      expect(p.maxSeen, DateTime.parse('2026-06-14T10:00:00Z'));
    });

    test('rows sharing the boundary timestamp resolve to that one cursor', () {
      // Postgres now() is constant per transaction, so a sale + its items share
      // an updated_at; the cursor lands on that shared value (>= overlap then
      // re-fetches them harmlessly).
      final rows = [
        row('a', '2026-06-14T09:30:00Z'),
        row('b', '2026-06-14T09:30:00Z'),
      ];
      final p = SeedService.partitionDelta(rows, collectDead: true);
      expect(p.maxSeen, DateTime.parse('2026-06-14T09:30:00Z'));
      expect(p.live.length, 2);
    });
  });

  test('guardrail: SeedService never pulls operator/admin tables', () {
    // Enforces the documented boundary — license/operator tables must never be
    // replicated. Checks actual table-access calls, not the doc comment.
    // NOTE: lightweight guardrail, not a security boundary — a literal-string
    // scan can be bypassed by dynamic table-name construction. The real wall is
    // server-side RLS (see rls_isolation_test.sql); this just catches the
    // obvious mistake of adding from('license_keys') during a refactor.
    final src =
        File('lib/data/local/seed_service.dart').readAsStringSync();
    expect(src.contains("from('license_keys')"), isFalse,
        reason: 'license_keys must never be pulled into the replica');
    expect(src.contains("from('shop_controls')"), isFalse,
        reason: 'shop_controls must never be pulled into the replica');
  });
}
