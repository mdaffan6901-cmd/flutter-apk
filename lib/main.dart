import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'habits_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(HabitApp(prefs: prefs));
}

String formatDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class Habit {
  final String id;
  String title;
  String description;
  int iconCode;
  int colorValue;
  String category;
  String frequency;
  int target;
  String reminderTime;
  bool isArchived;
  List<String> completedDates;

  Habit({
    required this.id,
    required this.title,
    this.description = '',
    required this.iconCode,
    required this.colorValue,
    required this.category,
    this.frequency = 'Daily',
    this.target = 1,
    this.reminderTime = '08:00',
    this.isArchived = false,
    List<String>? completedDates,
  }) : completedDates = completedDates ?? [];

  bool isCompletedOn(DateTime date) => completedDates.contains(formatDate(date));

  void toggleDate(DateTime date) {
    final key = formatDate(date);
    if (completedDates.contains(key)) {
      completedDates.remove(key);
    } else {
      completedDates.add(key);
    }
  }

  int get currentStreak {
    if (completedDates.isEmpty) return 0;
    final set = completedDates.toSet();
    var check = DateTime.now();
    final today = formatDate(check);
    final yest = formatDate(check.subtract(const Duration(days: 1)));
    if (!set.contains(today) && !set.contains(yest)) return 0;
    if (!set.contains(today)) check = check.subtract(const Duration(days: 1));
    int streak = 0;
    while (set.contains(formatDate(check))) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get bestStreak {
    if (completedDates.isEmpty) return 0;
    final sorted = completedDates.toSet().toList()..sort();
    int best = 0, current = 0;
    DateTime? prev;
    for (final dStr in sorted) {
      final d = DateTime.parse(dStr);
      if (prev == null || d.difference(prev).inDays == 1) {
        current++;
      } else if (d.difference(prev).inDays > 1) {
        current = 1;
      }
      if (current > best) best = current;
      prev = d;
    }
    return best;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'iconCode': iconCode,
        'colorValue': colorValue,
        'category': category,
        'frequency': frequency,
        'target': target,
        'reminderTime': reminderTime,
        'isArchived': isArchived,
        'completedDates': completedDates,
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'],
        title: json['title'],
        description: json['description'] ?? '',
        iconCode: json['iconCode'] ?? Icons.check_circle_outline.codePoint,
        colorValue: json['colorValue'] ?? 0xFF0F766E,
        category: json['category'] ?? 'General',
        frequency: json['frequency'] ?? 'Daily',
        target: json['target'] ?? 1,
        reminderTime: json['reminderTime'] ?? '08:00',
        isArchived: json['isArchived'] ?? false,
        completedDates: List<String>.from(json['completedDates'] ?? []),
      );
}

class AppState extends ChangeNotifier {
  final SharedPreferences _prefs;
  List<Habit> habits = [];
  ThemeMode themeMode = ThemeMode.system;
  Color accentColor = const Color(0xFF0F766E);
  double cornerRadius = 16.0;
  int weekStartDay = DateTime.monday;
  bool notificationsEnabled = true;
  bool soundEnabled = true;

  AppState(this._prefs) {
    _loadState();
  }

  void _loadState() {
    final habitsRaw = _prefs.getString('habits_data');
    if (habitsRaw != null) {
      final List list = jsonDecode(habitsRaw);
      habits = list.map((e) => Habit.fromJson(e)).toList();
    } else {
      loadSampleData(silent: true);
    }
    final tMode = _prefs.getString('theme_mode');
    if (tMode != null) themeMode = ThemeMode.values.byName(tMode);
    final colorVal = _prefs.getInt('accent_color');
    if (colorVal != null) accentColor = Color(colorVal);
    cornerRadius = _prefs.getDouble('corner_radius') ?? 16.0;
    weekStartDay = _prefs.getInt('week_start') ?? DateTime.monday;
    notificationsEnabled = _prefs.getBool('notifications') ?? true;
    soundEnabled = _prefs.getBool('sound') ?? true;
    notifyListeners();
  }

  Future<void> saveState() async {
    final list = habits.map((h) => h.toJson()).toList();
    await _prefs.setString('habits_data', jsonEncode(list));
    await _prefs.setString('theme_mode', themeMode.name);
    await _prefs.setInt('accent_color', accentColor.value);
    await _prefs.setDouble('corner_radius', cornerRadius);
    await _prefs.setInt('week_start', weekStartDay);
    await _prefs.setBool('notifications', notificationsEnabled);
    await _prefs.setBool('sound', soundEnabled);
  }

  void addHabit(Habit habit) {
    habits.add(habit);
    saveState();
    notifyListeners();
  }

  void updateHabit(Habit habit) {
    final idx = habits.indexWhere((h) => h.id == habit.id);
    if (idx != -1) {
      habits[idx] = habit;
      saveState();
      notifyListeners();
    }
  }

  void deleteHabit(String id) {
    habits.removeWhere((h) => h.id == id);
    saveState();
    notifyListeners();
  }

  void toggleHabitToday(String id) {
    final h = habits.firstWhere((element) => element.id == id);
    h.toggleDate(DateTime.now());
    saveState();
    notifyListeners();
  }

  void setArchived(String id, bool archive) {
    final h = habits.firstWhere((element) => element.id == id);
    h.isArchived = archive;
    saveState();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    saveState();
    notifyListeners();
  }

  void setAccentColor(Color color) {
    accentColor = color;
    saveState();
    notifyListeners();
  }

  void setCornerRadius(double radius) {
    cornerRadius = radius;
    saveState();
    notifyListeners();
  }

  void setWeekStart(int day) {
    weekStartDay = day;
    saveState();
    notifyListeners();
  }

  void toggleNotifications(bool val) {
    notificationsEnabled = val;
    saveState();
    notifyListeners();
  }

  void toggleSound(bool val) {
    soundEnabled = val;
    saveState();
    notifyListeners();
  }

  void clearAllData() {
    habits.clear();
    saveState();
    notifyListeners();
  }

  void loadSampleData({bool silent = false}) {
    final now = DateTime.now();
    List<String> genDates(int activeDays) {
      return List.generate(activeDays, (i) => formatDate(now.subtract(Duration(days: i))));
    }

    habits = [
      Habit(
        id: '1',
        title: 'Morning Meditation',
        description: '15 mins mindfulness & breathing',
        iconCode: Icons.self_improvement.codePoint,
        colorValue: 0xFF0284C7,
        category: 'Mindset',
        completedDates: genDates(12),
      ),
      Habit(
        id: '2',
        title: 'Deep Work Session',
        description: '2 hours uninterruptible focus',
        iconCode: Icons.laptop_chromebook.codePoint,
        colorValue: 0xFF0F766E,
        category: 'Productivity',
        completedDates: genDates(8),
      ),
      Habit(
        id: '3',
        title: 'Hydration Goal',
        description: 'Drink 2.5L water daily',
        iconCode: Icons.water_drop_outlined.codePoint,
        colorValue: 0xFF2563EB,
        category: 'Health',
        completedDates: genDates(24),
      ),
      Habit(
        id: '4',
        title: 'Evening Reading',
        description: '20 pages of non-fiction',
        iconCode: Icons.menu_book.codePoint,
        colorValue: 0xFFD97706,
        category: 'Learning',
        completedDates: genDates(5),
      ),
      Habit(
        id: '5',
        title: 'Daily Workout',
        description: 'Strength or mobility workout',
        iconCode: Icons.fitness_center.codePoint,
        colorValue: 0xFFE11D48,
        category: 'Fitness',
        completedDates: genDates(18),
      ),
    ];
    saveState();
    if (!silent) notifyListeners();
  }

  String exportToJson() => jsonEncode(habits.map((h) => h.toJson()).toList());

  bool importFromJson(String raw) {
    try {
      final List list = jsonDecode(raw);
      habits = list.map((e) => Habit.fromJson(e)).toList();
      saveState();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppStateScope>()!.notifier!;
}

class HabitApp extends StatelessWidget {
  final SharedPreferences prefs;
  const HabitApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return _HabitAppRoot(prefs: prefs);
  }
}

class _HabitAppRoot extends StatefulWidget {
  final SharedPreferences prefs;
  const _HabitAppRoot({required this.prefs});

  @override
  State<_HabitAppRoot> createState() => _HabitAppRootState();
}

class _HabitAppRootState extends State<_HabitAppRoot> {
  late final AppState _state;

  @override
  void initState() {
    super.initState();
    _state = AppState(widget.prefs);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        final radius = Radius.circular(_state.cornerRadius);
        final shape = RoundedRectangleBorder(borderRadius: BorderRadius.all(radius));
        return AppStateScope(
          state: _state,
          child: MaterialApp(
            title: 'TrackHabit Web',
            debugShowCheckedModeBanner: false,
            themeMode: _state.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorSchemeSeed: _state.accentColor,
              scaffoldBackgroundColor: const Color(0xFFF8FAFC),
              cardTheme: CardTheme(
                elevation: 0,
                shape: shape,
                color: Colors.white,
                margin: EdgeInsets.zero,
              ),
              dialogTheme: DialogTheme(shape: shape),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorSchemeSeed: _state.accentColor,
              scaffoldBackgroundColor: const Color(0xFF0F172A),
              cardTheme: CardTheme(
                elevation: 0,
                shape: shape,
                color: const Color(0xFF1E293B),
                margin: EdgeInsets.zero,
              ),
              dialogTheme: DialogTheme(shape: shape),
            ),
            home: const AppShell(),
          ),
        );
      },
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;
    final theme = Theme.of(context);

    final screens = const [
      HomeScreen(),
      HabitsScreen(),
      AnalyticsScreen(),
      SettingsScreen(),
    ];

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (val) => setState(() => _index = val),
              extended: width >= 1100,
              minExtendedWidth: 200,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.bolt, color: theme.colorScheme.primary, size: 24),
                    ),
                    if (width >= 1100) ...[
                      const SizedBox(width: 12),
                      Text('HabitFlow',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ]
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.check_circle_outline),
                  selectedIcon: Icon(Icons.check_circle),
                  label: Text('Habits'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights),
                  label: Text('Analytics'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: screens[_index]),
          ],
        ),
      );
    }

    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (val) => setState(() => _index = val),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.check_circle_outline),
              selectedIcon: Icon(Icons.check_circle),
              label: 'Habits'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Analytics'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);
    final today = DateTime.now();
    final activeHabits = state.habits.where((h) => !h.isArchived).toList();
    final completedCount = activeHabits.where((h) => h.isCompletedOn(today)).length;
    final totalCount = activeHabits.length;
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;
    final bestOverallStreak = activeHabits.fold<int>(0, (max, h) => h.currentStreak > max ? h.currentStreak : max);

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
                      Text(
                        '${_monthName(today.month)} ${today.day}, ${today.year}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Today\'s Overview',
                          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => showHabitEditorModal(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Habit'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Daily Progress',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                Text('${(progress * 100).round()}%',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                        color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 10,
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text('$completedCount of $totalCount completed today',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Active Streak',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.local_fire_department,
                                    color: Colors.amber.shade700, size: 28),
                                const SizedBox(width: 6),
                                Text('$bestOverallStreak days',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Top current streak',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text('Today\'s Habits',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (activeHabits.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.checklist, size: 48, color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        Text('No active habits configured', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('Create your daily habits or load sample data in Settings',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => showHabitEditorModal(context),
                          child: const Text('Create Habit'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...activeHabits.map((habit) {
                  final isDone = habit.isCompletedOn(today);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Color(habit.colorValue).withAlpha(40),
                          child: Icon(IconData(habit.iconCode, fontFamily: 'MaterialIcons'),
                              color: Color(habit.colorValue)),
                        ),
                        title: Text(
                          habit.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                            color: isDone ? theme.colorScheme.onSurfaceVariant : null,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(habit.category, style: theme.textTheme.labelSmall),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.local_fire_department, size: 14, color: Colors.amber.shade700),
                            Text(' ${habit.currentStreak}d', style: theme.textTheme.labelSmall),
                          ],
                        ),
                        trailing: Transform.scale(
                          scale: 1.15,
                          child: Checkbox(
                            value: isDone,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                            onChanged: (_) => state.toggleHabitToday(habit.id),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  String _monthName(int m) => const [
        '',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ][m];
}
