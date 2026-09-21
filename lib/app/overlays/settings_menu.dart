import 'package:flutter/material.dart';
import 'package:forge2d_game/game/services/app_settings.dart';
import 'package:forge2d_game/game/suika_game.dart';

const _colorSeedPresets = [
  Color(0xFF6A0DAD), // Violet (default)
  Color(0xFFFF2E9A), // Magenta
  Color(0xFF00B0FF), // Sky blue
  Color(0xFF00C853), // Green
  Color(0xFFFF6D00), // Orange
  Color(0xFFFFD600), // Yellow
];

/// Lets the player adjust sound volume, the app's accent color, and a
/// handful of gameplay-feel tunables. Opens as a peek overlay on top of the
/// current game (like the evolution guide): tapping outside dismisses it
/// without touching the game underneath.
class SettingsMenu extends StatelessWidget {
  final SuikaGame game;

  const SettingsMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final card = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Card(
        margin: EdgeInsets.zero,
        color: colorScheme.primary,
        elevation: 8,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: SizedBox(
          width: 340,
          height: 520,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48),
                    Text(
                      'SETTINGS',
                      style: textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: game.closeSettings,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                Expanded(
                  child: ValueListenableBuilder<AppSettingsState>(
                    valueListenable: game.appSettings.state,
                    builder: (context, settings, _) {
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SettingSlider(
                              label: 'Sound Volume',
                              value: settings.soundVolume,
                              min: 0,
                              max: 1,
                              onChanged: game.appSettings.setSoundVolume,
                            ),
                            _SettingSlider(
                              label: 'Gravity',
                              value: settings.worldGravity,
                              min: 5,
                              max: 40,
                              onChanged: game.appSettings.setWorldGravity,
                            ),
                            _SettingSlider(
                              label: 'Shake Strength',
                              value: settings.shakeStrength,
                              min: 0,
                              max: 30,
                              onChanged: game.appSettings.setShakeStrength,
                            ),
                            _SettingSlider(
                              label: 'Strong Shake Chance',
                              value: settings.strongShakeProbability,
                              min: 0,
                              max: 1,
                              onChanged:
                                  game.appSettings.setStrongShakeProbability,
                            ),
                            _SettingSlider(
                              label: 'Merge Effect Scale',
                              value: settings.mergeEffectScale,
                              min: 0,
                              max: 6,
                              onChanged: game.appSettings.setMergeEffectScale,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Accent Color',
                              style: textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                for (final seed in _colorSeedPresets)
                                  _ColorSwatch(
                                    color: seed,
                                    selected:
                                        seed.toARGB32() ==
                                        settings.colorSeed.toARGB32(),
                                    onTap:
                                        () =>
                                            game.appSettings.setColorSeed(seed),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Jev API Key',
                              style: textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _JevApiKeyField(
                              initialValue: settings.jevApiKey,
                              onChanged: game.appSettings.setJevApiKey,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: game.appSettings.resetToDefaults,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white),
                              ),
                              child: const Text('Reset to Defaults'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: game.closeSettings,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.55)),
          ),
        ),
        Center(child: card),
      ],
    );
  }
}

class _SettingSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SettingSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${value.toStringAsFixed(2)}',
          style: textTheme.labelLarge?.copyWith(color: Colors.white),
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.white,
            thumbColor: Colors.white,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _JevApiKeyField extends StatelessWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _JevApiKeyField({required this.initialValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'sk-...',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white54),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: selected ? 3 : 1),
        ),
        child:
            selected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
      ),
    );
  }
}
