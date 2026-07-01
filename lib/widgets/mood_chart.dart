import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:curome/models/models.dart';
import 'package:curome/constants/constants.dart';

/// Area chart of mood history (1–5 scale) – mirrors the `MoodAreaGraph`
/// Recharts component from the original React app.
class MoodAreaChart extends StatelessWidget {
  final List<MoodEntry> data;
  final String label;

  const MoodAreaChart({super.key, required this.data, required this.label});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: Text('No mood data yet.',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
      );
    }

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.mood.toDouble());
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54)),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: 1,
                maxY: 5,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.shade100,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 24,
                      getTitlesWidget: (val, _) => Text(
                        val.toInt().toString(),
                        style: TextStyle(
                            fontSize: 9, color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= data.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            data[idx].date,
                            style: TextStyle(
                                fontSize: 8, color: Colors.grey.shade400),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.indigo,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.indigo,
                        strokeColor: Colors.white,
                        strokeWidth: 1.5,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.indigo.withValues(alpha: 0.25),
                          AppColors.indigo.withValues(alpha: 0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((s) {
                      final mood = s.y.toInt();
                      return LineTooltipItem(
                        moodLabels[mood] ?? '$mood',
                        const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}