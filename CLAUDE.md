# forge2d_game

Flutter + Flame + Forge2D (`flame_forge2d`) で作られたスイカゲーム風の物理パズルゲーム。
SDK: Dart `^3.7.2` / Flutter (stable)。

## セットアップ

```
flutter pub get
```

## よく使うコマンド

```
flutter analyze          # 静的解析
flutter test              # test/ 配下のユニットテスト実行
dart format .              # フォーマット
flutter run                # 実機/エミュレータが必要（クラウドサンドボックスでは不可）
```

クラウド上のセッション（claude.ai/code 等）にはデバイス/エミュレータが無いため、
`flutter run` によるアプリの目視確認はできない。挙動確認は `flutter test` と
`flutter analyze` で行い、実機確認はローカル環境でブランチを pull して行うこと。

## 構成

詳細は `README.md` の構成図を参照。

- `lib/app/`: Flutter の起点、テーマ、オーバーレイUI
- `lib/game/`: Forge2Dゲーム本体、コンポーネント、ルール、入力処理
- `lib/game/model/`: モード・フェーズ・ボール定義などの不変状態
- `lib/game/services/`: `GameSession` (可変状態はここに閉じる)
- `test/game/`: ユニットテスト

UIは `GameSession` が持つ可変状態を、読み取り専用の `GameState` として購読する設計。
