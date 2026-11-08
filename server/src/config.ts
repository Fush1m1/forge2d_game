export interface Config {
  port: number;
  rpId: string;
  rpName: string;
  appleTeamId: string;
  iosBundleId: string;
  androidPackage: string;
  /** SHA-256 signing-cert fingerprints, colon-separated hex (as printed by `gradlew signingReport`). */
  androidCertSha256: string[];
  /** Origins accepted in clientDataJSON: the web origin plus one `android:apk-key-hash:` per cert. */
  expectedOrigins: string[];
  dataFile: string;
}

/** `AB:CD:...` → base64url of the raw bytes, the form Android puts in clientDataJSON's origin. */
export function androidOrigin(sha256Fingerprint: string): string {
  const bytes = Buffer.from(sha256Fingerprint.replaceAll(':', ''), 'hex');
  return `android:apk-key-hash:${bytes.toString('base64url')}`;
}

export function buildConfig(env: NodeJS.ProcessEnv): Config {
  const rpId = env.RP_ID ?? 'localhost';
  const androidCertSha256 = (env.ANDROID_CERT_SHA256 ?? '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
  const webOrigin = rpId === 'localhost' ? `http://localhost:${env.PORT ?? 8080}` : `https://${rpId}`;
  return {
    port: Number(env.PORT ?? 8080),
    rpId,
    rpName: env.RP_NAME ?? 'Forge2D Game',
    appleTeamId: env.APPLE_TEAM_ID ?? 'M9A89S749A',
    iosBundleId: env.IOS_BUNDLE_ID ?? 'com.fush1m1.forge2dgame',
    androidPackage: env.ANDROID_PACKAGE ?? 'com.fush1m1.forge2dgame',
    androidCertSha256,
    expectedOrigins: [webOrigin, ...androidCertSha256.map(androidOrigin)],
    dataFile: env.DATA_FILE ?? new URL('../data/db.json', import.meta.url).pathname,
  };
}

