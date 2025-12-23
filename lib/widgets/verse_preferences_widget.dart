import 'package:flutter/material.dart';
import '../services/unified_verse_service.dart';
import '../core/services/database_service.dart';
import '../core/services/bible_config.dart';
import '../theme/app_theme.dart';
import '../core/widgets/app_snackbar.dart';

class VersePreferencesWidget extends StatefulWidget {
  const VersePreferencesWidget({super.key});

  @override
  State<VersePreferencesWidget> createState() => _VersePreferencesWidgetState();
}

class _VersePreferencesWidgetState extends State<VersePreferencesWidget> {
  late UnifiedVerseService _verseService;
  List<String> _selectedThemes = [];
  int _avoidRecentDays = 30;
  String _preferredVersion = 'WEB';
  bool _isLoading = true;

  final List<String> _availableThemes = [
    'faith',
    'hope',
    'love',
    'peace',
    'strength',
    'comfort',
    'guidance',
    'wisdom',
    'forgiveness',
    'joy',
    'courage',
    'patience',
  ];

  // Get available versions from centralized configuration
  final List<String> _availableVersions = BibleConfig.availableVersions;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _verseService = UnifiedVerseService();
    await _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseService().database;
      final prefs = await db.query('verse_preferences');

      for (final pref in prefs) {
        final key = pref['preference_key'] as String;
        final value = pref['preference_value'] as String;

        switch (key) {
          case 'preferred_themes':
            _selectedThemes = value.split(',');
            break;
          case 'avoid_recent_days':
            _avoidRecentDays = int.tryParse(value) ?? 30;
            break;
          case 'preferred_version':
            _preferredVersion = value;
            break;
        }
      }
    } catch (e, stack) {
      debugPrint('Failed to load verse preferences: $e');
      debugPrintStack(stackTrace: stack);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveThemes() async {
    try {
      await _verseService.updatePreferredThemes(_selectedThemes);
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Theme preferences saved');
    } catch (e, stack) {
      debugPrint('Failed to save theme preferences: $e');
      debugPrintStack(stackTrace: stack);
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        message: 'Could not save theme preferences. Please try again.',
      );
    }
  }

  Future<void> _saveAvoidRecentDays() async {
    try {
      await _verseService.updateAvoidRecentDays(_avoidRecentDays);
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Avoid recent days preference saved');
    } catch (e, stack) {
      debugPrint('Failed to save avoid recent days preference: $e');
      debugPrintStack(stackTrace: stack);
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        message: 'Could not save preference. Please try again.',
      );
    }
  }

  Future<void> _savePreferredVersion() async {
    try {
      await _verseService.updatePreferredVersion(_preferredVersion);
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Bible version preference saved');
    } catch (e, stack) {
      debugPrint('Failed to save Bible version preference: $e');
      debugPrintStack(stackTrace: stack);
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        message: 'Could not save preference. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
          strokeWidth: 3,
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Daily Verse Preferences',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Customize your daily verse experience',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            // Preferred Themes
            _buildSectionHeader('Preferred Themes'),
            const SizedBox(height: 12),
            Text(
              'Select themes you\'d like to see in your daily verses',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            _buildThemeSelector(),
            const SizedBox(height: 32),

            // Bible Version
            _buildSectionHeader('Bible Version'),
            const SizedBox(height: 12),
            _buildVersionSelector(),
            const SizedBox(height: 32),

            // Avoid Recent Verses
            _buildSectionHeader('Variety Settings'),
            const SizedBox(height: 12),
            Text(
              'Avoid showing the same verse within this many days',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            _buildAvoidRecentDaysSlider(),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _saveThemes();
                  await _savePreferredVersion();
                  await _saveAvoidRecentDays();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mediumRadius,
                  ),
                ),
                child: const Text(
                  'Save All Preferences',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.goldColor,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableThemes.map((theme) {
        final isSelected = _selectedThemes.contains(theme);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedThemes.remove(theme);
              } else {
                _selectedThemes.add(theme);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        AppTheme.goldColor.withValues(alpha: 0.4),
                        AppTheme.goldColor.withValues(alpha: 0.2),
                      ],
                    )
                  : null,
              color: isSelected ? null : Colors.white.withValues(alpha: 0.1),
              borderRadius: AppRadius.cardRadius,
              border: Border.all(
                color: isSelected
                    ? AppTheme.goldColor
                    : Colors.white.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.goldColor,
                    size: 16,
                  ),
                if (isSelected) const SizedBox(width: 6),
                Text(
                  _capitalizeFirst(theme),
                  style: TextStyle(
                    color: isSelected ? AppTheme.goldColor : Colors.white,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVersionSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: AppRadius.mediumRadius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _preferredVersion,
          isExpanded: true,
          dropdownColor: const Color(0xFF121212), // Dark background color
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          icon: const Icon(Icons.arrow_drop_down, color: AppTheme.goldColor),
          items: _availableVersions.map((version) {
            return DropdownMenuItem(
              value: version,
              child: Text(version),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _preferredVersion = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildAvoidRecentDaysSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$_avoidRecentDays days',
              style: const TextStyle(
                color: AppTheme.goldColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              _getVarietyDescription(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.goldColor,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
            thumbColor: AppTheme.goldColor,
            overlayColor: AppTheme.goldColor.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: _avoidRecentDays.toDouble(),
            min: 7,
            max: 90,
            divisions: 83,
            onChanged: (value) {
              setState(() {
                _avoidRecentDays = value.toInt();
              });
            },
          ),
        ),
      ],
    );
  }

  String _getVarietyDescription() {
    if (_avoidRecentDays <= 14) {
      return 'More repetition';
    } else if (_avoidRecentDays <= 30) {
      return 'Balanced';
    } else if (_avoidRecentDays <= 60) {
      return 'Good variety';
    } else {
      return 'Maximum variety';
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
