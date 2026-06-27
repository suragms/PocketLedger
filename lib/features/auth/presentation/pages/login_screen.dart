import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/database/secure_storage_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _loadSavedEmail();
  }

  Future<void> _checkBiometrics() async {
    final auth = LocalAuthentication();
    try {
      final isSupported = await auth.isDeviceSupported();
      final canCheck = await auth.canCheckBiometrics;
      final storage = ref.read(secureStorageProvider);
      final isEnabled = await storage.isBiometricEnabled();
      
      setState(() {
        _canCheckBiometrics = isSupported && canCheck && isEnabled;
      });
      
      if (_canCheckBiometrics) {
        // Auto trigger biometrics
        await _authenticateWithBiometrics();
      }
    } catch (_) {}
  }

  Future<void> _loadSavedEmail() async {
    final storage = ref.read(secureStorageProvider);
    final savedEmail = await storage.getUserEmail();
    if (savedEmail != null) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final localAuth = LocalAuthentication();
    try {
      final didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Please authenticate to unlock PocketLedger',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate && mounted) {
        final storage = ref.read(secureStorageProvider);
        final token = await storage.getToken();
        if (token != null) {
          // Trigger biometric login simulation
          final email = await storage.getUserEmail();
          // We bypass full form validation here because biometrics passed
          if (email != null) {
            // Retrieve current mock user
            final user = await ref.read(authRepositoryProvider).getCurrentUser();
            if (user != null) {
              // Update state to authenticated
              ref.read(authStateProvider.notifier).setAuthenticated(user);
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Save email if Remember Me checked
    final storage = ref.read(secureStorageProvider);
    if (_rememberMe) {
      await storage.saveUserEmail(email);
    } else {
      // Don't clear, keep historical email or just empty if preferred
    }

    await ref.read(authStateProvider.notifier).login(email, password);

    final authState = ref.read(authStateProvider);
    if (authState.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.errorMessage!),
          backgroundColor: AppTheme.expenseAlert,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Header
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          size: 48,
                          color: AppTheme.primaryEmerald,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'PocketLedger',
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : AppTheme.primaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track your daily income and expenses.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                      hintText: 'name@example.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 8),

                  // Remember Me & Forgot Password Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (val) {
                              setState(() {
                                _rememberMe = val ?? false;
                              });
                            },
                          ),
                          const Text('Remember Me'),
                        ],
                      ),
                      TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: const Text('Forgot Password?'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Login Button / Indicator
                  if (authState.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Log In'),
                    ),

                  const SizedBox(height: 16),

                  // Biometrics option
                  if (_canCheckBiometrics && !authState.isLoading)
                    OutlinedButton.icon(
                      onPressed: _authenticateWithBiometrics,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Unlock with Biometrics'),
                    ),

                  const SizedBox(height: 24),

                  // Sign up footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: const Text('Register'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
