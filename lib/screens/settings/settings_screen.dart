import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../models/exercise_models.dart';
import '../../providers/providers.dart';
import '../../providers/navigation_provider.dart';
import '../../data/storage_initializer.dart';

/// Check if GPS location is supported on this platform
bool get _isGpsSupported {
  if (kIsWeb) return true; // Web has geolocation API
  // Mobile platforms support GPS
  return Platform.isAndroid || Platform.isIOS;
}

/// Settings screen - configure goals, preferences, and AI settings.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _scrollController = ScrollController();
  final _exercisePreferencesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Check if we need to scroll to a section after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollTarget();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkScrollTarget() {
    final target = ref.read(settingsScrollTargetProvider);
    if (target == SettingsSections.exercisePreferences) {
      // Clear the target
      ref.read(settingsScrollTargetProvider.notifier).state = null;
      // Scroll to exercise preferences section
      _scrollToExercisePreferences();
    }
  }

  void _scrollToExercisePreferences() {
    final context = _exercisePreferencesKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        alignment: 0.1, // Scroll so section is near top with some padding
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final config = ref.watch(userConfigProvider);
    
    // Watch for scroll target changes (in case we navigate here while already on screen)
    ref.listen(settingsScrollTargetProvider, (previous, next) {
      if (next == SettingsSections.exercisePreferences) {
        ref.read(settingsScrollTargetProvider.notifier).state = null;
        Future.delayed(const Duration(milliseconds: 100), _scrollToExercisePreferences);
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            _SectionHeader(title: 'Location', icon: Icons.location_on),
            const SizedBox(height: 16),
            _LocationSection(config: config, ref: ref),
            const SizedBox(height: 32),
            _SectionHeader(title: 'Daily Goals', icon: Icons.flag),
            const SizedBox(height: 16),
            _GoalsSection(config: config, ref: ref),
            const SizedBox(height: 32),
            // Exercise Preferences section with key for scrolling
            Column(
              key: _exercisePreferencesKey,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(title: 'Exercise Preferences', icon: Icons.fitness_center),
                const SizedBox(height: 16),
                _ExercisePreferencesSection(config: config, ref: ref),
              ],
            ),
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

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Settings', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          'Customize your tracking experience',
          style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
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

class _LocationSection extends StatefulWidget {
  const _LocationSection({required this.config, required this.ref});

  final dynamic config;
  final WidgetRef ref;

  @override
  State<_LocationSection> createState() => _LocationSectionState();
}

class _LocationSectionState extends State<_LocationSection> {
  bool _isLoadingLocation = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasLocation = widget.config.locationCity != null;

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
                  color: const Color(0xFF26A69A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on, color: Color(0xFF26A69A), size: 20),
              ),
              title: const Text('Current Location'),
              subtitle: Text(
                hasLocation
                    ? '${widget.config.locationCity}, ${widget.config.locationCountry}'
                    : 'Not set',
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
              trailing: hasLocation
                  ? IconButton(
                      icon: Icon(Icons.clear, color: colorScheme.error.withValues(alpha: 0.7)),
                      onPressed: () => widget.ref.read(userConfigProvider.notifier).clearLocation(),
                      tooltip: 'Clear location',
                    )
                  : null,
            ),
            Divider(height: 1, indent: 56, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.edit, color: colorScheme.primary, size: 20),
              ),
              title: const Text('Set Location Manually'),
              subtitle: Text(
                'Enter your city and country',
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
              trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
              onTap: () => _showManualLocationDialog(context),
            ),
            if (_isGpsSupported) ...[
              Divider(height: 1, indent: 56, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isLoadingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, color: Colors.blue, size: 20),
                ),
                title: const Text('Use Current Location'),
                subtitle: Text(
                  'Detect location via GPS',
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
                trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                onTap: _isLoadingLocation ? null : () => _detectLocation(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showManualLocationDialog(BuildContext context) {
    final cityController = TextEditingController(text: widget.config.locationCity ?? '');
    final countryController = TextEditingController(text: widget.config.locationCountry ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                hintText: 'e.g., Cape Town',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: countryController,
              decoration: const InputDecoration(
                labelText: 'Country',
                hintText: 'e.g., South Africa',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final city = cityController.text.trim();
              final country = countryController.text.trim();
              if (city.isNotEmpty && country.isNotEmpty) {
                widget.ref.read(userConfigProvider.notifier).setLocation(
                      address: '$city, $country',
                      city: city,
                      country: country,
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Location set to $city, $country')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _detectLocation(BuildContext context) async {
    setState(() => _isLoadingLocation = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled. Please enable them in settings.')),
          );
        }
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied. Please enable in settings.')),
          );
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Reverse geocode to get address
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality ?? place.subAdministrativeArea ?? 'Unknown City';
        final country = place.country ?? 'Unknown Country';
        final address = '${place.street ?? ''}, $city, $country'.replaceFirst(RegExp(r'^, '), '');

        widget.ref.read(userConfigProvider.notifier).setLocationFromCoordinates(
              lat: position.latitude,
              lng: position.longitude,
              address: address,
              city: city,
              country: country,
            );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location detected: $city, $country')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to detect location: ${e.toString().substring(0, 50)}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }
}

class _GoalsSection extends StatelessWidget {
  const _GoalsSection({required this.config, required this.ref});

  final dynamic config;
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
            _GoalTile(
              title: 'Water Goal',
              value: '${config.waterGoalLiters} L',
              icon: Icons.water_drop,
              color: const Color(0xFF29B6F6),
              onTap: () => _showEditDialog(context, 'Water Goal (L)', config.waterGoalLiters.toString(), (v) {
                final parsed = double.tryParse(v);
                if (parsed != null && parsed > 0) ref.read(userConfigProvider.notifier).setWaterGoal(parsed);
              }),
            ),
            _buildDivider(colorScheme),
            _GoalTile(
              title: 'Exercise Goal',
              value: '${config.exerciseGoalMinutes} min',
              icon: Icons.fitness_center,
              color: const Color(0xFFEF5350),
              onTap: () => _showEditDialog(context, 'Exercise Goal (min)', config.exerciseGoalMinutes.toString(), (v) {
                final parsed = int.tryParse(v);
                if (parsed != null && parsed > 0) ref.read(userConfigProvider.notifier).setExerciseGoal(parsed);
              }),
            ),
            _buildDivider(colorScheme),
            _GoalTile(
              title: 'Sunlight Goal',
              value: '${config.sunlightGoalMinutes} min',
              icon: Icons.wb_sunny,
              color: const Color(0xFFFFB300),
              onTap: () => _showEditDialog(context, 'Sunlight Goal (min)', config.sunlightGoalMinutes.toString(), (v) {
                final parsed = int.tryParse(v);
                if (parsed != null && parsed > 0) ref.read(userConfigProvider.notifier).setSunlightGoal(parsed);
              }),
            ),
            _buildDivider(colorScheme),
            _GoalTile(
              title: 'Sleep Goal',
              value: '${config.sleepGoalHours} hrs',
              icon: Icons.bedtime,
              color: const Color(0xFF7E57C2),
              onTap: () => _showEditDialog(context, 'Sleep Goal (hrs)', config.sleepGoalHours.toString(), (v) {
                final parsed = double.tryParse(v);
                if (parsed != null && parsed > 0) ref.read(userConfigProvider.notifier).setSleepGoal(parsed);
              }),
            ),
            _buildDivider(colorScheme),
            _GoalTile(
              title: 'Social Goal',
              value: '${config.socialGoalMinutes} min',
              icon: Icons.people,
              color: const Color(0xFF26A69A),
              onTap: () => _showEditDialog(context, 'Social Goal (min)', config.socialGoalMinutes.toString(), (v) {
                final parsed = int.tryParse(v);
                if (parsed != null && parsed > 0) ref.read(userConfigProvider.notifier).setSocialGoal(parsed);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Divider(height: 1, indent: 56, color: colorScheme.outlineVariant.withValues(alpha: 0.5));
  }

  void _showEditDialog(BuildContext context, String title, String currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onSubmitted: (value) {
            onSave(value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ExercisePreferencesSection extends StatelessWidget {
  const _ExercisePreferencesSection({required this.config, required this.ref});

  final dynamic config;
  final WidgetRef ref;

  static const Color exerciseColor = Color(0xFFEF5350);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            // Fitness Goal
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: exerciseColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flag, color: exerciseColor, size: 20),
              ),
              title: const Text('Fitness Goal'),
              subtitle: Text(
                config.fitnessGoal?.displayName ?? 'Not set',
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
              trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
              onTap: () => _showFitnessGoalDialog(context),
            ),
            Divider(height: 1, indent: 56, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),

            // Fitness Level
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: exerciseColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.trending_up, color: exerciseColor, size: 20),
              ),
              title: const Text('Fitness Level'),
              subtitle: Text(
                config.fitnessLevel?.displayName ?? 'Not set',
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
              trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
              onTap: () => _showFitnessLevelDialog(context),
            ),
            Divider(height: 1, indent: 56, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),

            // Preferred Workout Duration
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: exerciseColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.timer, color: exerciseColor, size: 20),
              ),
              title: const Text('Workout Duration'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${config.preferredWorkoutDuration ?? 20} min',
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                ],
              ),
              onTap: () => _showDurationDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showFitnessGoalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Fitness Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: FitnessGoal.values.map((goal) {
            final isSelected = config.fitnessGoal == goal;
            return ListTile(
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? _ExercisePreferencesSection.exerciseColor : null,
              ),
              title: Text(goal.displayName),
              subtitle: Text(goal.description),
              onTap: () {
                ref.read(userConfigProvider.notifier).setFitnessGoal(goal);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showFitnessLevelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Fitness Level'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: FitnessLevel.values.map((level) {
            final isSelected = config.fitnessLevel == level;
            return ListTile(
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? _ExercisePreferencesSection.exerciseColor : null,
              ),
              title: Text(level.displayName),
              subtitle: Text(level.description),
              onTap: () {
                ref.read(userConfigProvider.notifier).setFitnessLevel(level);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDurationDialog(BuildContext context) {
    final durations = [10, 15, 20, 30, 45, 60];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preferred Workout Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: durations.map((duration) {
            final isSelected = (config.preferredWorkoutDuration ?? 20) == duration;
            return ListTile(
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? _ExercisePreferencesSection.exerciseColor : null,
              ),
              title: Text('$duration minutes'),
              onTap: () {
                ref.read(userConfigProvider.notifier).setPreferredWorkoutDuration(duration);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
        ],
      ),
      onTap: onTap,
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
