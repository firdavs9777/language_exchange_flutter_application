import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';

/// Bottom sheet for tagging a story with a location: a "current location" row
/// (geolocator position -> geocoding reverse lookup for a display name) plus
/// a free-text search field (geocoding forward lookup, first 5 results).
/// Permission denied/unavailable falls back to search-only, silently — no
/// error dialog, since location is a non-critical, optional sticker.
Future<StoryLocation?> showLocationPickerSheet(BuildContext context) {
  return showModalBottomSheet<StoryLocation>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => const _LocationSheet(),
  );
}

class _LocationSheet extends StatefulWidget {
  const _LocationSheet();
  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  final _controller = TextEditingController();
  List<StoryLocation> _results = [];
  bool _busy = false;

  Future<void> _useCurrent() async {
    setState(() => _busy = true);
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return; // fall back to search-only silently
      }
      final pos = await Geolocator.getCurrentPosition();
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final p = placemarks.isNotEmpty ? placemarks.first : null;
      final name = [p?.locality, p?.country]
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .join(', ');
      if (mounted && name.isNotEmpty) {
        Navigator.pop(
            context,
            StoryLocation(
                name: name, longitude: pos.longitude, latitude: pos.latitude));
      }
    } catch (_) {
      // search-only fallback
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 3) return;
    setState(() => _busy = true);
    try {
      final locs = await locationFromAddress(q.trim());
      final results = <StoryLocation>[];
      for (final l in locs.take(5)) {
        final pm = await placemarkFromCoordinates(l.latitude, l.longitude);
        final p = pm.isNotEmpty ? pm.first : null;
        final name = [p?.name, p?.locality, p?.country]
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .toSet()
            .join(', ');
        results.add(StoryLocation(
            name: name.isEmpty ? q.trim() : name,
            longitude: l.longitude,
            latitude: l.latitude));
      }
      if (mounted) setState(() => _results = results);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Search a place…',
                prefixIcon: const Icon(Icons.search_rounded),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.my_location_rounded,
                color: Color(0xFF00BFA5)),
            title: const Text('Use current location'),
            trailing: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : null,
            onTap: _busy ? null : _useCurrent,
          ),
          for (final r in _results)
            ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => Navigator.pop(context, r),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}
