import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/services/image_picker_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../providers/transaction_providers.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  CategoryEntity? _selectedCategory;
  String? _selectedPaymentMethod = 'cash'; // Defaults to Cash
  String _selectedWallet = 'Personal Wallet'; // Default Wallet
  String? _receiptPath; // Image Picker path
  
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedCategory = null; // Reset category when switching tabs
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryEmerald,
              onPrimary: Colors.white,
              onSurface: AppTheme.textInk,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickReceipt(ImageSource source) async {
    final picker = ref.read(imagePickerServiceProvider);
    final path = await picker.pickImage(source);
    if (path != null) {
      setState(() {
        _receiptPath = path;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authStateProvider).user;
    if (user == null) return;

    final type = _tabController.index == 0 ? 'expense' : 'income';
    final amountVal = double.parse(_amountController.text.trim());
    final amountInMinor = (amountVal * 100).round(); // Convert to paise

    // Validation for category
    if (type == 'expense' && _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category for this expense'),
          backgroundColor: AppTheme.expenseAlert,
        ),
      );
      return;
    }

    // Default category for Income if not specified
    CategoryEntity? finalCategory = _selectedCategory;
    if (type == 'income' && finalCategory == null) {
      final categoriesAsync = ref.read(categoriesProvider('income'));
      categoriesAsync.whenData((list) {
        finalCategory = list.firstWhere(
          (c) => c.name.toLowerCase().contains('other'),
          orElse: () => list.first,
        );
      });
    }

    final noteText = _noteController.text.trim();
    final finalNote = noteText.isEmpty 
        ? '[$_selectedWallet]' 
        : '[$_selectedWallet] $noteText';

    final newTransaction = TransactionEntity(
      id: const Uuid().v4(),
      userId: user.id,
      type: type,
      amount: amountInMinor,
      categoryId: finalCategory?.id ?? '',
      paymentMethod: _selectedPaymentMethod,
      note: finalNote,
      receiptUrl: _receiptPath,
      transactionDate: _selectedDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(transactionRepositoryProvider).addTransaction(newTransaction);
      ref.read(transactionUpdateTriggerProvider.notifier).triggerUpdate();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type == 'expense' ? 'Expense' : 'Income'} added successfully'),
            backgroundColor: AppTheme.primaryEmerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save transaction: $e'),
            backgroundColor: AppTheme.expenseAlert,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 8,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bottom sheet drag handle
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                'Add Transaction',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Tab Selector (Expense / Income)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: _tabController.index == 0 ? AppTheme.expenseAlert : AppTheme.primaryEmerald,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark ? Colors.grey.shade400 : AppTheme.textSlate,
                  tabs: const [
                    Tab(text: 'Expense'),
                    Tab(text: 'Income'),
                  ],
                  onTap: (_) => setState(() {}),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                ),
              ),
              const SizedBox(height: 24),

              // Amount Input Field
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  prefixStyle: theme.textTheme.displayMedium?.copyWith(
                    fontSize: 24,
                    color: _tabController.index == 0 ? AppTheme.expenseAlert : AppTheme.primaryEmerald,
                  ),
                  hintText: '0.00',
                  hintStyle: const TextStyle(fontSize: 24),
                ),
                style: theme.textTheme.displayMedium?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _tabController.index == 0 ? AppTheme.expenseAlert : AppTheme.primaryEmerald,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: Validators.validateAmount,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),

              // Categories Grid title
              Text(
                'Select Category',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              // Category Selector
              _buildCategorySelector(),
              const SizedBox(height: 20),

              // Quick fields
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_month, color: AppTheme.primaryEmerald),
                      label: Text(
                        Formatters.formatDateShort(_selectedDate),
                        style: const TextStyle(fontSize: 14, color: AppTheme.textInk),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showAdvanced = !_showAdvanced;
                        });
                      },
                      icon: Icon(
                        _showAdvanced ? Icons.expand_less : Icons.expand_more,
                        color: AppTheme.primaryEmerald,
                      ),
                      label: const Text(
                        'Details',
                        style: TextStyle(fontSize: 14, color: AppTheme.textInk),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Collapsible Advanced section
              if (_showAdvanced) ...[
                // Wallet Selector Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedWallet,
                  decoration: const InputDecoration(
                    labelText: 'Wallet',
                    prefixIcon: Icon(Icons.wallet),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Personal Wallet', child: Text('Personal Wallet')),
                    DropdownMenuItem(value: 'Savings Wallet', child: Text('Savings Wallet')),
                    DropdownMenuItem(value: 'Business Wallet', child: Text('Business Wallet')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedWallet = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Note Input
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  maxLength: 140,
                  decoration: const InputDecoration(
                    labelText: 'Add Note',
                    hintText: 'Enter description (optional)',
                    prefixIcon: Icon(Icons.edit_note),
                  ),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 16),

                // Payment Method Selector
                Text(
                  'Payment Method',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPaymentMethodButton('cash', Icons.money, 'Cash'),
                    _buildPaymentMethodButton('card', Icons.credit_card, 'Card'),
                    _buildPaymentMethodButton('upi', Icons.mobile_screen_share, 'UPI'),
                    _buildPaymentMethodButton('bank_transfer', Icons.account_balance, 'Bank'),
                  ],
                ),
                const SizedBox(height: 20),

                // Receipt Attachment
                const Text(
                  'Receipt Attachment',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_receiptPath != null) ...[
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_receiptPath!),
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      IconButton(
                        icon: const CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                        onPressed: () {
                          setState(() {
                            _receiptPath = null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickReceipt(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt, color: AppTheme.primaryEmerald),
                          label: const Text('Camera', style: TextStyle(color: AppTheme.textInk)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickReceipt(ImageSource.gallery),
                          icon: const Icon(Icons.photo, color: AppTheme.primaryEmerald),
                          label: const Text('Gallery', style: TextStyle(color: AppTheme.textInk)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ],

              // CTA Action Button
              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _tabController.index == 0 ? AppTheme.expenseAlert : AppTheme.primaryEmerald,
                ),
                child: const Text('Save Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final type = _tabController.index == 0 ? 'expense' : 'income';
    final categoriesAsync = ref.watch(categoriesProvider(type));

    return categoriesAsync.when(
      data: (categoriesList) {
        if (categoriesList.isEmpty) {
          return const Center(child: Text('No categories available. Please add in Settings.'));
        }

        return SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categoriesList.length,
            itemBuilder: (context, index) {
              final cat = categoriesList[index];
              final isSelected = _selectedCategory?.id == cat.id;
              final color = Color(int.parse(cat.colorHex));

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                  });
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? color.withValues(alpha: 0.15) 
                        : Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey.shade900 
                            : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? color : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: color.withValues(alpha: 0.2),
                        child: Icon(
                          CategoryIcons.getIcon(cat.icon),
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => SizedBox(
        height: 100,
        child: Center(child: Text('Error loading categories: $err')),
      ),
    );
  }

  Widget _buildPaymentMethodButton(String method, IconData icon, String label) {
    final isSelected = _selectedPaymentMethod == method;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryLight
                : theme.brightness == Brightness.dark
                    ? Colors.grey.shade900
                    : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryEmerald : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? AppTheme.primaryDark : theme.iconTheme.color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryDark : theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
