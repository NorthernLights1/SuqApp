import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

class ExpenseCategory extends Equatable {
  const ExpenseCategory({required this.id, required this.name});
  final String id;
  final String name;
  factory ExpenseCategory.fromJson(Map<String, dynamic> json) =>
      ExpenseCategory(id: json['id'] as String, name: json['name'] as String);
  @override
  List<Object?> get props => [id, name];
}

class Expense extends Equatable {
  const Expense({
    required this.id,
    required this.branchId,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    this.description,
    required this.recordedBy,
    required this.date,
    required this.createdAt,
  });

  final String id;
  final String branchId;
  final String categoryId;
  final String categoryName;
  final Decimal amount;
  final String? description;
  final String recordedBy;
  final DateTime date;
  final DateTime createdAt;

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        branchId: json['branch_id'] as String,
        categoryId: json['category_id'] as String,
        categoryName:
            (json['expense_categories'] as Map<String, dynamic>?)?['name']
                    as String? ??
                '',
        amount: Decimal.parse(json['amount'].toString()),
        description: json['description'] as String?,
        recordedBy: json['recorded_by'] as String,
        date: DateTime.parse(json['date'] as String),
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );

  @override
  List<Object?> get props => [id, amount, date];
}
