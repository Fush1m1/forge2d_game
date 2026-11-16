import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'app/game_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(GameApp());
}
