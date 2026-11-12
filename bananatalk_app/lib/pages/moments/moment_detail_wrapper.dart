import 'package:bananatalk_app/pages/moments/single/single_moment.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/widgets/navigation/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart' show kMomentsTabIndex;

class MomentDetailWrapper extends ConsumerStatefulWidget {
  final String momentId;

  /// Fetches the moment; defaults to [MomentsService.getSingleMoment].
  final Future<Moments> Function(String id)? loadMoment;

  const MomentDetailWrapper({
    super.key,
    required this.momentId,
    this.loadMoment,
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
      final load = widget.loadMoment ??
          (id) => MomentsService().getSingleMoment(id: id);
      final moment = await load(widget.momentId);

      if (mounted) {
        setState(() {
          _moment = moment;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching moment: $e');
      if (!mounted) return;
      if (e is MomentNotFoundException) {
        // Gone: no error page. Back to where the user came from, or (a
        // cold-start push, nothing below) the Moments tab, and say so; the
        // snackbar outlives this route.
        final messenger = ScaffoldMessenger.of(context);
        final message = AppLocalizations.of(context)!.momentNotFound;
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        } else {
          context.go('/tabs/$kMomentsTabIndex');
        }
        messenger.showSnackBar(SnackBar(content: Text(message)));
      } else {
        setState(() {
          _error = AppLocalizations.of(context)!.momentFailedToLoad;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const AppBackButton(),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
          ),
        ),
      );
    }

    if (_error != null || _moment == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: Text(AppLocalizations.of(context)!.error),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error ?? AppLocalizations.of(context)!.momentNotFound,
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
