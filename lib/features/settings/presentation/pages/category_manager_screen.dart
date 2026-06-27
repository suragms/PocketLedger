import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../transactions/domain/entities/category_entity.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

class CategoryManagerScreen extends ConsumerStatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  ConsumerState<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends ConsumerState<CategoryManagerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddCategoryDialog(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddCategorySheet(type: type),
    );
  }

  Future<void> _archiveCategory(CategoryEntity cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Category'),
        content: Text('Are you sure you want to delete the "${cat.name}" category? Historical transactions using it will still preserve it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.expenseAlert),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(transactionRepositoryProvider).deleteCategory(cat.id);
      ref.read(transactionUpdateTriggerProvider.notifier).triggerUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Manager'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryEmerald,
          labelColor: AppTheme.primaryEmerald,
          unselectedLabelColor: isDark ? Colors.grey.shade400 : AppTheme.textSlate,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList('expense'),
          _buildCategoryList('income'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _openAddCategoryDialog(context, _tabController.index == 0 ? 'expense' : 'income');
        },
        tooltip: 'Add Category',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(String type) {
    final categoriesAsync = ref.watch(categoriesProvider(type));

    return categoriesAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return const Center(child: Text('No categories configured.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: list.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final cat = list[index];
            final color = Color(int.parse(cat.colorHex));

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(
                  CategoryIcons.getIcon(cat.icon),
                  color: color,
                  size: 20,
                ),
              ),
              title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                cat.isDefault ? 'System Default' : 'Custom Category',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: cat.isDefault
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.archive_outlined, color: AppTheme.expenseAlert),
                      tooltip: 'Archive category',
                      onPressed: () => _archiveCategory(cat),
                    ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}

class AddCategorySheet extends ConsumerStatefulWidget {
  final String type;

  const AddCategorySheet({
    super.key,
    required this.type,
  });

  @override
  ConsumerState<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends ConsumerState<AddCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  String _selectedIcon = 'category';
  String _selectedColor = '0xff0e9f6e'; // Default Emerald

  final List<String> _availableColors = [
    '0xff0e9f6e', // Emerald
    '0xff3498db', // Blue
    '0xffe74c3c', // Red
    '0xfff1c40f', // Yellow
    '0xff9b59b6', // Purple
    '0xffe67e22', // Orange
    '0xff1abc9c', // Teal
    '0xff7f8c8d', // Grey
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authStateProvider).user;
    if (user == null) return;

    final newCategory = CategoryEntity(
      id: const Uuid().v4(),
      userId: user.id,
      name: _nameController.text.trim(),
      type: widget.type,
      icon: _selectedIcon,
      colorHex: _selectedColor,
      isDefault: false,
      isArchived: false,
      sortOrder: 50, // Custom categories sorted down
    );

    try {
      await ref.read(transactionRepositoryProvider).addCategory(newCategory);
      ref.read(transactionUpdateTriggerProvider.notifier).triggerUpdate();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category created successfully'),
            backgroundColor: AppTheme.primaryEmerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save category: $e'),
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
    final availableIcons = CategoryIcons.getAvailableIcons();

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
              // Drag Handle
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

              Text(
                'Add Category (${widget.type.toUpperCase()})',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Category Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),

              // Color Selector
              const Text('Select Theme Color', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableColors.length,
                  itemBuilder: (context, index) {
                    final colorStr = _availableColors[index];
                    final color = Color(int.parse(colorStr));
                    final isSelected = _selectedColor == colorStr;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = colorStr;
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: isDark ? Colors.white : Colors.black, width: 3)
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Icon Grid Selector
              const Text('Select Icon', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: availableIcons.length,
                  itemBuilder: (context, index) {
                    final iconKey = availableIcons[index];
                    final isSelected = _selectedIcon == iconKey;
                    final activeColor = Color(int.parse(_selectedColor));

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIcon = iconKey;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? activeColor.withValues(alpha: 0.15) 
                              : isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? activeColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          CategoryIcons.getIcon(iconKey),
                          color: isSelected ? activeColor : theme.iconTheme.color,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Save Category Button
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Create Category'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
