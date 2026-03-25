import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/food_tracker_provider.dart';

/// Shows weekly calorie trend (bar chart) and macro breakdown line chart.
class WeeklyChartScreen extends StatefulWidget {
  const WeeklyChartScreen({super.key});

  @override
  State<WeeklyChartScreen> createState() => _WeeklyChartScreenState();
}

class _WeeklyChartScreenState extends State<WeeklyChartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodTrackerProvider>().loadWeeklyData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Trends')),
      body: Consumer<FoodTrackerProvider>(
        builder: (_, provider, __) {
          if (!provider.weeklyLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = _buildDailyTotals(provider);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionTitle('Calories (last 7 days)'),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: _CalorieBarChart(
                  dailyData: data,
                  goal: provider.goals.calories,
                ),
              ),
              const SizedBox(height: 32),
              _SectionTitle('Macros (last 7 days)'),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: _MacroLineChart(dailyData: data),
              ),
              const SizedBox(height: 32),
              _SectionTitle('Iron (last 7 days)'),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: _IronBarChart(
                  dailyData: data,
                  goal: provider.goals.iron,
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  // ── Build ordered daily total list (oldest → newest, 7 slots) ────────────

  List<_DayData> _buildDailyTotals(FoodTrackerProvider provider) {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final date =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
      final key = _dateKey(date);
      final entries = provider.weeklyEntries[key] ?? [];
      return _DayData(
        label: _shortDay(date),
        calories: entries.fold(0.0, (s, e) => s + e.calories),
        protein: entries.fold(0.0, (s, e) => s + e.protein),
        carbs: entries.fold(0.0, (s, e) => s + e.carbs),
        fat: entries.fold(0.0, (s, e) => s + e.fat),
        iron: entries.fold(0.0, (s, e) => s + e.iron),
      );
    });
  }

  static String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  static String _shortDay(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dt.weekday - 1];
  }
}

class _DayData {
  final String label;
  final double calories, protein, carbs, fat, iron;
  const _DayData({
    required this.label,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.iron,
  });
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.titleSmall,
      );
}

// ── Calorie bar chart ──────────────────────────────────────────────────────

class _CalorieBarChart extends StatelessWidget {
  final List<_DayData> dailyData;
  final double goal;
  const _CalorieBarChart({required this.dailyData, required this.goal});

  @override
  Widget build(BuildContext context) {
    final maxY = dailyData.fold(goal, (m, d) => d.calories > m ? d.calories : m) * 1.15;

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              '${rod.toY.toStringAsFixed(0)} kcal',
              const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Text(
                dailyData[v.toInt()].label,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          dailyData.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: dailyData[i].calories,
                color: dailyData[i].calories >= goal
                    ? Colors.green
                    : Colors.blue.shade300,
                width: 18,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        // Goal reference line
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: goal,
              color: Colors.orange.withOpacity(0.6),
              strokeWidth: 1.5,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                labelResolver: (_) => 'Goal',
                style: const TextStyle(fontSize: 10, color: Colors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Macro line chart ───────────────────────────────────────────────────────

class _MacroLineChart extends StatelessWidget {
  final List<_DayData> dailyData;
  const _MacroLineChart({required this.dailyData});

  @override
  Widget build(BuildContext context) {
    LineChartBarData _line(
      List<double> vals,
      Color color,
    ) =>
        LineChartBarData(
          spots: List.generate(vals.length, (i) => FlSpot(i.toDouble(), vals[i])),
          isCurved: true,
          color: color,
          barWidth: 2,
          dotData: const FlDotData(show: false),
        );

    final maxY = dailyData.fold(
          0.0,
          (m, d) {
            final top = [d.protein, d.carbs, d.fat].reduce((a, b) => a > b ? a : b);
            return top > m ? top : m;
          },
        ) *
        1.2;

    return LineChart(
      LineChartData(
        maxY: maxY.clamp(10, double.infinity),
        lineBarsData: [
          _line(dailyData.map((d) => d.protein).toList(), Colors.blue),
          _line(dailyData.map((d) => d.carbs).toList(), Colors.amber),
          _line(dailyData.map((d) => d.fat).toList(), Colors.purple),
        ],
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= dailyData.length) return const SizedBox.shrink();
                return Text(dailyData[idx].label, style: const TextStyle(fontSize: 11));
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

// ── Iron bar chart ─────────────────────────────────────────────────────────

class _IronBarChart extends StatelessWidget {
  final List<_DayData> dailyData;
  final double goal;
  const _IronBarChart({required this.dailyData, required this.goal});

  @override
  Widget build(BuildContext context) {
    final maxY =
        dailyData.fold(goal, (m, d) => d.iron > m ? d.iron : m) * 1.2;

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              '${rod.toY.toStringAsFixed(1)} mg',
              const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Text(
                dailyData[v.toInt()].label,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          dailyData.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: dailyData[i].iron,
                color: dailyData[i].iron >= goal
                    ? Colors.red
                    : Colors.red.shade200,
                width: 18,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: goal,
              color: Colors.orange.withOpacity(0.6),
              strokeWidth: 1.5,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                labelResolver: (_) => 'Goal',
                style: const TextStyle(fontSize: 10, color: Colors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
