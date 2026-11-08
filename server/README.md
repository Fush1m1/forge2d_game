# Passkey server (local)

A WebAuthn relying-party server for the game's passkey accounts. It handles registration, sign-in, and storing each player's best level per mode, and it serves the iOS/Android association files.
Node + Express + `@simplewebauthn/server`. Data is stored in `server/data/db.json`.

## Why an HTTPS tunnel is needed

On iOS and Android, a passkey works only for a domain whose `.well-known` files associate it with the app.
`localhost` can't be used, so the local server is exposed through a tunnel with a **fixed domain**.
The RP ID is that domain, so if the domain changes, existing passkeys stop working. Don't use a quick tunnel that gets a new URL on every run.

## Setup

```sh
cd server
npm install
npm test
```

### 1. Start the tunnel (ngrok's free static domain)

```sh
ngrok http 8080 --url your-name.ngrok-free.app
```

### 2. Start the server

```sh
RP_ID=your-name.ngrok-free.app \
ANDROID_CERT_SHA256="AA:BB:..." \
npm run dev
```

| Variable | Default | Purpose |
| --- | --- | --- |
| `RP_ID` | `localhost` | Tunnel domain (the RP ID) |
| `PORT` | `8080` | Port to listen on |
| `APPLE_TEAM_ID` | `M9A89S749A` | Used in the AASA `webcredentials` entry |
| `IOS_BUNDLE_ID` | `com.fush1m1.forge2dgame` | Same as above |
| `ANDROID_PACKAGE` | `com.fush1m1.forge2dgame` | Used in assetlinks.json |
| `ANDROID_CERT_SHA256` | (none) | SHA-256 of the signing certificate, comma-separated. Also used to build the expected Android origin (`android:apk-key-hash:`) |
| `DATA_FILE` | `server/data/db.json` | Where data is stored |

Get the Android debug-signing SHA-256 with:

```sh
cd android && ./gradlew signingReport   # SHA-256 for Variant: debug
```

Check: `curl https://your-name.ngrok-free.app/.well-known/apple-app-site-association`

### 3. iOS setup

1. `cp ios/Flutter/Passkey.xcconfig.example ios/Flutter/Passkey.xcconfig` and set `PASSKEY_RP_ID` to the tunnel domain.
   (Only the Debug build gets the Associated Domains entitlement, from `ios/Runner/RunnerDebug.entitlements`. Release builds are unchanged.)
2. In Xcode, check that Signing & Capabilities shows Associated Domains. Automatic signing adds it to the App ID.
3. On the device, turn on Settings > Privacy & Security > Developer Mode. This lets `?mode=developer` fetch the AASA file straight from the server instead of Apple's CDN.

### 4. Run the app

```sh
flutter run --dart-define=PASSKEY_SERVER_URL=https://your-name.ngrok-free.app
```

Open Settings → **Passkey Account** to create a passkey or sign in. After that, your best level is sent when a round ends (game over or level 10 reached).
If you build without `PASSKEY_SERVER_URL`, the account screen shows a notice that the feature is turned off.

## API

| Method | Path | Body / Response |
| --- | --- | --- |
| POST | `/auth/register/options` | `{username}` → PublicKeyCredentialCreationOptionsJSON |
| POST | `/auth/register/verify` | `{username, response}` → `{token, username, best}` |
| POST | `/auth/login/options` | → PublicKeyCredentialRequestOptionsJSON (discoverable) |
| POST | `/auth/login/verify` | `{response}` → `{token, username, best}` |
| POST | `/auth/logout` | Bearer → 204 |
| GET | `/me` | Bearer → `{username, best: {normal, easy}}` |
| POST | `/scores` | Bearer, `{mode, level}` → `{best}` (keeps the highest value) |
