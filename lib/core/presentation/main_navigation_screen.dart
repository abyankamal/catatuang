import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class MainNavigationScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationScreen({
    super.key,
    required this.navigationShell,
  });

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    final items = [
      _NavItem(icon: Icons.grid_view_rounded, label: 'Beranda'),
      _NavItem(icon: Icons.receipt_long_outlined, label: 'Riwayat'),
      _NavItem(icon: Icons.bar_chart_rounded, label: 'Statistik'),
      _NavItem(icon: Icons.track_changes_rounded, label: 'Target'),
    ];

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        child: Center(
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = index == currentIndex;

                  return InkWell(
                    onTap: () => _onDestinationSelected(index),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              item.icon,
                              size: 20,
                              color: isSelected ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              color: isSelected ? AppColors.primary : Colors.grey.shade600,
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  _NavItem({required this.icon, required this.label});
}
