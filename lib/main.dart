import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game.dart';

void main() {
  runApp(SafeArea(child: GameWidget.controlled(gameFactory: SuikaGame.new)));
}
