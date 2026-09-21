import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Reusable fl_chart line chart.
class LineChartMulti extends StatelessWidget {
  final List<FlSpot> spots;
  final Color color;
  final double? minY;
  final double? maxY;
  final String? Function(double)? xFormatter;
  final String? Function(double)? yFormatter;

  const LineChartMulti({
    super.key,
    required this.spots,
    required this.color,
    this.minY,
    this.maxY,
    this.xFormatter,
    this.yFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (spots.isEmpty) {
      return const Center(child: Text('No data'));
    }
    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots
                .map((spot) => LineTooltipItem(
                      '${spot.y.toStringAsFixed(1)}',
                      TextStyle(
                          color: theme.colorScheme.surface,
                          fontWeight: FontWeight.w700),
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: color,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 3,
                color: color,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.12),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: yFormatter != null,
              reservedSize: 34,
              getTitlesWidget: (v, meta) => Text(
                yFormatter?.call(v) ?? v.toStringAsFixed(0),
                style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  xFormatter?.call(v) ?? v.toStringAsFixed(0),
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                ),
              ),
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY == null ? null : (maxY! - (minY ?? 0)) / 4,
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

/// Simplified wrapper for a single-colour line chart.
class LineChartView extends StatelessWidget {
  final List<FlSpot> spots;
  final Color color;
  final double? minY;
  final double? maxY;
  final String? Function(double)? xFormatter;
  final String? Function(double)? yFormatter;

  const LineChartView({
    required this.spots,
    required this.color,
    this.minY,
    this.maxY,
    this.xFormatter,
    this.yFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return LineChartMulti(
      spots: spots,
      color: color,
      minY: minY,
      maxY: maxY,
      xFormatter: xFormatter,
      yFormatter: yFormatter,
    );
  }
}