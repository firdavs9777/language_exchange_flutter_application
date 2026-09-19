import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/grammar_station.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/listening_station.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/review_station.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/translate_station.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/vocab_station.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/wrap_station.dart';
import 'package:bananatalk_app/pages/learning/daily/widgets/day_complete_sheet.dart';
import 'package:bananatalk_app/pages/learning/daily/widgets/station_rail.dart';
import 'package:bananatalk_app/services/learning_service.dart';

typedef SubmitStation = Future<StationResult> Function(
  String station, {
  List<int> answers,
  List<Map<String, dynamic>> reviews,
  String text,
});

/// The full-screen day: one station at a time, rail on top, no bottom nav.
///
/// Each station commits on its own, so exiting mid-flow keeps finished work.
/// 21 of the 23 learners who ever opened the old drop never came back, and
/// losing partial progress is one fewer reason to return.
class DailyPackFlow extends StatefulWidget {
  final DailyPack pack;
  final int initialIndex;
  final SubmitStation? submit;
  final VoidCallback? onExit;

  const DailyPackFlow({
    super.key,
    required this.pack,
    this.initialIndex = 0,
    this.submit,
    this.onExit,
  });

  @override
  State<DailyPackFlow> createState() => _DailyPackFlowState();
}

/// The station kinds this build can render. Kept beside `_stationBody`'s
/// switch, which must agree with it.
const Set<String> _kinds = {
  'vocabulary',
  'grammar',
  'listening',
  'review',
  'wrap',
  'translate',
};

class _DailyPackFlowState extends State<DailyPackFlow> {
  late List<PackStation> _outstanding;
  late int _index;
  bool _finished = false;
  StationResult? _last;

  @override
  void initState() {
    super.initState();
    // Empty stations are already satisfied; parking the learner on an empty
    // page would read as a broken step.
    //
    // Unrecognised kinds are dropped for the same reason. `_stationBody`'s
    // default arm renders nothing, and nothing has no Continue button — so a
    // station kind this build does not know about (a server that shipped
    // ahead of the store review) would strand the learner on a blank screen
    // with no way to finish the day.
    _outstanding = widget.pack.stations
        .where((s) => s.isOutstanding && _kinds.contains(s.kind))
        .toList();
    _index = _outstanding.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, _outstanding.length - 1);
  }

  Future<StationResult> _submit(
    String station, {
    List<int> answers = const [],
    List<Map<String, dynamic>> reviews = const [],
    String text = '',
  }) async {
    final result = widget.submit != null
        ? await widget.submit!(station, answers: answers, reviews: reviews, text: text)
        : await LearningService.completeStation(
            station,
            answers: answers,
            reviews: reviews,
            text: text,
          );
    _last = result;
    return result;
  }

  void _advance() {
    if (_index + 1 < _outstanding.length && !(_last?.packComplete ?? false)) {
      setState(() => _index += 1);
      return;
    }
    setState(() => _finished = true);
  }

  Widget _stationBody(PackStation station) {
    switch (station.kind) {
      case 'vocabulary':
        return VocabStation(
          payload: station.payload as VocabPayload,
          onSubmit: (a) => _submit('vocabulary', answers: a),
          onDone: _advance,
        );
      case 'grammar':
        return GrammarStation(
          payload: station.payload as GrammarPayload,
          onSubmit: (a) => _submit('grammar', answers: a),
          onDone: _advance,
        );
      case 'listening':
        return ListeningStation(
          payload: station.payload as ListeningPayload,
          language: widget.pack.language ?? 'en',
          onSubmit: (a) => _submit('listening', answers: a),
          onDone: _advance,
        );
      case 'review':
        return ReviewStation(
          payload: station.payload as ReviewPayload,
          onSubmit: (r) => _submit('review', reviews: r),
          onDone: _advance,
        );
      case 'wrap':
        return WrapStation(
          payload: station.payload as WrapPayload,
          onSubmit: (a) => _submit('wrap', answers: a),
          onDone: _advance,
        );
      case 'translate':
        return TranslateStation(
          payload: station.payload as TranslatePayload,
          onSubmit: (text) => _submit('translate', text: text),
          onDone: _advance,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _exit() {
    if (widget.onExit != null) {
      widget.onExit!();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_finished || _outstanding.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: DayCompleteSheet(
                streak: _last?.streak,
                xpAwarded: _last?.xpAwarded ?? 0,
                themeTopic: widget.pack.theme?.topic,
                onClose: _exit,
              ),
            ),
          ),
        ),
      );
    }

    final station = _outstanding[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pack.theme?.topic ?? l10n.today),
        leading: IconButton(
          key: const Key('pack-close'),
          icon: const Icon(Icons.close),
          onPressed: _exit,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: StationRail(
                stations: widget.pack.stations,
                // The rail draws one dot per station in the PACK, but `_index`
                // walks `_outstanding` — the todo subset. On a fresh day the
                // two lists are identical, which is why this read correctly
                // until someone resumed a half-finished day: then the enlarged
                // "you are here" dot sat on a station they had already
                // finished, and the one they were actually on looked untouched.
                currentIndex: widget.pack.stations.indexOf(station),
              ),
            ),
            Expanded(child: _stationBody(station)),
          ],
        ),
      ),
    );
  }
}
