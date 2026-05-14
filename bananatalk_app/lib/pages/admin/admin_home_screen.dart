import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/pages/reports/admin_reports_screen.dart';
import 'package:bananatalk_app/pages/admin/admin_users_screen.dart';
import 'package:bananatalk_app/pages/admin/admin_audit_log_screen.dart';
import 'package:bananatalk_app/pages/admin/admin_analytics_screen.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Step 15 — landing screen for the admin toolset. Replaces the
/// previous direct-to-reports entry on the profile menu and drawer.
/// 2-column grid of tiles, each tile routes to one of the admin
/// surfaces (Reports / Users / Audit Log).
///
/// The grid is the consolidation point for future admin tools
/// (dashboard counters, live voice room moderation, content browse)
/// — adding a new tile is the only change required for a new surface.
class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Client-side defense-in-depth role gate. Backend authorize('admin')
    // on every /api/v1/admin/* request is the actual security boundary.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = ref.read(userProvider).valueOrNull;
      if (user?.isAdmin != true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const _NotAuthorizedScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Tools')),
      body: SafeArea(
        child: Padding(
          padding: Spacing.paddingLG,
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: Spacing.md,
            crossAxisSpacing: Spacing.md,
            childAspectRatio: 1.1,
            children: [
              _AdminTile(
                icon: Icons.flag_outlined,
                label: 'Reports',
                subtitle: 'Review user reports',
                color: AppColors.error,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminReportsScreen(),
                  ),
                ),
              ),
              _AdminTile(
                icon: Icons.people_outline,
                label: 'Users',
                subtitle: 'Search · ban · roles',
                color: AppColors.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                ),
              ),
              _AdminTile(
                icon: Icons.history_outlined,
                label: 'Audit Log',
                subtitle: 'Moderator actions',
                color: const Color(0xFF607D8B),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminAuditLogScreen(),
                  ),
                ),
              ),
              _AdminTile(
                icon: Icons.insights_outlined,
                label: 'Analytics',
                subtitle: 'Counts · breakdowns',
                color: const Color(0xFF009688),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminAnalyticsScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _AdminTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotAuthorizedScreen extends StatelessWidget {
  const _NotAuthorizedScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, size: 56, color: Colors.black45),
              SizedBox(height: 16),
              Text(
                "This page isn't available.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
