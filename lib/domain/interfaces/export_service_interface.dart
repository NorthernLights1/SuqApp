abstract interface class IExportService {
  Future<String> generate({
    required ExportFormat format,
    required ReportType reportType,
    required ExportPeriod period,
    required String branchId,
    String? shopId,
  });
}

enum ExportFormat { pdf, excel }

enum ReportType { sales, inventory, financial, expenses, full }

enum PeriodType { daily, weekly, monthly, yearly, custom }

class ExportPeriod {
  const ExportPeriod({required this.type, required this.from, required this.to});
  final PeriodType type;
  final DateTime from;
  final DateTime to;
}
