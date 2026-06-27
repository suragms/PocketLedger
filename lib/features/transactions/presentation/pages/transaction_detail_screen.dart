import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../providers/transaction_providers.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  ConsumerState<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends ConsumerState<TransactionDetailScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? _selectedDate;
  CategoryEntity? _selectedCategory;
  String? _selectedPaymentMethod;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _initializeEditingFields(TransactionEntity transaction) {
    _amountController.text = (transaction.amount / 100.0).toStringAsFixed(2);
    _noteController.text = transaction.note ?? '';
    _selectedDate = transaction.transactionDate;
    _selectedCategory = transaction.category;
    _selectedPaymentMethod = transaction.paymentMethod;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _deleteTransaction() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this transaction? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.expenseAlert),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref.read(transactionRepositoryProvider).deleteTransaction(widget.transactionId);
        ref.read(transactionUpdateTriggerProvider.notifier).triggerUpdate();
        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction deleted successfully'),
              backgroundColor: AppTheme.primaryEmerald,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: AppTheme.expenseAlert,
            ),
          );
        }
      }
    }
  }

  Future<void> _updateTransaction(TransactionEntity original) async {
    if (!_formKey.currentState!.validate()) return;

    final amountVal = double.parse(_amountController.text.trim());
    final amountInMinor = (amountVal * 100).round();

    final updated = original.copyWith(
      amount: amountInMinor,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      transactionDate: _selectedDate,
      categoryId: _selectedCategory?.id,
      category: _selectedCategory,
      paymentMethod: _selectedPaymentMethod,
    );

    try {
      await ref.read(transactionRepositoryProvider).updateTransaction(updated);
      ref.read(transactionUpdateTriggerProvider.notifier).triggerUpdate();
      
      setState(() {
        _isEditing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction updated successfully'),
            backgroundColor: AppTheme.primaryEmerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            backgroundColor: AppTheme.expenseAlert,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionAsync = ref.watch(singleTransactionProvider(widget.transactionId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Transaction Details'),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                transactionAsync.whenData((tx) {
                  if (tx != null) {
                    setState(() {
                      _initializeEditingFields(tx);
                      _isEditing = true;
                    });
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.expenseAlert),
              onPressed: _deleteTransaction,
            ),
          ]
        ],
      ),
      body: transactionAsync.when(
        data: (transaction) {
          if (transaction == null) {
            return const Center(child: Text('Transaction not found.'));
          }

          return _isEditing 
              ? _buildEditForm(theme, transaction) 
              : _buildDetailsView(theme, transaction);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading details: $err')),
      ),
    );
  }

  Widget _buildDetailsView(ThemeData theme, TransactionEntity tx) {
    final isExpense = tx.type == 'expense';
    final amountColor = isExpense ? AppTheme.expenseAlert : AppTheme.primaryEmerald;
    final catColor = tx.category != null ? Color(int.parse(tx.category!.colorHex)) : Colors.grey;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Visual category header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: catColor.withValues(alpha: 0.15),
                  child: Icon(
                    CategoryIcons.getIcon(tx.category?.icon ?? 'category'),
                    color: catColor,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  tx.category?.name ?? 'Uncategorized',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tx.type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 16),
                // Hero numeric amount
                Text(
                  Formatters.formatCurrency(tx.amount, 'INR', showSign: true),
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Details List
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDetailRow(
                    Icons.calendar_today_outlined, 
                    'Date', 
                    Formatters.formatDateHeader(tx.transactionDate),
                  ),
                  const Divider(),
                  _buildDetailRow(
                    Icons.payment_outlined, 
                    'Payment Method', 
                    tx.paymentMethod != null ? tx.paymentMethod!.toUpperCase() : 'None',
                  ),
                  if (tx.note != null) ...[
                    const Divider(),
                    _buildDetailRow(
                      Icons.description_outlined, 
                      'Note', 
                      tx.note!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(ThemeData theme, TransactionEntity original) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount Edit
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.validateAmount,
            ),
            const SizedBox(height: 16),

            // Date Pick
            OutlinedButton.icon(
              onPressed: () => _selectDate(context),
              icon: const Icon(Icons.calendar_month, color: AppTheme.primaryEmerald),
              label: Text(
                _selectedDate != null ? Formatters.formatDateShort(_selectedDate!) : 'Select Date',
                style: const TextStyle(color: AppTheme.textInk),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Payment Method Select
            DropdownButtonFormField<String>(
              initialValue: _selectedPaymentMethod,
              decoration: const InputDecoration(labelText: 'Payment Method'),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'card', child: Text('Card')),
                DropdownMenuItem(value: 'upi', child: Text('UPI')),
                DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedPaymentMethod = val;
                });
              },
            ),
            const SizedBox(height: 16),

            // Note Edit
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              maxLength: 140,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
            const SizedBox(height: 32),

            // CTA Buttons Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateTransaction(original),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.textSlate, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.textSlate, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textInk),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
