import 'package:flutter/material.dart';
import 'main.dart';

void showHabitEditorModal(BuildContext context, [Habit? habit]) {
  final isDesktop = MediaQuery.of(context).size.width >= 700;
  if (isDesktop) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: HabitEditorForm(habit: habit),
          ),
        ),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: HabitEditorForm(habit: habit),
      ),
    );
  }
}

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);

    final categories = ['All', 'Health', 'Productivity', 'Mindset', 'Learning', 'Fitness'];

    final filtered = state.habits.where((h) {
      if (h.isArchived != _showArchived) return false;
      if (_selectedCategory != 'All' && h.category != _selectedCategory) return false;
      if (_searchQuery.isNotEmpty &&
          !h.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !h.description.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

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
                      Text('Habit Management',
                          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${state.habits.length} habits configured',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: () => showHabitEditorModal(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Habit'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search habits...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...categories.map((c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(c),
                            selected: _selectedCategory == c,
                            onSelected: (_) => setState(() => _selectedCategory = c),
                          ),
                        )),
                    FilterChip(
                      label: const Text('Archived'),
                      selected: _showArchived,
                      onSelected: (val) => setState(() => _showArchived = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (filtered.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text('No habits match the criteria',
                          style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ),
                  ),
                )
              else
                ...filtered.map((habit) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Color(habit.colorValue).withAlpha(40),
                                radius: 24,
                                child: Icon(
                                  IconData(habit.iconCode, fontFamily: 'MaterialIcons'),
                                  color: Color(habit.colorValue),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(habit.title,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(fontWeight: FontWeight.bold)),
                                    if (habit.description.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(habit.description,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant)),
                                    ],
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(habit.category,
                                              style: theme.textTheme.labelSmall),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('${habit.frequency} • ${habit.reminderTime}',
                                            style: theme.textTheme.labelSmall?.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant)),
                                        const SizedBox(width: 8),
                                        Icon(Icons.local_fire_department,
                                            size: 14, color: Colors.amber.shade700),
                                        Text('${habit.currentStreak}d streak',
                                            style: theme.textTheme.labelSmall),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                tooltip: 'Edit',
                                onPressed: () => showHabitEditorModal(context, habit),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (action) {
                                  if (action == 'archive') {
                                    state.setArchived(habit.id, !habit.isArchived);
                                  } else if (action == 'delete') {
                                    _confirmDelete(context, habit.id, habit.title);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  PopupMenuItem(
                                    value: 'archive',
                                    child: Text(habit.isArchived ? 'Restore' : 'Archive'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to permanently delete "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              AppStateScope.of(context).deleteHabit(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class HabitEditorForm extends StatefulWidget {
  final Habit? habit;
  const HabitEditorForm({super.key, this.habit});

  @override
  State<HabitEditorForm> createState() => _HabitEditorFormState();
}

class _HabitEditorFormState extends State<HabitEditorForm> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _description;
  late String _category;
  late String _frequency;
  late int _target;
  late String _reminderTime;
  late int _iconCode;
  late int _colorValue;

  final List<int> _colors = const [
    0xFF0F766E,
    0xFF0284C7,
    0xFF2563EB,
    0xFF7C3AED,
    0xFFD97706,
    0xFFE11D48,
    0xFF16A34A,
    0xFF475569
  ];

  final List<IconData> _icons = const [
    Icons.check_circle_outline,
    Icons.self_improvement,
    Icons.laptop_chromebook,
    Icons.water_drop_outlined,
    Icons.menu_book,
    Icons.fitness_center,
    Icons.directions_run,
    Icons.bedtime_outlined,
    Icons.code,
    Icons.brush_outlined,
  ];

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _title = h?.title ?? '';
    _description = h?.description ?? '';
    _category = h?.category ?? 'Health';
    _frequency = h?.frequency ?? 'Daily';
    _target = h?.target ?? 1;
    _reminderTime = h?.reminderTime ?? '08:00';
    _iconCode = h?.iconCode ?? _icons.first.codePoint;
    _colorValue = h?.colorValue ?? _colors.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.habit != null;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isEdit ? 'Edit Habit' : 'New Habit',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _title,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a title' : null,
              onSaved: (v) => _title = v!.trim(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _description,
              decoration:
                  const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
              onSaved: (v) => _description = v?.trim() ?? '',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _category,
                    decoration:
                        const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: ['Health', 'Productivity', 'Mindset', 'Learning', 'Fitness', 'General']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _frequency,
                    decoration:
                        const InputDecoration(labelText: 'Frequency', border: OutlineInputBorder()),
                    items: ['Daily', 'Weekly']
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (v) => setState(() => _frequency = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Color Accent', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors
                  .map((c) => InkWell(
                        onTap: () => setState(() => _colorValue = c),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(c),
                          child: _colorValue == c
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : null,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text('Icon', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _icons
                  .map((icon) => InkWell(
                        onTap: () => setState(() => _iconCode = icon.codePoint),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _iconCode == icon.codePoint
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, size: 22),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _save,
                  child: Text(isEdit ? 'Save Changes' : 'Create'),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    final state = AppStateScope.of(context);
    if (widget.habit != null) {
      final h = widget.habit!;
      h.title = _title;
      h.description = _description;
      h.category = _category;
      h.frequency = _frequency;
      h.target = _target;
      h.reminderTime = _reminderTime;
      h.iconCode = _iconCode;
      h.colorValue = _colorValue;
      state.updateHabit(h);
    } else {
      state.addHabit(Habit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _title,
        description: _description,
        iconCode: _iconCode,
        colorValue: _colorValue,
        category: _category,
        frequency: _frequency,
        target: _target,
        reminderTime: _reminderTime,
      ));
    }
    Navigator.pop(context);
  }
}
