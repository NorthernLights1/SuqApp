import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/expenses_provider.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesProvider);
    final total = ref.watch(todayExpensesTotalProvider);
    final date = ref.watch(selectedExpenseDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () => _pickDate(context, ref, date),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date + total banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDate(date), style: AppTextStyles.label),
                total.when(
                  data: (t) => Text(
                    'Total: ETB ${t.toStringAsFixed(2)}',
                    style: AppTextStyles.body.copyWith(
                        color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: expenses.when(
              data: (list) => list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.money_off_outlined,
                              size: 64, color: AppColors.textDisabled),
                          const SizedBox(height: 12),
                          Text('No expenses recorded',
                              style: AppTextStyles.headline3),
                          const SizedBox(height: 4),
                          Text('Tap + to record one',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (ctx, i) =>
                          _ExpenseTile(expense: list[i]),
                    ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                  child: Text('Error: $e', style: AppTextStyles.bodySmall)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Record Expense'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showForm(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const RecordExpenseScreen(),
      fullscreenDialog: true,
    ));
  }

  Future<void> _pickDate(
      BuildContext context, WidgetRef ref, DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(selectedExpenseDateProvider.notifier).state = picked;
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense});
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.error.withValues(alpha: 0.1),
        child: const Icon(Icons.money_off_outlined,
            color: AppColors.error, size: 20),
      ),
      title: Text(expense.categoryName, style: AppTextStyles.body),
      subtitle: expense.description != null
          ? Text(expense.description!, style: AppTextStyles.bodySmall)
          : null,
      trailing: Text(
        'ETB ${expense.amount.toStringAsFixed(2)}',
        style: AppTextStyles.body
            .copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Record Expense Screen ────────────────────────────────────────────────────

class RecordExpenseScreen extends ConsumerStatefulWidget {
  const RecordExpenseScreen({super.key});

  @override
  ConsumerState<RecordExpenseScreen> createState() =>
      _RecordExpenseScreenState();
}

class _RecordExpenseScreenState extends ConsumerState<RecordExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  ExpenseCategory? _selectedCategory;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a category')),
      );
      return;
    }
    final amount = Decimal.tryParse(_amountCtrl.text);
    if (amount == null || amount <= Decimal.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    final ok = await ref.read(recordExpenseProvider.notifier).record(
          categoryId: _selectedCategory!.id,
          amount: amount,
          description: _descCtrl.text,
          date: _date,
        );

    if (mounted && ok) Navigator.pop(context);
    if (mounted && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(recordExpenseProvider).error?.toString() ??
              'Failed to record'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(expenseCategoriesProvider);
    final loading = ref.watch(recordExpenseProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Record Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category
              categories.when(
                data: (list) => DropdownButtonFormField<ExpenseCategory>(
                  initialValue: _selectedCategory,
                  hint: const Text('Category'),
                  items: list
                      .map((c) => DropdownMenuItem(
                          value: c, child: Text(c.name)))
                      .toList(),
                  onChanged: (c) => setState(() => _selectedCategory = c),
                  validator: (v) => v == null ? 'Select a category' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, st) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _amountCtrl,
                label: 'Amount (ETB)',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.attach_money),
                textInputAction: TextInputAction.next,
                autofocus: true,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Amount is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _descCtrl,
                label: 'Description (optional)',
                prefixIcon: const Icon(Icons.notes_outlined),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),
              // Date picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined,
                    color: AppColors.primary),
                title: Text(_formatDate(_date), style: AppTextStyles.body),
                subtitle: Text('Tap to change date',
                    style: AppTextStyles.bodySmall),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Record Expense',
                loading: loading,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['January','February','March','April','May','June',
        'July','August','September','October','November','December'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
