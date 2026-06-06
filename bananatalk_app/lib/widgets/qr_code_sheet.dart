// lib/widgets/qr_code_sheet.dart
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// Bottom sheet with two tabs:
///   - My Code: shows the current user's QR code
///   - Scan: opens camera to scan another user's code
class QrCodeSheet extends StatefulWidget {
  final String userId;
  final String userName;
  final String? avatarUrl;

  /// Called when a valid `bananatalk://user/<id>` is scanned.
  /// The sheet is already popped before this is invoked.
  final void Function(String scannedUserId) onUserScanned;

  const QrCodeSheet({
    super.key,
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.onUserScanned,
  });

  @override
  State<QrCodeSheet> createState() => _QrCodeSheetState();
}

class _QrCodeSheetState extends State<QrCodeSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _navigating = false;

  String get _qrData => 'bananatalk://user/${widget.userId}';

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

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_navigating) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;

      if (raw.startsWith('bananatalk://user/')) {
        final scannedId = raw.substring('bananatalk://user/'.length).trim();
        if (scannedId.isEmpty) continue;

        _navigating = true;
        // Pop the sheet first, then invoke the callback
        Navigator.of(context).pop();
        widget.onUserScanned(scannedId);
        return;
      }
    }

    // Nothing valid found — show snackbar once per scan attempt
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invalid QR code'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareQrLink() {
    SharePlus.instance.share(
      ShareParams(
        text: 'Add me on Bananatalk! $_qrData',
        subject: 'Connect with ${widget.userName} on Bananatalk',
      ),
    );
  }

  void _copyQrLink() {
    Clipboard.setData(ClipboardData(text: _qrData));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: context.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'My Code'),
              Tab(text: 'Scan'),
            ],
          ),

          // Tab views — fixed height so the sheet has a stable size
          SizedBox(
            height: 420,
            child: TabBarView(
              controller: _tabController,
              children: [
                _MyCodeTab(
                  qrData: _qrData,
                  userName: widget.userName,
                  avatarUrl: widget.avatarUrl,
                  onShare: _shareQrLink,
                  onCopy: _copyQrLink,
                ),
                _ScanTab(onDetect: _onBarcodeDetected),
              ],
            ),
          ),

          // Bottom safe area padding
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
        ],
      ),
    );
  }
}

// ─── My Code Tab ─────────────────────────────────────────────────────────────

class _MyCodeTab extends StatelessWidget {
  final String qrData;
  final String userName;
  final String? avatarUrl;
  final VoidCallback onShare;
  final VoidCallback onCopy;

  const _MyCodeTab({
    required this.qrData,
    required this.userName,
    required this.avatarUrl,
    required this.onShare,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
              backgroundColor: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

          // Avatar + name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Avatar(url: avatarUrl, name: userName, size: 36),
              const SizedBox(width: 10),
              Text(
                userName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy Link'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Scan Tab ────────────────────────────────────────────────────────────────

class _ScanTab extends StatefulWidget {
  final void Function(BarcodeCapture) onDetect;

  const _ScanTab({required this.onDetect});

  @override
  State<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<_ScanTab> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Scanner viewport
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: widget.onDetect,
                  ),
                  // Scan frame overlay
                  _ScanOverlay(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Point your camera at a Bananatalk QR code',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// A simple corner-bracket overlay to guide scanning
class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const size = 180.0;
    const cornerLength = 24.0;
    const cornerWidth = 3.0;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          color: AppColors.primary,
          cornerLength: cornerLength,
          strokeWidth: cornerWidth,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double cornerLength;
  final double strokeWidth;

  _CornerPainter({
    required this.color,
    required this.cornerLength,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final cl = cornerLength;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, cl)
        ..lineTo(0, 0)
        ..lineTo(cl, 0),
      paint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(w - cl, 0)
        ..lineTo(w, 0)
        ..lineTo(w, cl),
      paint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, h - cl)
        ..lineTo(0, h)
        ..lineTo(cl, h),
      paint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(w - cl, h)
        ..lineTo(w, h)
        ..lineTo(w, h - cl),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.cornerLength != cornerLength ||
      oldDelegate.strokeWidth != strokeWidth;
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;
  final double size;

  const _Avatar({required this.url, required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(url!),
        backgroundColor: AppColors.gray200,
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
