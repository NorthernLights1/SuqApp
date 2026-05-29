import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/interfaces/export_service_interface.dart';

class ExportService implements IExportService {
  ExportService(this._supabase);
  final SupabaseClient _supabase;

  @override
  Future<String> generate({
    required ExportFormat format,
    required ReportType reportType,
    required ExportPeriod period,
    required String branchId,
    String? shopId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final resolvedShopId = shopId ??
        await _supabase
            .from('branches')
            .select('shop_id')
            .eq('id', branchId)
            .single()
            .then((r) => r['shop_id'] as String);

    final result = await _supabase.from('export_jobs').insert({
      'shop_id': resolvedShopId,
      'branch_id': branchId,
      'requested_by': userId,
      'format': format.name,
      'report_type': reportType.name,
      'period_type': period.type.name,
      'date_from': period.from.toIso8601String().substring(0, 10),
      'date_to': period.to.toIso8601String().substring(0, 10),
      'status': 'pending',
    }).select('id').single();

    return result['id'] as String;
  }
}
