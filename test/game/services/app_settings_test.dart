import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge2d_game/game/services/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts with default values before the async load completes', () {
    final settings = AppSettings();
    addTearDown(settings.dispose);

    final defaults = AppSettingsState.defaults();
    expect(settings.state.value.soundVolume, defaults.soundVolume);
    expect(settings.state.value.colorSeed, defaults.colorSeed);
    expect(settings.state.value.worldGravity, defaults.worldGravity);
  });

  test('persists a changed value across a new AppSettings instance', () async {
    final settings = AppSettings();
    addTearDown(settings.dispose);
    await settings.ready;

    await settings.setSoundVolume(0.4);
    await settings.setColorSeed(const Color(0xFF00C853));
    await settings.setWorldGravity(25);

    final reloaded = AppSettings();
    addTearDown(reloaded.dispose);
    await reloaded.ready;

    expect(reloaded.state.value.soundVolume, 0.4);
    expect(reloaded.state.value.colorSeed, const Color(0xFF00C853));
    expect(reloaded.state.value.worldGravity, 25);
  });

  test('resetToDefaults clears persisted values', () async {
    final settings = AppSettings();
    addTearDown(settings.dispose);
    await settings.ready;

    await settings.setSoundVolume(0.1);
    await settings.resetToDefaults();

    expect(
      settings.state.value.soundVolume,
      AppSettingsState.defaults().soundVolume,
    );

    final reloaded = AppSettings();
    addTearDown(reloaded.dispose);
    await reloaded.ready;

    expect(
      reloaded.state.value.soundVolume,
      AppSettingsState.defaults().soundVolume,
    );
  });

  test('persists the Jev API key across a new AppSettings instance', () async {
    final settings = AppSettings();
    addTearDown(settings.dispose);
    await settings.ready;

    expect(settings.state.value.jevApiKey, '');
    await settings.setJevApiKey('test-key-123');

    final reloaded = AppSettings();
    addTearDown(reloaded.dispose);
    await reloaded.ready;

    expect(reloaded.state.value.jevApiKey, 'test-key-123');
  });
}
