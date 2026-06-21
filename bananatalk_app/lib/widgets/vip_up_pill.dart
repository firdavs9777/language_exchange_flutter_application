import 'package:flutter/material.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

/// Gold gradient "VIP" pill with a small red "Up" badge — the standard
/// entry-point CTA for the upgrade flow used across the top-level app
/// bars (chat list, community, AI study).
///
/// Tap pushes [VipPlansScreen]. The pill is compact enough to sit alongside
/// other AppBar actions or as part of a `leading` row.
class VipUpPill extends StatelessWidget {
  const VipUpPill({super.key, this.onTap, this.onLight = true});

  /// Override tap behavior. When null the pill pushes [VipPlansScreen]
  /// onto the root navigator.
  final VoidCallback? onTap;

  /// True when placed on a light surface (most app bars). On a dark/colored
  /// surface (e.g. the AI Study purple gradient header) the "Up" badge's
  /// outline needs to match the surface so it cuts cleanly.
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = Theme.of(context).colorScheme.surface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ??
              () => Navigator.push(
                    context,
                    AppPageRoute(builder: (_) => const VipPlansScreen()),
                  ),
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFA000).withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'VIP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Positioned(
                top: -6,
                right: -8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: onLight ? scaffoldBg : Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: const Text(
                    'Up',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
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
