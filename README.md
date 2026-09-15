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

## 検証

```sh
flutter analyze
flutter test
```
