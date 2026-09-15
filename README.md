# forge2d_game
A Mini Watermelon Game made with Flutter

## 構成

- `lib/app/`: Flutter の起点、テーマ、ゲームオーバー・モード選択などのオーバーレイUI
- `lib/game/`: Forge2Dゲーム本体、コンポーネント、ゲームルール、入力処理
- `lib/game/model/`: モード・フェーズ・ボール定義・UI向けの不変状態
- `lib/game/services/`: セッションと次のボールを管理するゲームルール
- `test/game/`: ボール定義、セッション遷移、長押し連射の単体テスト

ゲームごとの可変状態は `GameSession` に閉じており、Flutter UIは読み取り専用の
`GameState` を購読します。

```text
lib/
├── main.dart
├── app/
│   ├── game_app.dart
│   ├── overlays/
│   │   ├── congratulations_menu.dart
│   │   ├── game_over_menu.dart
│   │   ├── mode_select_menu.dart
│   │   ├── new_game_button.dart
│   │   ├── next_alien.dart
│   │   └── top_controls.dart
│   └── theme/
│       └── app_theme.dart
├── game/
│   ├── suika_game.dart
│   ├── components/
│   │   ├── alien_ball.dart
│   │   ├── background.dart
│   │   ├── brick.dart
│   │   ├── debug_info.dart
│   │   ├── easy_mode_message.dart
│   │   └── ground.dart
│   ├── config/
│   │   └── game_constants.dart
│   ├── input/
│   │   └── drop_controller.dart
│   ├── model/
│   │   ├── ball_definition.dart
│   │   ├── game_mode.dart
│   │   ├── game_overlay.dart
│   │   ├── game_phase.dart
│   │   └── game_state.dart
│   └── services/
│       └── game_session.dart
└── shared/
    └── forge2d/
        └── body_component_with_user_data.dart
```
