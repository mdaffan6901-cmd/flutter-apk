import 'package:flutter/material.dart';
import 'main.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _rangeDays = 90;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();

    final allHabits = state.habits;
    final totalCompletions =
        allHabits.fold<int>(0, (sum, h) => sum + h.completedDates.length);
    final bestCurrentStreak =
        allHabits.fold<int>(0, (max, h) => h.currentStreak > max ? h.currentStreak : max);
    final bestEverStreak =
        allHabits.fold<int>(0, (max, h) => h.bestStreak > max ? h.bestStreak : max);

    final dayCounts = <String, int>{};
    for (final h in allHabits) {
      for (final d in h.completedDates) {
        dayCounts[d] = (dayCounts[d] ?? 0) + 1;
      }
    }

    final weekdayCounts = List.filled(7, 0);
    for (int i = 0; i < _rangeDays; i++) {
      final d = now.subtract(Duration(days: i));
      final count = dayCounts[formatDate(d)] ?? 0;
      weekdayCounts[d.weekday - 1] += count;
    }

    final catCounts = <String, int>{};
    for (final h in allHabits) {
      catCounts[h.category] = (catCounts[h.category] ?? 0) + h.completedDates.length;
    }

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Analytics & Insights',
                          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Habit consistency and activity heatmaps',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 30, label: Text('30D')),
                      ButtonSegment(value: 90, label: Text('90D')),
                      ButtonSegment(value: 180, label: Text('180D')),
                    ],
                    selected: {_rangeDays},
                    onSelectionChanged: (set) => setState(() => _rangeDays = set.first),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _statCard(context, 'Total Check-ins', totalCompletions.toString(), Icons.done_all),
                  const SizedBox(width: 12),
                  _statCard(context, 'Current Top Streak', '$bestCurrentStreak d', Icons.local_fire_department),
                  const SizedBox(width: 12),
                  _statCard(context, 'Best Streak Record', '$bestEverStreak d', Icons.emoji_events_outlined),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Activity Heatmap (Past 20 Weeks)',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              Text('Less', style: theme.textTheme.labelSmall),
                              const SizedBox(width: 4),
                              _colorBox(theme.colorScheme.surfaceContainerHighest),
                              _colorBox(theme.colorScheme.primary.withAlpha(80)),
                              _colorBox(theme.colorScheme.primary.withAlpha(160)),
                              _colorBox(theme.colorScheme.primary),
                              const SizedBox(width: 4),
                              Text('More', style: theme.textTheme.labelSmall),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _buildHeatmapGrid(context, dayCounts, now),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Completions by Day of Week',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            _buildWeekdayChart(context, weekdayCounts),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Category Breakdown',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            if (catCounts.isEmpty)
                              const Text('No records recorded.')
                            else
                              ...catCounts.entries.map((e) {
                                final pct = totalCompletions == 0 ? 0.0 : e.value / totalCompletions;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(e.key, style: theme.textTheme.bodyMedium),
                                          Text('${(pct * 100).round()}% (${e.value})',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                  color: theme.colorScheme.onSurfaceVariant)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: pct,
                                          minHeight: 6,
                                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Habit Performance Breakdown',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...allHabits.map((habit) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(habit.colorValue).withAlpha(40),
                          child: Icon(IconData(habit.iconCode, fontFamily: 'MaterialIcons'),
                              color: Color(habit.colorValue)),
                        ),
                        title: Text(habit.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            'Current streak: ${habit.currentStreak}d  •  Best: ${habit.bestStreak}d  •  Total: ${habit.completedDates.length} completions'),
                        trailing: habit.isArchived
                            ? const Chip(label: Text('Archived'), padding: EdgeInsets.zero)
                            : null,
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(BuildContext context, String title, String value, IconData icon) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 20),
              const SizedBox(height: 8),
              Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(title,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorBox(Color c) => Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
      );

  Widget _buildHeatmapGrid(
      BuildContext context, Map<String, int> counts, DateTime now) {
    final theme = Theme.of(context);
    const totalWeeks = 20;
    const daysInWeek = 7;

    final cells = <Widget>[];
    for (int w = totalWeeks - 1; w >= 0; w--) {
      final col = <Widget>[];
      for (int d = 0; d < daysInWeek; d++) {
        final date = now.subtract(Duration(days: (w * 7) + (6 - d)));
        final key = formatDate(date);
        final count = counts[key] ?? 0;

        Color cellColor = theme.colorScheme.surfaceContainerHighest;
        if (count == 1) cellColor = theme.colorScheme.primary.withAlpha(70);
        if (count == 2) cellColor = theme.colorScheme.primary.withAlpha(140);
        if (count >= 3) cellColor = theme.colorScheme.primary;

        col.add(
          Tooltip(
            message: '$key: $count habits completed',
            child: Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: cellColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      }
      cells.add(Column(children: col));
    }
    return Row(children: cells);
  }

  Widget _buildWeekdayChart(BuildContext context, List<int> counts) {
    final theme = Theme.of(context);
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final maxCount = counts.fold<int>(1, (max, v) => v > max ? v : max);

    return SizedBox(
      height: 140,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final count = counts[i];
          final heightFactor = count / maxCount;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(count.toString(), style: theme.textTheme.labelSmall),
              const SizedBox(height: 4),
              Container(
                width: 24,
                height: (heightFactor * 90).clamp(4, 90),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
              const SizedBox(height: 6),
              Text(days[i], style: theme.textTheme.labelSmall),
            ],
          );
        }),
      ),
    );
  }
}
