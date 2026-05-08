import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/services/storage_service.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/settings/widgets/settings_snackbar.dart';
import 'package:bananatalk_app/pages/settings/widgets/cache_stats_card.dart';

class DataStorageScreen extends ConsumerStatefulWidget {
  const DataStorageScreen({super.key});

  @override
  ConsumerState<DataStorageScreen> createState() => _DataStorageScreenState();
}

class _DataStorageScreenState extends ConsumerState<DataStorageScreen> {
  StorageBreakdown? _storageBreakdown;
  bool _isLoading = true;
  bool _isClearing = false;
  String? _clearingType;

  // Auto-download settings
  AutoDownloadOption _autoDownloadImages = AutoDownloadOption.always;
  AutoDownloadOption _autoDownloadVideos = AutoDownloadOption.wifiOnly;
  AutoDownloadOption _autoDownloadVoice = AutoDownloadOption.always;
  AutoDownloadOption _autoDownloadDocuments = AutoDownloadOption.wifiOnly;

  String _networkType = 'Unknown';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final breakdown = await StorageService.calculateStorageBreakdown();
      final images = await StorageService.getAutoDownloadImages();
      final videos = await StorageService.getAutoDownloadVideos();
      final voice = await StorageService.getAutoDownloadVoice();
      final documents = await StorageService.getAutoDownloadDocuments();
      final network = await StorageService.getCurrentNetworkType();

