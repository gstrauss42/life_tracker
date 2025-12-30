import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../data/storage_initializer.dart';

/// Settings screen - app configuration, appearance, and data management.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final config = ref.watch(userConfigProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            _SectionHeader(title: 'AI Food Analysis', icon: Icons.auto_awesome),
            const SizedBox(height: 16),
            _AISection(config: config, ref: ref),
            const SizedBox(height: 32),
            _SectionHeader(title: 'Appearance', icon: Icons.palette),
            const SizedBox(height: 16),
            _AppearanceSection(ref: ref),
            const SizedBox(height: 32),
            _SectionHeader(title: 'Data Management', icon: Icons.storage),
            const SizedBox(height: 16),
            _DataSection(ref: ref),
            const SizedBox(height: 32),
            _SectionHeader(title: 'About', icon: Icons.info_outline),
            const SizedBox(height: 16),
            _buildAboutSection(context),
          ],
        ),
      ),
    );
  }

  static Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Settings', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          'App configuration and preferences',
          style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      ],
    );
  }

  static Widget _buildAboutSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.favorite, color: colorScheme.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Life Tracker', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _AISection extends StatelessWidget {
  const _AISection({required this.config, required this.ref});

  final dynamic config;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasApiKey = config.aiApiKey != null && config.aiApiKey!.isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.key, color: colorScheme.primary, size: 20),
              ),
              title: const Text('API Key'),
              subtitle: Text(
                hasApiKey ? '••••••••${config.aiApiKey!.substring(config.aiApiKey!.length - 4)}' : 'Not configured',
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
              trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
              onTap: () => _showApiKeyDialog(context),
            ),
            Divider(height: 1, indent: 56, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.smart_toy, color: colorScheme.primary, size: 20),
              ),
              title: const Text('AI Provider'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getProviderName(config.aiProvider),
                    style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                ],
              ),
              onTap: () => _showProviderDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  String _getProviderName(String provider) {
    switch (provider) {
      case 'openai':
        return 'OpenAI';
      case 'anthropic':
        return 'Anthropic';
      case 'deepseek':
        return 'DeepSeek';
      default:
        return provider;
    }
  }

  void _showApiKeyDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Key'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onSubmitted: (value) {
            if (value.isNotEmpty) ref.read(userConfigProvider.notifier).setAiApiKey(value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) ref.read(userConfigProvider.notifier).setAiApiKey(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showProviderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select AI Provider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ProviderOption(
              name: 'OpenAI',
              subtitle: 'GPT-4o Mini',
              value: 'openai',
              current: config.aiProvider,
              onTap: () {
                ref.read(userConfigProvider.notifier).setAiProvider('openai');
                Navigator.pop(context);
              },
            ),
            _ProviderOption(
              name: 'Anthropic',
              subtitle: 'Claude 3 Haiku',
              value: 'anthropic',
              current: config.aiProvider,
              onTap: () {
                ref.read(userConfigProvider.notifier).setAiProvider('anthropic');
                Navigator.pop(context);
              },
            ),
            _ProviderOption(
              name: 'DeepSeek',
              subtitle: 'DeepSeek Chat (Most affordable)',
              value: 'deepseek',
              current: config.aiProvider,
              onTap: () {
                ref.read(userConfigProvider.notifier).setAiProvider('deepseek');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderOption extends StatelessWidget {
  const _ProviderOption({
    required this.name,
    required this.subtitle,
    required this.value,
    required this.current,
    required this.onTap,
  });

  final String name;
  final String subtitle;
  final String value;
  final String current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        current == value ? Icons.radio_button_checked : Icons.radio_button_off,
        color: colorScheme.primary,
      ),
      title: Text(name),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: colorScheme.primary, size: 20),
          ),
          title: const Text('Theme'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isDark ? 'Dark' : 'Light', style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7))),
              const SizedBox(width: 8),
              Switch(value: isDark, onChanged: (value) => ref.read(themeModeProvider.notifier).setThemeMode(value ? ThemeMode.dark : ThemeMode.light)),
            ],
          ),
          onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(),
        ),
      ),
    );
  }
}

class _DataSection extends StatelessWidget {
  const _DataSection({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.download, color: colorScheme.primary, size: 20),
              ),
              title: const Text('Export Data'),
              subtitle: Text(
                'Download your tracking history',
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export feature coming soon!')));
              },
            ),
            Divider(height: 1, indent: 56, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              ),
              title: const Text('Clear All Data'),
              subtitle: Text(
                'This action cannot be undone',
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
              onTap: () => _showClearDataDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text('This will permanently delete all your tracking history and settings. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await StorageInitializer.clearAll();
              ref.read(userConfigProvider.notifier).load();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data cleared')));
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
