import 'package:permission_handler/permission_handler.dart';

/// Service to manage app permissions
/// 
/// NOTE: Requesting all permissions at startup is NOT recommended by Apple guidelines.
/// Permissions should be requested in context when needed.
/// This service is provided for testing/debugging purposes only.
class PermissionService {
  /// Check the current status of all permissions
  static Future<Map<Permission, PermissionStatus>> checkAllPermissions() async {
    final permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.location,
      Permission.locationWhenInUse,
      Permission.photos,
    ];

    final statuses = <Permission, PermissionStatus>{};
    for (final permission in permissions) {
      statuses[permission] = await permission.status;
    }

    return statuses;
  }

  /// Request all permissions at once (for testing/debugging only)
  /// 
  /// ⚠️ WARNING: This is NOT recommended for production apps.
  /// Apple guidelines suggest requesting permissions when they're needed in context.
  static Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    print('🔐 PermissionService: Requesting all permissions...');
    
    final permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.locationWhenInUse, // Start with WhenInUse, not Always
      Permission.photos,
    ];

    final statuses = await permissions.request();

    print('📋 PermissionService: Permission request results:');
    statuses.forEach((permission, status) {
      print('   ${permission.toString()}: $status');
    });

    return statuses;
  }

  /// Request only call-related permissions (camera and microphone)
  static Future<bool> requestCallPermissions({required bool includeCamera}) async {
    final permissions = [
      Permission.microphone,
      if (includeCamera) Permission.camera,
    ];

    final statuses = await permissions.request();
    
    return statuses.values.every((status) => status.isGranted);
  }

  /// Request location permission
  static Future<PermissionStatus> requestLocationPermission() async {
    return await Permission.locationWhenInUse.request();
  }

  /// Get a human-readable status summary
  static String getStatusSummary(Map<Permission, PermissionStatus> statuses) {
    final buffer = StringBuffer();
    statuses.forEach((permission, status) {
      buffer.writeln('${permission.toString()}: ${status.toString()}');
    });
    return buffer.toString();
  }
}

