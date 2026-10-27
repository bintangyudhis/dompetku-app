import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../state/dashboard_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Grafik batang pengeluaran 7 hari terakhir (fl_chart).
///
/// Nol hari tanpa transaksi tetap digambar sebagai batang nol — grafik
/// tidak pernah menyembunyikan hari kosong.
class WeeklyChart extends StatelessWidget {
  const WeeklyChart({required this.days, super.key});

  final List<DailyTotal> days;

  @override
  Widget build(BuildContext context) {
    final maxValue = days.fold<int>(0, (m, d) => d.total > m ? d.total : m);
    final maxY = (maxValue == 0 ? 1 : maxValue).toDouble() * 1.2;
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8D2C4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text(
              'Pengeluaran 7 hari terakhir',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            hariSingkat(days[index].date),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.muted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < days.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: days[i].total.toDouble(),
                          color: AppTheme.primaryGreen,
                          width: 18,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
