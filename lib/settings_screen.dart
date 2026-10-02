import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  final List<Color> _accentPresets = const [
    Color(0xFF0F766E), // Teal
    Color(0xFF2563EB), // Blue
    Color(0xFF7C3AED), // Violet
    Color(0xFF059669), // Emerald
    Color(0xFFD97706), // Amber
    Color(0xFFE11D48), // Rose
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            children: [
              Text('Settings & Data',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Customize your experience and manage habit backups',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              Text('Appearance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                          SegmentedButton<ThemeMode>(
                            segments: const [
                              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                              ButtonSegment(value: ThemeMode.system, label: Text('System')),
                              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                            ],
                            selected: {state.themeMode},
                            onSelectionChanged: (val) => state.setThemeMode(val.first),
                          ),
                        ],
                      ),
                      const Divider(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Theme Accent Color', style: TextStyle(fontWeight: FontWeight.w600)),
                          Wrap(
                            spacing: 8,
                            children: _accentPresets
                                .map((c) => InkWell(
                                      onTap: () => state.setAccentColor(c),
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: c,
                                        child: state.accentColor.value == c.value
                                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                                            : null,
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                      const Divider(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('UI Corner Radius', style: TextStyle(fontWeight: FontWeight.w600)),
                          SegmentedButton<double>(
                            segments: const [
                              ButtonSegment(value: 8.0, label: Text('Crisp (8)')),
                              ButtonSegment(value: 16.0, label: Text('Smooth (16)')),
                              ButtonSegment(value: 24.0, label: Text('Soft (24)')),
                            ],
                            selected: {state.cornerRadius},
                            onSelectionChanged: (val) => state.setCornerRadius(val.first),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Preferences', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Start Week On'),
                      trailing: DropdownButton<int>(
                        value: state.weekStartDay,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: DateTime.monday, child: Text('Monday')),
                          DropdownMenuItem(value: DateTime.sunday, child: Text('Sunday')),
                        ],
                        onChanged: (v) => state.setWeekStart(v!),
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Habit Reminder Notifications'),
                      subtitle: const Text('Browser notification prompt for web reminders'),
                      value: state.notificationsEnabled,
                      onChanged: (v) => state.toggleNotifications(v),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Micro-interactions & Audio Tones'),
                      subtitle: const Text('Play subtle tone feedback on completion'),
                      value: state.soundEnabled,
                      onChanged: (v) => state.toggleSound(v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Data Management', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.dataset_outlined),
                      title: const Text('Load Demo / Sample Data'),
                      subtitle: const Text('Populates 5 habits with realistic past completion records'),
                      trailing: FilledButton.tonal(
                        onPressed: () {
                          state.loadSampleData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sample data loaded successfully')),
                          );
                        },
                        child: const Text('Load Demo'),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.download_outlined),
                      title: const Text('Export Data (JSON)'),
                      subtitle: const Text('Copy raw JSON backup to clipboard'),
                      trailing: OutlinedButton(
                        onPressed: () {
                          final json = state.exportToJson();
                          Clipboard.setData(ClipboardData(text: json));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Backup JSON copied to clipboard')),
                          );
                        },
                        child: const Text('Copy JSON'),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.upload_outlined),
                      title: const Text('Import Data (JSON)'),
                      subtitle: const Text('Restore habits from existing backup string'),
                      trailing: OutlinedButton(
                        onPressed: () => _showImportDialog(context),
                        child: const Text('Import'),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('Reset All Data', style: TextStyle(color: Colors.red)),
                      subtitle: const Text('Permanently erase all habits and completion history'),
                      trailing: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => _confirmReset(context),
                        child: const Text('Reset All'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text('HabitFlow Web • v1.0.0 • Pure Material 3',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import JSON Backup'),
        content: TextField(
          controller: textController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Paste valid HabitFlow JSON here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final ok = AppStateScope.of(context).importFromJson(textController.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Data restored successfully' : 'Invalid JSON payload'),
                ),
              );
            },
            child: const Text('Import Data'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Everything?'),
        content: const Text('This will delete all habit history. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              AppStateScope.of(context).clearAllData();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared')),
              );
            },
            child: const Text('Confirm Reset'),
          ),
        ],
      ),
    );
  }
}
