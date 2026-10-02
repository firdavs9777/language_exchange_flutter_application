import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/referral_service.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  late Future<ReferralInfo> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(referralServiceProvider).getMine();
  }

  void _retry() {
    setState(() => _future = ref.read(referralServiceProvider).getMine());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.referralTitle)),
      body: FutureBuilder<ReferralInfo>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Center(
              child: ElevatedButton.icon(
                key: const ValueKey('referral_retry'),
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            );
          }
          final info = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(l10n.referralHowItWorks, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Text(
                l10n.referralYourCode,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Text(
                info.code,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(info.link, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                l10n.referralInvitedCount(info.invited),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final copied = l10n.referralCopied;
                        await Clipboard.setData(ClipboardData(text: info.link));
                        messenger.showSnackBar(SnackBar(content: Text(copied)));
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: Text(l10n.referralCopy),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(
                          text: l10n.referralShareText(info.code, info.link),
                        ),
                      ),
                      icon: const Icon(Icons.ios_share_rounded),
                      label: Text(l10n.referralShare),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
