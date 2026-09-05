import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Bottom nav merah dengan lekukan (notch) di tengah untuk tombol scan
/// mengambang — sesuai desain Figma "dashboard".
///
/// Dipakai bersama [FloatingActionButtonLocation.centerDocked] di Scaffold.
class AppBottomNav extends StatelessWidget {
  final int currentIndex; // 0..3
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.red,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 12,
      padding: EdgeInsets.zero,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
          _NavIcon(
            icon: Icons.shopping_bag_outlined,
            activeIcon: Icons.shopping_bag_rounded,
            selected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavIcon(
            icon: Icons.add_business_outlined,
            activeIcon: Icons.add_business_rounded,
            selected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          const SizedBox(width: 56), // ruang untuk notch + FAB
          _NavIcon(
            icon: Icons.contact_page_outlined,
            activeIcon: Icons.contact_page_rounded,
            selected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavIcon(
            icon: Icons.insert_chart_outlined_rounded,
            activeIcon: Icons.insert_chart_rounded,
            selected: currentIndex == 3,
            onTap: () => onTap(3),
          ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      splashRadius: 24,
      icon: Icon(
        selected ? activeIcon : icon,
        color: Colors.white.withValues(alpha: selected ? 1 : .70),
        size: 26,
      ),
    );
  }
}

/// Tombol scan bundar mengambang di tengah notch.
class ScanFab extends StatelessWidget {
  final VoidCallback onPressed;
  const ScanFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      width: 62,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: AppColors.redBright,
        foregroundColor: Colors.white,
        elevation: 6,
        highlightElevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner_rounded, size: 28),
      ),
    );
  }
}
