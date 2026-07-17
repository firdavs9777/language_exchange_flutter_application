import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/models/coin_transaction.dart';
import 'package:bananatalk_app/providers/coins_provider.dart';
import 'package:bananatalk_app/services/coin_api_client.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Coins v2 (Task 17) — full ledger history, reachable from the coin
/// shop's balance row. Reads `GET /coins/transactions` via
/// [CoinApiClient.getTransactions] (cursor-paginated).
class CoinHistoryScreen extends ConsumerStatefulWidget {
  const CoinHistoryScreen({super.key});

  @override
  ConsumerState<CoinHistoryScreen> createState() => _CoinHistoryScreenState();
}

class _CoinHistoryScreenState extends ConsumerState<CoinHistoryScreen> {
  final List<CoinTransaction> _transactions = [];
  String? _nextCursor;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final client = ref.read(coinApiClientProvider);
      final page = await client.getTransactions();
      if (!mounted) return;
      setState(() {
        _transactions
          ..clear()
          ..addAll(page.transactions);
        _nextCursor = page.nextCursor;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is CoinApiException ? e.message : 'Could not load coin history.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _nextCursor == null) return;
    setState(() => _isLoadingMore = true);
    try {
      final client = ref.read(coinApiClientProvider);
      final page = await client.getTransactions(cursor: _nextCursor);
      if (!mounted) return;
      setState(() {
        _transactions.addAll(page.transactions);
        _nextCursor = page.nextCursor;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load more history.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        title: const Text('Coin History'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Icon(Icons.error_outline, size: 40, color: context.textMuted),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: context.bodyMedium.copyWith(color: context.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ),
        ],
      );
    }
    if (_transactions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          const Center(child: Text('💎', style: TextStyle(fontSize: 40))),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'No coin activity yet',
              style: context.bodyMedium.copyWith(color: context.textSecondary),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _transactions.length + (_nextCursor != null ? 1 : 0),
      separatorBuilder: (_, __) => Divider(height: 1, color: context.dividerColor),
      itemBuilder: (context, index) {
        if (index >= _transactions.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _isLoadingMore
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(onPressed: _loadMore, child: const Text('Load more')),
            ),
          );
        }
        return _buildRow(_transactions[index]);
      },
    );
  }

  Widget _buildRow(CoinTransaction tx) {
    final isCredit = tx.amount >= 0;
    final color = isCredit ? AppColors.success : AppColors.error;
    final amountText = '${isCredit ? '+' : ''}${tx.amount}';

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(_iconFor(tx.reason), color: color, size: 20),
      ),
      title: Text(_labelFor(tx.reason), style: context.titleSmall),
      subtitle: tx.createdAt != null
          ? Text(
              timeago.format(tx.createdAt!),
              style: context.captionSmall.copyWith(color: context.textMuted),
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$amountText 💎',
            style: context.titleSmall.copyWith(color: color, fontWeight: FontWeight.w800),
          ),
          if (tx.createdAt != null)
            Text(
              DateFormat.yMMMd().format(tx.createdAt!.toLocal()),
              style: context.captionSmall.copyWith(color: context.textMuted),
            ),
        ],
      ),
    );
  }

  IconData _iconFor(String? reason) {
    if (reason == null) return Icons.swap_horiz;
    if (reason == 'daily_reward') return Icons.card_giftcard;
    if (reason == 'ad_reward') return Icons.play_circle_outline;
    if (reason == 'iap_purchase') return Icons.credit_card;
    if (reason.startsWith('unlock:')) return Icons.lock_open;
    return Icons.swap_horiz;
  }

  String _labelFor(String? reason) {
    if (reason == null) return 'Coin activity';
    if (reason == 'daily_reward') return 'Daily reward';
    if (reason == 'ad_reward') return 'Watched an ad';
    if (reason == 'iap_purchase') return 'Coin purchase';
    if (reason.startsWith('unlock:')) {
      final feature = reason.substring('unlock:'.length);
      return 'Unlocked ${_titleCase(feature)}';
    }
    return 'Coin activity';
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
