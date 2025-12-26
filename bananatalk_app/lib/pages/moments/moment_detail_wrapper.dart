import 'package:bananatalk_app/pages/moments/single_moment.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MomentDetailWrapper extends ConsumerStatefulWidget {
  final String momentId;

  const MomentDetailWrapper({
    super.key,
    required this.momentId,
  });

  @override
  ConsumerState<MomentDetailWrapper> createState() =>
      _MomentDetailWrapperState();
}

class _MomentDetailWrapperState extends ConsumerState<MomentDetailWrapper> {
  Moments? _moment;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMoment();
  }

  Future<void> _fetchMoment() async {
    try {
      final momentsService = MomentsService();
      final moment =
          await momentsService.getSingleMoment(id: widget.momentId);

      if (mounted) {
        setState(() {
          _moment = moment;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching moment: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load moment';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
          ),
        ),
      );
    }

    if (_error != null || _moment == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.error),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Moment not found',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.goBack),
              ),
            ],
          ),
        ),
      );
    }

    return SingleMoment(moment: _moment!);
  }
}

