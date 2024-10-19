import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/pages/moments/create_moment.dart';
import 'package:bananatalk_app/pages/moments/moment_card.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';

class MomentsMain extends ConsumerWidget {
  const MomentsMain({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> refresh() async {
      ref.refresh(momentsProvider);
    }

    final momentsList = ref.watch(momentsProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Moments'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (ctx) => const CreateMoment()))
                    .then((_) {
                  ref.refresh(momentsProvider);
                });
              },
              icon: const Icon(
                Icons.add,
                size: 34,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: momentsList.when(
          data: (item) {
            if (item.isEmpty) {
              return const Center(child: Text('No moments available.'));
            }
            return Container(
              child: ListView.builder(
                itemCount: item.length,
                itemBuilder: (context, index) {
                  final moments = item[index];
                  return MomentCard(moments: moments);
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error $stack')),
        ),
      ),
    );
  }
}
