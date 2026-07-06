import 'dart:convert';

import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Splits an exam prompt into an optional embedded figure (chart/table) and
/// the remaining prose.
///
/// IELTS Academic Writing Task 1 prompts describe a chart, graph or table.
/// Rather than add a backend schema field or host chart images, we encode the
/// figure as a delimited JSON block inside the question's `questionText`:
///
///   <<<FIGURE
///   { "type": "bar", "title": "…", "unit": "%", "categories": [...],
///     "series": [ { "name": "Solar", "values": [12, 20, 34] } ] }
///   FIGURE>>>
///   The chart shows … Summarise the information …
///
/// When no block is present [figure] is null and the whole string is [prose],
/// so letter-style and essay prompts are completely unaffected.
class ExamPrompt {
  const ExamPrompt({this.figure, required this.prose});

  final Map<String, dynamic>? figure;
  final String prose;

  static final _re =
      RegExp(r'<<<FIGURE\s*(\{.*\})\s*FIGURE>>>', dotAll: true);

  factory ExamPrompt.parse(String raw) {
    final m = _re.firstMatch(raw);
    if (m == null) return ExamPrompt(prose: raw.trim());
    Map<String, dynamic>? spec;
    try {
      spec = json.decode(m.group(1)!) as Map<String, dynamic>;
    } catch (_) {
      spec = null; // Malformed block → fall back to text-only.
    }
    final prose = raw.replaceRange(m.start, m.end, '').trim();
    return ExamPrompt(figure: spec, prose: prose);
  }
}

/// Renders a figure spec ([ExamPrompt.figure]) as a chart or table.
/// Supports `type`: "bar", "line", "pie", "table". Unknown types render
/// nothing so a bad spec can never crash the screen.
class ExamFigureView extends StatelessWidget {
  const ExamFigureView({super.key, required this.spec});

  final Map<String, dynamic> spec;

  static const List<Color> _palette = [
    Color(0xFF6366F1),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
    Color(0xFFA855F7),
  ];

  @override
  Widget build(BuildContext context) {
    final type = (spec['type'] as String?)?.toLowerCase();
    final title = spec['title'] as String?;
    final Widget body;
    switch (type) {
      case 'bar':
        body = _buildBar(context);
        break;
      case 'line':
        body = _buildLine(context);
        break;
      case 'pie':
        body = _buildPie(context);
        break;
      case 'table':
        body = _buildTable(context);
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title.isNotEmpty) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
          ],
          body,
        ],
      ),
    );
  }

  // ---- shared helpers -------------------------------------------------

  List<String> _categories() =>
      (spec['categories'] as List?)?.map((e) => e.toString()).toList() ??
      const [];

  List<({String name, List<double> values})> _series() {
    final raw = (spec['series'] as List?) ?? const [];
    return raw.map((s) {
      final m = s as Map<String, dynamic>;
      final values = (m['values'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const <double>[];
      return (name: m['name']?.toString() ?? '', values: values);
    }).toList();
  }

  double _maxValue(List<({String name, List<double> values})> series) {
    var max = 0.0;
    for (final s in series) {
      for (final v in s.values) {
        if (v > max) max = v;
      }
    }
    // Round up to a tidy axis ceiling.
    if (max <= 0) return 1;
    final step = max <= 10 ? 2 : (max <= 50 ? 10 : (max <= 100 ? 20 : 50));
    return ((max / step).ceil() * step).toDouble();
  }

  Widget _legend(BuildContext context, List<String> names) {
    if (names.length < 2) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        children: [
          for (var i = 0; i < names.length; i++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _palette[i % _palette.length],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  names[i],
                  style: TextStyle(fontSize: 11, color: context.textSecondary),
                ),
              ],
            ),
        ],
      ),
    );
  }

  AxisTitles _bottomCategoryTitles(
      BuildContext context, List<String> categories) {
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 28,
        getTitlesWidget: (value, meta) {
          final i = value.toInt();
          if (i < 0 || i >= categories.length) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              categories[i],
              style: TextStyle(fontSize: 10, color: context.textSecondary),
            ),
          );
        },
      ),
    );
  }

  FlTitlesData _titlesData(BuildContext context, List<String> categories) {
    return FlTitlesData(
      show: true,
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          getTitlesWidget: (value, meta) => Text(
            value.toInt().toString(),
            style: TextStyle(fontSize: 10, color: context.textMuted),
          ),
        ),
      ),
      bottomTitles: _bottomCategoryTitles(context, categories),
    );
  }

  // ---- bar ------------------------------------------------------------

  Widget _buildBar(BuildContext context) {
    final categories = _categories();
    final series = _series();
    final maxY = _maxValue(series);
    final groupWidth = series.length <= 1 ? 14.0 : 9.0;

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: context.dividerColor, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: _titlesData(context, categories),
              barGroups: [
                for (var c = 0; c < categories.length; c++)
                  BarChartGroupData(
                    x: c,
                    barRods: [
                      for (var s = 0; s < series.length; s++)
                        BarChartRodData(
                          toY: c < series[s].values.length
                              ? series[s].values[c]
                              : 0,
                          color: _palette[s % _palette.length],
                          width: groupWidth,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        _legend(context, series.map((s) => s.name).toList()),
      ],
    );
  }

  // ---- line -----------------------------------------------------------

  Widget _buildLine(BuildContext context) {
    final categories = _categories();
    final series = _series();
    final maxY = _maxValue(series);

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              maxY: maxY,
              minX: 0,
              maxX: (categories.length - 1).toDouble().clamp(0, double.infinity),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: context.dividerColor, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: _titlesData(context, categories),
              lineBarsData: [
                for (var s = 0; s < series.length; s++)
                  LineChartBarData(
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: _palette[s % _palette.length],
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    spots: [
                      for (var i = 0; i < series[s].values.length; i++)
                        FlSpot(i.toDouble(), series[s].values[i]),
                    ],
                  ),
              ],
            ),
          ),
        ),
        _legend(context, series.map((s) => s.name).toList()),
      ],
    );
  }

  // ---- pie ------------------------------------------------------------

  Widget _buildPie(BuildContext context) {
    final slices = (spec['slices'] as List?) ?? const [];
    final labels = <String>[];
    final sections = <PieChartSectionData>[];
    for (var i = 0; i < slices.length; i++) {
      final m = slices[i] as Map<String, dynamic>;
      final value = (m['value'] as num?)?.toDouble() ?? 0;
      labels.add(m['label']?.toString() ?? '');
      sections.add(
        PieChartSectionData(
          value: value,
          title: value > 0 ? value.toStringAsFixed(0) : '',
          color: _palette[i % _palette.length],
          radius: 70,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 28,
              sectionsSpace: 2,
            ),
          ),
        ),
        _legend(context, labels),
      ],
    );
  }

  // ---- table ----------------------------------------------------------

  Widget _buildTable(BuildContext context) {
    final columns =
        (spec['columns'] as List?)?.map((e) => e.toString()).toList() ??
            const [];
    final rows = (spec['rows'] as List?) ?? const [];

    TableRow headerRow() => TableRow(
          decoration: BoxDecoration(color: context.containerColor),
          children: [
            for (final c in columns)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Text(
                  c,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
              ),
          ],
        );

    TableRow dataRow(List cells) => TableRow(
          children: [
            for (final cell in cells)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Text(
                  cell.toString(),
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
              ),
          ],
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Table(
        border: TableBorder.all(color: context.dividerColor, width: 1),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          headerRow(),
          for (final r in rows) dataRow(r as List),
        ],
      ),
    );
  }
}