      if (mounted) {
        setState(() {
          _storageBreakdown = breakdown;
          _autoDownloadImages = images;
          _autoDownloadVideos = videos;
          _autoDownloadVoice = voice;
          _autoDownloadDocuments = documents;
          _networkType = network;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearCache(String type) async {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isClearing = true;
      _clearingType = type;
    });

    try {
      switch (type) {
        case 'image':
          await StorageService.clearImageCache();
          break;
        case 'voice':
          await StorageService.clearVoiceCache();
          break;
        case 'video':
          await StorageService.clearVideoCache();
          break;
        case 'all':
          await StorageService.clearAllCache();
          break;
      }

      // Reload storage info
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.cacheCleared)),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showSettingsSnackBar(
          context,
          message: '${l10n.clearCacheFailed}: $e',
          type: SettingsSnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClearing = false;
          _clearingType = null;
        });
      }
    }
  }

  void _showClearConfirmation(String type, String title, int size) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXL),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: AppRadius.borderSM,
              ),
              child: const Icon(Icons.cleaning_services, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${l10n.clearCache}?',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type == 'all'
                  ? l10n.clearAllCacheConfirmation
                  : l10n.clearCacheConfirmationFor(title),
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.containerColor,
                borderRadius: AppRadius.borderSM,
              ),
              child: Row(
                children: [
                  Icon(Icons.storage, color: context.textSecondary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.storageToFree(StorageBreakdown.formatBytes(size)),
                    style: context.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCache(type);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.clearCache),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.surfaceColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.dataAndStorage, style: context.titleLarge),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Storage Usage Section
                    _buildSectionHeader(l10n.storageUsage),
                    if (_storageBreakdown != null)
                      CacheStatsCard(
                        breakdown: _storageBreakdown!,
                        isClearing: _isClearing,
                        clearingType: _clearingType,
                        onClearImages: () => _showClearConfirmation(
                          'image',
                          l10n.imageCache,
                          _storageBreakdown!.imageCache,
                        ),
                        onClearVoice: () => _showClearConfirmation(
                          'voice',
                          l10n.voiceMessagesCache,
                          _storageBreakdown!.voiceMessages,
                        ),
                        onClearVideo: () => _showClearConfirmation(
                          'video',
                          l10n.videoCache,
                          _storageBreakdown!.videoCache,
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Auto-Download Section
                    _buildSectionHeader(l10n.autoDownloadMedia),
                    _buildNetworkInfo(),
                    _buildAutoDownloadCard(),

                    const SizedBox(height: 24),

                    // Clear All Cache Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isClearing
                              ? null
                              : () => _showClearConfirmation(
                                    'all',
                                    l10n.allCache,
                                    _storageBreakdown?.total ?? 0,
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.borderMD,
                            ),
                          ),
                          icon: _isClearing && _clearingType == 'all'
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.delete_sweep),
                          label: Text(
                            l10n.clearAllCache,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: context.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNetworkInfo() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: AppRadius.borderMD,
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _networkType == 'WiFi'
                ? Icons.wifi
                : _networkType == 'Mobile Data'
                    ? Icons.signal_cellular_alt
                    : Icons.signal_wifi_off,
            color: AppColors.info,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${l10n.currentNetwork}: $_networkType',
            style: context.bodySmall.copyWith(color: AppColors.info),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoDownloadCard() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderLG,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          _buildAutoDownloadItem(
            icon: Icons.image,
            iconColor: Colors.blue,
            title: l10n.images,
            value: _autoDownloadImages,
            onChanged: (option) async {
              setState(() => _autoDownloadImages = option);
              await StorageService.setAutoDownloadImages(option);
            },
          ),
          Divider(height: 1, color: context.dividerColor),
          _buildAutoDownloadItem(
            icon: Icons.videocam,
            iconColor: Colors.purple,
            title: l10n.videos,
            value: _autoDownloadVideos,
            onChanged: (option) async {
              setState(() => _autoDownloadVideos = option);
              await StorageService.setAutoDownloadVideos(option);
            },
          ),
          Divider(height: 1, color: context.dividerColor),
          _buildAutoDownloadItem(
            icon: Icons.mic,
            iconColor: Colors.orange,
            title: l10n.voiceMessagesShort,
            value: _autoDownloadVoice,
            onChanged: (option) async {
              setState(() => _autoDownloadVoice = option);
              await StorageService.setAutoDownloadVoice(option);
            },
          ),
          Divider(height: 1, color: context.dividerColor),
          _buildAutoDownloadItem(
            icon: Icons.insert_drive_file,
            iconColor: Colors.teal,
            title: l10n.documentsLabel,
            value: _autoDownloadDocuments,
            onChanged: (option) async {
              setState(() => _autoDownloadDocuments = option);
              await StorageService.setAutoDownloadDocuments(option);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAutoDownloadItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required AutoDownloadOption value,
    required ValueChanged<AutoDownloadOption> onChanged,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: AppRadius.borderSM,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: context.titleSmall),
          ),
          PopupMenuButton<AutoDownloadOption>(
            initialValue: value,
            onSelected: onChanged,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMD),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.containerColor,
                borderRadius: AppRadius.borderSM,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getAutoDownloadLabel(l10n, value),
                    style: context.bodySmall.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 20, color: context.textSecondary),
                ],
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: AutoDownloadOption.always,
                child: Row(
                  children: [
                    Icon(
                      Icons.download,
                      size: 20,
                      color: value == AutoDownloadOption.always
                          ? AppColors.primary
                          : context.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.always),
                  ],
                ),
              ),
              PopupMenuItem(
                value: AutoDownloadOption.wifiOnly,
                child: Row(
                  children: [
                    Icon(
                      Icons.wifi,
                      size: 20,
                      color: value == AutoDownloadOption.wifiOnly
                          ? AppColors.primary
                          : context.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.wifiOnly),
                  ],
                ),
              ),
              PopupMenuItem(
                value: AutoDownloadOption.never,
                child: Row(
                  children: [
                    Icon(
                      Icons.block,
                      size: 20,
                      color: value == AutoDownloadOption.never
                          ? AppColors.primary
                          : context.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.never),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getAutoDownloadLabel(AppLocalizations l10n, AutoDownloadOption option) {
    switch (option) {
      case AutoDownloadOption.always:
        return l10n.always;
      case AutoDownloadOption.wifiOnly:
        return l10n.wifiOnly;
      case AutoDownloadOption.never:
        return l10n.never;
    }
  }
}
