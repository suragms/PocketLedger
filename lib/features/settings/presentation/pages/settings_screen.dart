import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/secure_storage_provider.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../main.dart'; // Notification provider
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/entities/category_entity.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricHardwareAvailable = false;
  bool _pinLockEnabled = false;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricHardware();
    _checkPinState();
    _checkNotificationState();
  }

  Future<void> _checkBiometricHardware() async {
    final localAuth = LocalAuthentication();
    try {
      final isSupported = await localAuth.isDeviceSupported();
      final canCheck = await localAuth.canCheckBiometrics;
      setState(() {
        _biometricHardwareAvailable = isSupported && canCheck;
      });
    } catch (_) {}
  }

  Future<void> _checkPinState() async {
    final pin = await ref.read(secureStorageProvider).getPin();
    setState(() {
      _pinLockEnabled = pin != null;
    });
  }

  Future<void> _checkNotificationState() async {
    // Check if daily reminder was scheduled or active
    // Simulating active reminder state (defaulting to false)
    setState(() {
      _notificationsEnabled = false;
    });
  }

  Future<void> _toggleBiometrics(bool value) async {
    final localAuth = LocalAuthentication();
    if (value) {
      try {
        final didAuthenticate = await localAuth.authenticate(
          localizedReason: 'Please authenticate to enable biometric unlock',
          options: const AuthenticationOptions(stickyAuth: true),
        );
        if (didAuthenticate) {
          await ref.read(authStateProvider.notifier).updatePreferences(biometricEnabled: true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: $e'), backgroundColor: AppTheme.expenseAlert),
          );
        }
      }
    } else {
      await ref.read(authStateProvider.notifier).updatePreferences(biometricEnabled: false);
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final notificationService = ref.read(notificationServiceProvider);
    if (value) {
      // Schedule daily reminder at 8:00 PM (20:00)
      await notificationService.scheduleDailyReminder(id: 1, hour: 20, minute: 0);
    } else {
      await notificationService.cancelAll();
    }
    setState(() {
      _notificationsEnabled = value;
    });
  }

  Future<void> _setupPin() async {
    final storage = ref.read(secureStorageProvider);
    final controller = TextEditingController();

    if (_pinLockEnabled) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disable PIN Lock'),
          content: const Text('Are you sure you want to disable PIN lock?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await storage.deletePin();
                await _checkPinState();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Disable'),
            ),
          ],
        ),
      );
    } else {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Set 4-Digit PIN'),
          content: TextField(
            controller: controller,
            maxLength: 4,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Enter PIN',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final pin = controller.text.trim();
                if (pin.length == 4) {
                  await storage.savePin(pin);
                  await _checkPinState();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Save PIN'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _backupData() async {
    final repo = ref.read(transactionRepositoryProvider);
    final user = ref.read(authStateProvider).user;
    if (user == null) return;

    try {
      final txs = await repo.getTransactions(userId: user.id);
      final cats = await repo.getCategories(userId: user.id);

      final Map<String, dynamic> backup = {
        'version': 1,
        'user_id': user.id,
        'categories': cats.map((c) => {
          'id': c.id,
          'name': c.name,
          'type': c.type,
          'icon': c.icon,
          'color_hex': c.colorHex,
          'is_default': c.isDefault,
          'sort_order': c.sortOrder,
        }).toList(),
        'transactions': txs.map((t) => {
          'id': t.id,
          'type': t.type,
          'amount': t.amount,
          'category_id': t.categoryId,
          'payment_method': t.paymentMethod,
          'note': t.note,
          'receipt_url': t.receiptUrl,
          'date': t.transactionDate.toIso8601String(),
        }).toList(),
      };

      final jsonStr = jsonEncode(backup);
      await Clipboard.setData(ClipboardData(text: jsonStr));

      final folder = await getApplicationDocumentsDirectory();
      final file = File('${folder.path}/pocket_ledger_backup.json');
      await file.writeAsString(jsonStr);

      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Backup Successful'),
            content: Text('Backup data copied to clipboard and saved to:\n${file.path}'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e'), backgroundColor: AppTheme.expenseAlert),
        );
      }
    }
  }

  Future<void> _restoreData() async {
    final user = ref.read(authStateProvider).user;
    if (user == null) return;

    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Paste the JSON backup string below:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '{"version": 1, ...}',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final jsonStr = controller.text.trim();
              if (jsonStr.isEmpty) return;

              try {
                final Map<String, dynamic> backup = jsonDecode(jsonStr);
                final repo = ref.read(transactionRepositoryProvider);

                // Insert Categories
                final List<dynamic> cats = backup['categories'] ?? [];
                for (var c in cats) {
                  final cat = CategoryEntity(
                    id: c['id'],
                    userId: user.id,
                    name: c['name'],
                    type: c['type'],
                    icon: c['icon'],
                    colorHex: c['color_hex'],
                    isDefault: c['is_default'] ?? false,
                    isArchived: false,
                    sortOrder: c['sort_order'] ?? 0,
                  );
                  try {
                    await repo.addCategory(cat);
                  } catch (_) {
                    await repo.updateCategory(cat);
                  }
                }

                // Insert Transactions
                final List<dynamic> txs = backup['transactions'] ?? [];
                for (var t in txs) {
                  final tx = TransactionEntity(
                    id: t['id'],
                    userId: user.id,
                    type: t['type'],
                    amount: t['amount'],
                    categoryId: t['category_id'],
                    paymentMethod: t['payment_method'],
                    note: t['note'],
                    receiptUrl: t['receipt_url'],
                    transactionDate: DateTime.parse(t['date']),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  try {
                    await repo.addTransaction(tx);
                  } catch (_) {}
                }

                ref.read(transactionUpdateTriggerProvider.notifier).triggerUpdate();

                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data restored successfully!'),
                      backgroundColor: AppTheme.primaryEmerald,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Restore failed: $e'), backgroundColor: AppTheme.expenseAlert),
                  );
                }
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final user = ref.read(authStateProvider).user;
    if (user == null) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account', style: TextStyle(color: AppTheme.expenseAlert)),
        content: const Text(
          'WARNING: This will permanently delete your account and all transaction records. This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.expenseAlert),
            onPressed: () async {
              try {
                final db = ref.read(databaseProvider);
                await (db.delete(db.users)..where((t) => t.id.equals(user.id))).go();
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (_) {}
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Theme available via context if needed
    final userState = ref.watch(authStateProvider);
    final user = userState.user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('No user profile found.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // User profile card
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primaryLight,
                child: Icon(Icons.person, color: AppTheme.primaryDark, size: 28),
              ),
              title: Text(
                user.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(user.email, style: const TextStyle(color: AppTheme.textSlate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/profile'),
            ),
          ),
          const SizedBox(height: 20),

          // Preferences section
          _buildSectionHeader('Preferences'),
          Card(
            child: Column(
              children: [
                // Currency dropdown
                ListTile(
                  leading: const Icon(Icons.monetization_on_outlined, color: AppTheme.primaryEmerald),
                  title: const Text('Default Currency'),
                  trailing: DropdownButton<String>(
                    value: user.currencyCode,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 'INR', child: Text('INR (₹)')),
                      DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                      DropdownMenuItem(value: 'GBP', child: Text('GBP (£)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(authStateProvider.notifier).updatePreferences(currencyCode: val);
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                // Theme toggle
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined, color: AppTheme.primaryEmerald),
                  title: const Text('Theme'),
                  trailing: DropdownButton<String>(
                    value: user.themePreference,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 'system', child: Text('System')),
                      DropdownMenuItem(value: 'light', child: Text('Light')),
                      DropdownMenuItem(value: 'dark', child: Text('Dark')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(authStateProvider.notifier).updatePreferences(themePreference: val);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Security Section
          _buildSectionHeader('Security & App Lock'),
          Card(
            child: Column(
              children: [
                if (_biometricHardwareAvailable) ...[
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint, color: AppTheme.primaryEmerald),
                    title: const Text('Biometric Unlock'),
                    subtitle: const Text('Use Face ID / Fingerprint on launch'),
                    value: user.biometricEnabled,
                    activeThumbColor: AppTheme.primaryEmerald,
                    onChanged: _toggleBiometrics,
                  ),
                  const Divider(height: 1),
                ],
                ListTile(
                  leading: const Icon(Icons.pin_outlined, color: AppTheme.primaryEmerald),
                  title: const Text('PIN Code Lock'),
                  subtitle: Text(_pinLockEnabled ? 'Active' : 'Disabled'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _setupPin,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications_active_outlined, color: AppTheme.primaryEmerald),
              title: const Text('Daily Reminder Alerts'),
              subtitle: const Text('Reminds you daily to log expenditures'),
              value: _notificationsEnabled,
              activeThumbColor: AppTheme.primaryEmerald,
              onChanged: _toggleNotifications,
            ),
          ),
          const SizedBox(height: 20),

          // Categories section
          _buildSectionHeader('Categories'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.category_outlined, color: AppTheme.primaryEmerald),
              title: const Text('Category Manager'),
              subtitle: const Text('Add, edit, or archive categories'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/categories'),
            ),
          ),
          const SizedBox(height: 20),

          // Backup & Restore section
          _buildSectionHeader('Backup & Migration'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined, color: AppTheme.primaryEmerald),
                  title: const Text('Backup Ledger Data'),
                  subtitle: const Text('Export JSON to copy & save locally'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _backupData,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined, color: AppTheme.primaryEmerald),
                  title: const Text('Restore Ledger Data'),
                  subtitle: const Text('Paste JSON backup file to overwrite'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _restoreData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // About section
          _buildSectionHeader('Info'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: AppTheme.primaryEmerald),
              title: const Text('About & Legal'),
              subtitle: const Text('App version, terms, copyright'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/about'),
            ),
          ),
          const SizedBox(height: 32),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(authStateProvider.notifier).logout();
              },
              icon: const Icon(Icons.logout, color: AppTheme.expenseAlert),
              label: const Text('Log Out', style: TextStyle(color: AppTheme.expenseAlert)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.expenseAlert),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Delete Account Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextButton.icon(
              onPressed: _deleteAccount,
              icon: const Icon(Icons.delete_forever, color: AppTheme.expenseAlert),
              label: const Text('Delete Account Permanently', style: TextStyle(color: AppTheme.expenseAlert)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSlate,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
