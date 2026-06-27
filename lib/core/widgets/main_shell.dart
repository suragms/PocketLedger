import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/transactions/presentation/widgets/add_transaction_sheet.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  void _onTabTapped(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddTransactionSheet(),
          );
        },
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        clipBehavior: Clip.antiAlias,
        elevation: 8,
        padding: EdgeInsets.zero,
        height: 64,
        color: theme.brightness == Brightness.dark
            ? theme.colorScheme.surface
            : Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Dashboard
            _buildNavItem(
              context: context,
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard,
              label: 'Dashboard',
              index: 0,
              currentIndex: currentIndex,
            ),
            // History
            _buildNavItem(
              context: context,
              icon: Icons.history,
              activeIcon: Icons.history_toggle_off,
              label: 'History',
              index: 1,
              currentIndex: currentIndex,
            ),
            // Spacing for FAB
            const SizedBox(width: 48),
            // Reports
            _buildNavItem(
              context: context,
              icon: Icons.bar_chart_outlined,
              activeIcon: Icons.bar_chart,
              label: 'Reports',
              index: 2,
              currentIndex: currentIndex,
            ),
            // Settings
            _buildNavItem(
              context: context,
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
              label: 'Settings',
              index: 3,
              currentIndex: currentIndex,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required int currentIndex,
  }) {
    final theme = Theme.of(context);
    final isActive = index == currentIndex;
    final color = isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return InkWell(
      onTap: () => _onTabTapped(context, index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
