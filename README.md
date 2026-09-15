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

## TestFlight配信

iOSビルドとTestFlightへのアップロードにはmacOS/Xcodeと Apple Developer の認証情報が
必要なため、クラウドセッション上では実行できない。GitHub Actions
（`.github/workflows/testflight.yml`、`macos-14` ランナー）と fastlane
（`ios/fastlane/`）でCI配信できるように構成してあるので、以下のRepository
Secretsを登録した上で Actions タブから `Deploy to TestFlight` ワークフローを
手動実行（workflow_dispatch）する。

| Secret | 内容 |
| --- | --- |
| `ASC_KEY_ID` | App Store Connect API キーのKey ID |
| `ASC_ISSUER_ID` | App Store Connect API キーのIssuer ID |
| `ASC_KEY_CONTENT` | `.p8` キーファイルの中身をbase64エンコードした文字列（`base64 -i AuthKey_XXXX.p8 \| pbcopy`） |
| `TEAM_ID` | Apple Developer の Team ID（任意、複数チーム所属時のみ必要） |
| `APP_IDENTIFIER` | Bundle ID（任意、既定値は `com.fush1m1.forge2dgame`） |

App Store Connect API キーは developer.apple.com の
「ユーザとアクセス」→「統合」→「App Store Connect API」から発行し、
対象アプリに対して少なくとも「App Manager」ロールを付与しておくこと。
証明書・プロビジョニングプロファイルはXcodeの自動署名
（`update_code_signing_settings` + `-allowProvisioningUpdates`）で
CI実行時に取得・更新される。
