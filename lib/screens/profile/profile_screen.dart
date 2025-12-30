import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';

/// Check if GPS location is supported on this platform
bool get _isGpsSupported {
  if (kIsWeb) return true;
  return Platform.isAndroid || Platform.isIOS;
}

/// Profile screen - personal information, goals, and preferences.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _scrollController = ScrollController();
  final _personalInfoKey = GlobalKey();
  final _locationKey = GlobalKey();
  final _goalsKey = GlobalKey();
  final _exercisePreferencesKey = GlobalKey();
  final _healthKey = GlobalKey();
  final _dietaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
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
    final target = ref.read(profileScrollTargetProvider);
    if (target != null) {
      ref.read(profileScrollTargetProvider.notifier).state = null;
      _scrollToSection(target);
    }
  }

  void _scrollToSection(String section) {
    GlobalKey? key;
    switch (section) {
      case ProfileSections.personalInfo:
        key = _personalInfoKey;
      case ProfileSections.location:
        key = _locationKey;
      case ProfileSections.goals:
        key = _goalsKey;
      case ProfileSections.exercisePreferences:
        key = _exercisePreferencesKey;
      case ProfileSections.health:
        key = _healthKey;
      case ProfileSections.dietary:
        key = _dietaryKey;
    }
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        alignment: 0.1,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final config = ref.watch(userConfigProvider);

    ref.listen(profileScrollTargetProvider, (previous, next) {
      if (next != null) {
        ref.read(profileScrollTargetProvider.notifier).state = null;
        Future.delayed(const Duration(milliseconds: 100), () => _scrollToSection(next));
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
            _buildHeader(context, config),
            const SizedBox(height: 32),
            Column(
              key: _personalInfoKey,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(title: 'Personal Information', icon: Icons.person),
                const SizedBox(height: 16),
                _PersonalInfoSection(config: config, ref: ref),
              ],
            ),
            const SizedBox(height: 32),
            Column(
              key: _locationKey,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(title: 'Location', icon: Icons.location_on),
                const SizedBox(height: 16),
                _LocationSection(config: config, ref: ref),
              ],
            ),
            const SizedBox(height: 32),
            Column(
              key: _goalsKey,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(title: 'Daily Goals', icon: Icons.flag),
                const SizedBox(height: 16),
                _GoalsSection(config: config, ref: ref),
              ],
            ),
            const SizedBox(height: 32),
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
            Column(
              key: _healthKey,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(title: 'Health Information', icon: Icons.medical_information),
                const SizedBox(height: 16),
                _HealthSection(config: config, ref: ref),
              ],
            ),
            const SizedBox(height: 32),
            Column(
              key: _dietaryKey,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(title: 'Dietary Preferences', icon: Icons.restaurant),
                const SizedBox(height: 16),
                _DietarySection(config: config, ref: ref),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserConfig config) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: config.displayName?.isNotEmpty == true
                ? Text(
                    config.displayName![0].toUpperCase(),
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Icon(Icons.person, size: 36, color: colorScheme.primary),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.displayName?.isNotEmpty == true ? config.displayName! : 'Your Profile',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _buildSubtitle(config),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _buildSubtitle(UserConfig config) {
    final parts = <String>[];
    if (config.age != null) parts.add('${config.age} years');
    if (config.locationCity != null) parts.add(config.locationCity!);
    if (parts.isEmpty) return 'Complete your profile to personalize your experience';
    return parts.join(' • ');
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

// ============================================================================
// Personal Information Section
// ============================================================================

class _PersonalInfoSection extends StatelessWidget {
  const _PersonalInfoSection({required this.config, required this.ref});

  final UserConfig config;
  final WidgetRef ref;

  static const Color infoColor = Color(0xFF5C6BC0);

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
            // Name
            ListTile(
              leading: _buildIcon(Icons.badge, infoColor),
              title: const Text('Display Name'),
              subtitle: Text(
                config.displayName ?? 'Not set',
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
              trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
              onTap: () => _showNameDialog(context),
            ),
            _buildDivider(colorScheme),
            // Birth Date / Age
            ListTile(
              leading: _buildIcon(Icons.cake, infoColor),
              title: const Text('Birth Date'),
              subtitle: Text(
                config.birthDate != null
                    ? '${_formatDate(config.birthDate!)} (${config.age} years old)'
                    : 'Not set',
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
              trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
              onTap: () => _showDatePicker(context),
            ),
            _buildDivider(colorScheme),
            // Height
            ListTile(
              leading: _buildIcon(Icons.height, infoColor),
              title: const Text('Height'),
              subtitle: Text(
                config.heightCm != null ? '${config.heightCm!.toStringAsFixed(0)} cm' : 'Not set',
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
              trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
              onTap: () => _showHeightDialog(context),
            ),
            _buildDivider(colorScheme),
            // Weight
            ListTile(
              leading: _buildIcon(Icons.monitor_weight, infoColor),
              title: const Text('Weight'),
              subtitle: Text(
                config.weightKg != null ? '${config.weightKg!.toStringAsFixed(1)} kg' : 'Not set',
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
              trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
              onTap: () => _showWeightDialog(context),
            ),
            _buildDivider(colorScheme),
            // Biological Sex
            ListTile(
              leading: _buildIcon(Icons.wc, infoColor),
              title: const Text('Biological Sex'),
              subtitle: Text(
                config.biologicalSex?.displayName ?? 'Not set',
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
              trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
              onTap: () => _showSexDialog(context),
            ),
            _buildDivider(colorScheme),
            // Activity Level
            ListTile(
              leading: _buildIcon(Icons.directions_run, infoColor),
              title: const Text('Activity Level'),
              subtitle: Text(
                config.activityLevel?.displayName ?? 'Not set',
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
              trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
              onTap: () => _showActivityLevelDialog(context),
            ),
            // BMI display if available
            if (config.bmi != null) ...[
              _buildDivider(colorScheme),
              ListTile(
                leading: _buildIcon(Icons.analytics, _getBmiColor(config.bmi!)),
                title: const Text('BMI'),
                subtitle: Text(
                  '${config.bmi!.toStringAsFixed(1)} - ${_getBmiCategory(config.bmi!)}',
                  style: TextStyle(color: _getBmiColor(config.bmi!)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Divider(height: 1, indent: 56, color: colorScheme.outlineVariant.withValues(alpha: 0.5));
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.orange;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  String _getBmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Healthy';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  void _showNameDialog(BuildContext context) {
    final controller = TextEditingController(text: config.displayName ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Display Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              ref.read(userConfigProvider.notifier).setDisplayName(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDatePicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: config.birthDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select your birth date',
    );
    if (picked != null) {
      ref.read(userConfigProvider.notifier).setBirthDate(picked);
    }
  }

  void _showHeightDialog(BuildContext context) {
    final controller = TextEditingController(
      text: config.heightCm?.toStringAsFixed(0) ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Height (cm)'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'e.g., 175',
            border: OutlineInputBorder(),
            suffixText: 'cm',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                ref.read(userConfigProvider.notifier).setHeight(value);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showWeightDialog(BuildContext context) {
    final controller = TextEditingController(
      text: config.weightKg?.toStringAsFixed(1) ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Weight (kg)'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'e.g., 70.5',
            border: OutlineInputBorder(),
            suffixText: 'kg',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                ref.read(userConfigProvider.notifier).setWeight(value);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSexDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Biological Sex'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: BiologicalSex.values.map((sex) {
            final isSelected = config.biologicalSex == sex;
            return ListTile(
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? infoColor : null,
              ),
              title: Text(sex.displayName),
              onTap: () {
                ref.read(userConfigProvider.notifier).setBiologicalSex(sex);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showActivityLevelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activity Level'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ActivityLevel.values.map((level) {
              final isSelected = config.activityLevel == level;
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? infoColor : null,
                ),
                title: Text(level.displayName),
                subtitle: Text(level.description),
                onTap: () {
                  ref.read(userConfigProvider.notifier).setActivityLevel(level);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Location Section (moved from Settings)
// ============================================================================

class _LocationSection extends StatefulWidget {
  const _LocationSection({required this.config, required this.ref});

  final UserConfig config;
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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled. Please enable them in settings.')),
          );
        }
        return;
      }

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

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

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

// ============================================================================
// Goals Section (moved from Settings)
// ============================================================================

class _GoalsSection extends StatelessWidget {
  const _GoalsSection({required this.config, required this.ref});

  final UserConfig config;
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

// ============================================================================
// Exercise Preferences Section (moved from Settings)
// ============================================================================

class _ExercisePreferencesSection extends StatelessWidget {
  const _ExercisePreferencesSection({required this.config, required this.ref});

  final UserConfig config;
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
                color: isSelected ? exerciseColor : null,
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
                color: isSelected ? exerciseColor : null,
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
                color: isSelected ? exerciseColor : null,
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

// ============================================================================
// Health Section (new)
// ============================================================================

class _HealthSection extends StatelessWidget {
  const _HealthSection({required this.config, required this.ref});

  final UserConfig config;
  final WidgetRef ref;

  static const Color healthColor = Color(0xFFE91E63);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final conditions = config.medicalConditions ?? [];
    final allergies = config.allergies ?? [];

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
            // Medical Conditions
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: healthColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.medical_services, color: healthColor, size: 20),
              ),
              title: const Text('Medical Conditions'),
              subtitle: Text(
                conditions.isEmpty ? 'None added' : conditions.join(', '),
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
              onTap: () => _showConditionsDialog(context, conditions),
            ),
            Divider(height: 1, indent: 56, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            // Allergies
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
              ),
              title: const Text('Allergies'),
              subtitle: Text(
                allergies.isEmpty ? 'None added' : allergies.join(', '),
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
              onTap: () => _showAllergiesDialog(context, allergies),
            ),
          ],
        ),
      ),
    );
  }

  void _showConditionsDialog(BuildContext context, List<String> conditions) {
    _showListEditDialog(
      context: context,
      title: 'Medical Conditions',
      items: conditions,
      hintText: 'e.g., Diabetes, Hypertension',
      onAdd: (item) => ref.read(userConfigProvider.notifier).addMedicalCondition(item),
      onRemove: (item) => ref.read(userConfigProvider.notifier).removeMedicalCondition(item),
    );
  }

  void _showAllergiesDialog(BuildContext context, List<String> allergies) {
    _showListEditDialog(
      context: context,
      title: 'Allergies',
      items: allergies,
      hintText: 'e.g., Peanuts, Shellfish, Pollen',
      onAdd: (item) => ref.read(userConfigProvider.notifier).addAllergy(item),
      onRemove: (item) => ref.read(userConfigProvider.notifier).removeAllergy(item),
    );
  }

  void _showListEditDialog({
    required BuildContext context,
    required String title,
    required List<String> items,
    required String hintText,
    required Function(String) onAdd,
    required Function(String) onRemove,
  }) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final colorScheme = Theme.of(context).colorScheme;
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: hintText,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              onAdd(value.trim());
                              controller.clear();
                              setDialogState(() {});
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () {
                          if (controller.text.trim().isNotEmpty) {
                            onAdd(controller.text.trim());
                            controller.clear();
                            setDialogState(() {});
                          }
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No items added yet',
                        style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            title: Text(items[index]),
                            trailing: IconButton(
                              icon: Icon(Icons.close, size: 18, color: colorScheme.error),
                              onPressed: () {
                                onRemove(items[index]);
                                setDialogState(() {});
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// Dietary Section (new - includes avoided ingredients from Settings)
// ============================================================================

class _DietarySection extends StatelessWidget {
  const _DietarySection({required this.config, required this.ref});

  final UserConfig config;
  final WidgetRef ref;

  static const Color dietaryColor = Color(0xFF4CAF50);

  static const List<String> _commonRestrictions = [
    'Vegetarian',
    'Vegan',
    'Pescatarian',
    'Gluten-Free',
    'Dairy-Free',
    'Nut-Free',
    'Kosher',
    'Halal',
    'Low-Carb',
    'Keto',
    'Paleo',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final restrictions = config.dietaryRestrictions ?? [];
    final avoidedIngredients = config.avoidedIngredients ?? [];

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
            // Dietary Restrictions
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: dietaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.eco, color: dietaryColor, size: 20),
              ),
              title: const Text('Dietary Restrictions'),
              subtitle: Text(
                restrictions.isEmpty ? 'None selected' : restrictions.join(', '),
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
              onTap: () => _showRestrictionsDialog(context, restrictions),
            ),
            Divider(height: 1, indent: 56, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            // Avoided Ingredients
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.block, color: Colors.red, size: 20),
              ),
              title: const Text('Avoided Ingredients'),
              subtitle: Text(
                avoidedIngredients.isEmpty ? 'None added' : avoidedIngredients.join(', '),
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
              onTap: () => _showAvoidedIngredientsDialog(context, avoidedIngredients),
            ),
          ],
        ),
      ),
    );
  }

  void _showRestrictionsDialog(BuildContext context, List<String> currentRestrictions) {
    final selected = Set<String>.from(currentRestrictions);
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Dietary Restrictions'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _commonRestrictions.map((restriction) {
                    final isSelected = selected.contains(restriction);
                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(restriction),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) {
                        setDialogState(() {
                          if (value == true) {
                            selected.add(restriction);
                          } else {
                            selected.remove(restriction);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  ref.read(userConfigProvider.notifier).setDietaryRestrictions(selected.toList());
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAvoidedIngredientsDialog(BuildContext context, List<String> ingredients) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final colorScheme = Theme.of(context).colorScheme;
          return AlertDialog(
            title: const Text('Avoided Ingredients'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: 'e.g., Sugar, MSG, Soy',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              ref.read(userConfigProvider.notifier).addAvoidedIngredient(value.trim());
                              controller.clear();
                              setDialogState(() {});
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () {
                          if (controller.text.trim().isNotEmpty) {
                            ref.read(userConfigProvider.notifier).addAvoidedIngredient(controller.text.trim());
                            controller.clear();
                            setDialogState(() {});
                          }
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (ingredients.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No ingredients added yet',
                        style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: ingredients.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            title: Text(ingredients[index]),
                            trailing: IconButton(
                              icon: Icon(Icons.close, size: 18, color: colorScheme.error),
                              onPressed: () {
                                ref.read(userConfigProvider.notifier).removeAvoidedIngredient(ingredients[index]);
                                setDialogState(() {});
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }
}

