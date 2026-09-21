import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/game_constants.dart' as defaults;

/// Snapshot of user-adjustable app/game settings.
class AppSettingsState {
  const AppSettingsState({
    required this.soundVolume,
    required this.colorSeed,
    required this.worldGravity,
    required this.shakeStrength,
    required this.strongShakeProbability,
    required this.mergeEffectScale,
    required this.jevAuthenticated,
  });

  factory AppSettingsState.defaults() => const AppSettingsState(
    soundVolume: 1,
    colorSeed: Color(0xFF6A0DAD),
    worldGravity: defaults.worldGravity,
    shakeStrength: defaults.shakeMaxHorizontalVelocity,
    strongShakeProbability: defaults.strongShakeProbability,
    mergeEffectScale: defaults.mergeBurstScaleBoost,
    jevAuthenticated: false,
  );

  final double soundVolume;
  final Color colorSeed;
  final double worldGravity;
  final double shakeStrength;
  final double strongShakeProbability;
  final double mergeEffectScale;
  final bool jevAuthenticated;

  AppSettingsState copyWith({
    double? soundVolume,
    Color? colorSeed,
    double? worldGravity,
    double? shakeStrength,
    double? strongShakeProbability,
    double? mergeEffectScale,
    bool? jevAuthenticated,
  }) {
    return AppSettingsState(
      soundVolume: soundVolume ?? this.soundVolume,
      colorSeed: colorSeed ?? this.colorSeed,
      worldGravity: worldGravity ?? this.worldGravity,
      shakeStrength: shakeStrength ?? this.shakeStrength,
      strongShakeProbability:
          strongShakeProbability ?? this.strongShakeProbability,
      mergeEffectScale: mergeEffectScale ?? this.mergeEffectScale,
      jevAuthenticated: jevAuthenticated ?? this.jevAuthenticated,
    );
  }
}

/// Persists user-adjustable settings (sound volume, theme color seed, and a
/// handful of gameplay-feel tunables) to device storage via
/// [SharedPreferences]. Starts with defaults from [defaults] and swaps in the
/// saved values once the async load completes.
class AppSettings {
  AppSettings() : state = ValueNotifier(AppSettingsState.defaults()) {
    ready = _load();
  }

  static const _keySoundVolume = 'settings.soundVolume';
  static const _keyColorSeed = 'settings.colorSeed';
  static const _keyWorldGravity = 'settings.worldGravity';
  static const _keyShakeStrength = 'settings.shakeStrength';
  static const _keyStrongShakeProbability = 'settings.strongShakeProbability';
  static const _keyMergeEffectScale = 'settings.mergeEffectScale';
  static const _keyJevAuthenticated = 'settings.jevAuthenticated';

  final ValueNotifier<AppSettingsState> state;

  /// Resolves once the persisted values have been loaded and applied to
  /// [state]. The constructor kicks the load off without awaiting it (so
  /// callers get a usable instance with defaults immediately); await this
  /// where the load must have settled first, e.g. in tests that construct a
  /// second [AppSettings] right after writing a value with a first one.
  late final Future<void> ready;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final current = state.value;
    state.value = current.copyWith(
      soundVolume: prefs.getDouble(_keySoundVolume),
      colorSeed:
          prefs.containsKey(_keyColorSeed)
              ? Color(prefs.getInt(_keyColorSeed)!)
              : null,
      worldGravity: prefs.getDouble(_keyWorldGravity),
      shakeStrength: prefs.getDouble(_keyShakeStrength),
      strongShakeProbability: prefs.getDouble(_keyStrongShakeProbability),
      mergeEffectScale: prefs.getDouble(_keyMergeEffectScale),
      jevAuthenticated: prefs.getBool(_keyJevAuthenticated),
    );
  }

  Future<void> setSoundVolume(double value) async {
    state.value = state.value.copyWith(soundVolume: value);
    (await SharedPreferences.getInstance()).setDouble(_keySoundVolume, value);
  }

  Future<void> setColorSeed(Color value) async {
    state.value = state.value.copyWith(colorSeed: value);
    (await SharedPreferences.getInstance()).setInt(
      _keyColorSeed,
      value.toARGB32(),
    );
  }

  Future<void> setWorldGravity(double value) async {
    state.value = state.value.copyWith(worldGravity: value);
    (await SharedPreferences.getInstance()).setDouble(_keyWorldGravity, value);
  }

  Future<void> setShakeStrength(double value) async {
    state.value = state.value.copyWith(shakeStrength: value);
    (await SharedPreferences.getInstance()).setDouble(_keyShakeStrength, value);
  }

  Future<void> setStrongShakeProbability(double value) async {
    state.value = state.value.copyWith(strongShakeProbability: value);
    (await SharedPreferences.getInstance()).setDouble(
      _keyStrongShakeProbability,
      value,
    );
  }

  Future<void> setMergeEffectScale(double value) async {
    state.value = state.value.copyWith(mergeEffectScale: value);
    (await SharedPreferences.getInstance()).setDouble(
      _keyMergeEffectScale,
      value,
    );
  }

  Future<void> setJevAuthenticated(bool value) async {
    state.value = state.value.copyWith(jevAuthenticated: value);
    (await SharedPreferences.getInstance()).setBool(
      _keyJevAuthenticated,
      value,
    );
  }

  Future<void> resetToDefaults() async {
    state.value = AppSettingsState.defaults();
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_keySoundVolume),
      prefs.remove(_keyColorSeed),
      prefs.remove(_keyWorldGravity),
      prefs.remove(_keyShakeStrength),
      prefs.remove(_keyStrongShakeProbability),
      prefs.remove(_keyMergeEffectScale),
      prefs.remove(_keyJevAuthenticated),
    ]);
  }

  void dispose() => state.dispose();
}
