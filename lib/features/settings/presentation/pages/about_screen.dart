import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('About PocketLedger'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Logo and version info
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      size: 64,
                      color: AppTheme.primaryEmerald,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PocketLedger',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(color: AppTheme.textSlate, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Developer Info Section
            Text(
              'Developer Info',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Developed by Surag (Surag Sunil / Surag M S)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'HexaStack Solutions',
                      style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    _buildLinkRow(Icons.language, 'Portfolio', 'surag-portfolio.web.app'),
                    _buildLinkRow(Icons.code, 'GitHub', 'github.com/suragms'),
                    _buildLinkRow(Icons.link, 'Linktree', 'linktr.ee/suragdevstudio'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Legal & Terms Section
            Text(
              'Legal & Privacy',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy Policy Summary',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'PocketLedger is an offline-first app. Your transactions are stored directly on your physical device. No financial data is sent to external servers unless synchronizations are explicitly configured.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSlate),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Terms of Service',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'PocketLedger is provided "as is". The developers are not liable for any financial tracking errors or discrepancies. Always verify reports manually for tax or accounting purposes.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSlate),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Copyright attribution
            Center(
              child: Column(
                children: [
                  const Text(
                    '© 2026 HexaStack Solutions. All rights reserved.',
                    style: TextStyle(color: AppTheme.textSlate, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Developed by Surag with HexaStack AI.',
                    style: TextStyle(color: AppTheme.textSlate.withValues(alpha: 0.8), fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkRow(IconData icon, String site, String path) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSlate),
          const SizedBox(width: 12),
          Text('$site: ', style: const TextStyle(fontSize: 13)),
          Expanded(
            child: Text(
              path,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.primaryEmerald,
                decoration: TextDecoration.underline,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
