import { randomBytes } from 'node:crypto';

import {
  generateAuthenticationOptions,
  generateRegistrationOptions,
  verifyAuthenticationResponse,
  verifyRegistrationResponse,
  type AuthenticationResponseJSON,
  type AuthenticatorTransportFuture,
  type RegistrationResponseJSON,
} from '@simplewebauthn/server';
import express, { type NextFunction, type Request, type Response } from 'express';

import type { Config } from './config.js';
import { gameModes, type GameMode, type Store, type User } from './store.js';

const challengeTtlMs = 5 * 60 * 1000;
const usernamePattern = /^[A-Za-z0-9_.-]{3,32}$/;

interface PendingChallenge {
  challenge: string;
  expiresAt: number;
  /** Set for registrations: the user handle and name the options were issued for. */
  user?: { id: string; username: string };
}

class HttpError extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message);
  }
}

const newToken = () => randomBytes(32).toString('base64url');

function profile(user: User) {
  return { username: user.username, best: user.best };
}

/**
 * The relying-party server: passkey registration/sign-in plus best-record
 * storage for signed-in players, and the `.well-known` association files
 * iOS/Android need before they'll use passkeys for [Config.rpId].
 */
export function createApp(config: Config, store: Store) {
  const app = express();
  app.use(express.json());

  // Challenges are keyed by the challenge string itself; the client echoes it
  // back inside clientDataJSON, so no cookie/session is needed to find it.
  const pending = new Map<string, PendingChallenge>();

  const remember = (entry: Omit<PendingChallenge, 'expiresAt'>) => {
    const now = Date.now();
    for (const [key, value] of pending) if (value.expiresAt < now) pending.delete(key);
    pending.set(entry.challenge, { ...entry, expiresAt: now + challengeTtlMs });
  };

  const takeChallenge = (clientDataJSON: string): PendingChallenge => {
    let challenge: string;
    try {
      challenge = JSON.parse(Buffer.from(clientDataJSON, 'base64url').toString('utf8')).challenge;
    } catch {
      throw new HttpError(400, 'Malformed clientDataJSON');
    }
    const entry = pending.get(challenge);
    pending.delete(challenge);
    if (!entry || entry.expiresAt < Date.now()) throw new HttpError(400, 'Unknown or expired challenge');
    return entry;
  };

  const requireUser = (req: Request): { user: User; token: string } => {
    const token = req.header('authorization')?.match(/^Bearer (.+)$/)?.[1];
    const user = token ? store.userForToken(token) : undefined;
    if (!token || !user) throw new HttpError(401, 'Not signed in');
    return { user, token };
  };

  app.get('/.well-known/apple-app-site-association', (_req, res) => {
    res.type('application/json').send(
      JSON.stringify({
        webcredentials: { apps: [`${config.appleTeamId}.${config.iosBundleId}`] },
      }),
    );
  });

  app.get('/.well-known/assetlinks.json', (_req, res) => {
    res.json([
      {
        relation: [
          'delegate_permission/common.handle_all_urls',
          'delegate_permission/common.get_login_creds',
        ],
        target: {
          namespace: 'android_app',
          package_name: config.androidPackage,
          sha256_cert_fingerprints: config.androidCertSha256,
        },
      },
    ]);
  });

  app.post('/auth/register/options', async (req, res) => {
    const username = req.body?.username;
    if (typeof username !== 'string' || !usernamePattern.test(username)) {
      throw new HttpError(400, 'Username must be 3-32 characters of letters, digits, _ . -');
    }
    if (store.findByUsername(username)) throw new HttpError(409, 'Username already taken');

    const userId = randomBytes(16);
    const options = await generateRegistrationOptions({
      rpName: config.rpName,
      rpID: config.rpId,
      userName: username,
      userDisplayName: username,
      userID: userId,
      attestationType: 'none',
      authenticatorSelection: { residentKey: 'required', userVerification: 'preferred' },
    });
    remember({ challenge: options.challenge, user: { id: options.user.id, username } });
    res.json(options);
  });

  app.post('/auth/register/verify', async (req, res) => {
    const response = req.body?.response as RegistrationResponseJSON | undefined;
    if (!response?.response?.clientDataJSON) throw new HttpError(400, 'Missing response');
    const entry = takeChallenge(response.response.clientDataJSON);
    if (!entry.user) throw new HttpError(400, 'Challenge was not issued for registration');
    // Re-check: someone may have claimed the name between options and verify.
    if (store.findByUsername(entry.user.username)) throw new HttpError(409, 'Username already taken');

    const verification = await verifyRegistrationResponse({
      response,
      expectedChallenge: entry.challenge,
      expectedOrigin: config.expectedOrigins,
      expectedRPID: config.rpId,
      requireUserVerification: false,
    });
    if (!verification.verified || !verification.registrationInfo) {
      throw new HttpError(400, 'Registration could not be verified');
    }

    const { credential } = verification.registrationInfo;
    const user: User = {
      id: entry.user.id,
      username: entry.user.username,
      credentials: [
        {
          id: credential.id,
          publicKey: Buffer.from(credential.publicKey).toString('base64url'),
          counter: credential.counter,
          transports: credential.transports,
        },
      ],
      best: { normal: 0, easy: 0 },
    };
    store.addUser(user);
    const token = newToken();
    store.createSession(token, user.id);
    res.json({ token, ...profile(user) });
  });

  app.post('/auth/login/options', async (_req, res) => {
    const options = await generateAuthenticationOptions({
      rpID: config.rpId,
      userVerification: 'preferred',
      allowCredentials: [],
    });
    remember({ challenge: options.challenge });
    res.json(options);
  });

  app.post('/auth/login/verify', async (req, res) => {
    const response = req.body?.response as AuthenticationResponseJSON | undefined;
    if (!response?.response?.clientDataJSON) throw new HttpError(400, 'Missing response');
    const entry = takeChallenge(response.response.clientDataJSON);
    if (entry.user) throw new HttpError(400, 'Challenge was not issued for sign-in');

    const found = store.findByCredentialId(response.id);
    if (!found) throw new HttpError(404, 'Unknown passkey');

    const verification = await verifyAuthenticationResponse({
      response,
      expectedChallenge: entry.challenge,
      expectedOrigin: config.expectedOrigins,
      expectedRPID: config.rpId,
      credential: {
        id: found.credential.id,
        publicKey: new Uint8Array(Buffer.from(found.credential.publicKey, 'base64url')),
        counter: found.credential.counter,
        transports: found.credential.transports as AuthenticatorTransportFuture[] | undefined,
      },
      requireUserVerification: false,
    });
    if (!verification.verified) throw new HttpError(401, 'Sign-in could not be verified');

    store.updateCounter(found.credential, verification.authenticationInfo.newCounter);
    const token = newToken();
    store.createSession(token, found.user.id);
    res.json({ token, ...profile(found.user) });
  });

  app.post('/auth/logout', (req, res) => {
    const { token } = requireUser(req);
    store.deleteSession(token);
    res.status(204).end();
  });

  app.get('/me', (req, res) => {
    res.json(profile(requireUser(req).user));
  });

  app.post('/scores', (req, res) => {
    const { user } = requireUser(req);
    const { mode, level } = req.body ?? {};
    if (!gameModes.includes(mode) || !Number.isInteger(level) || level < 1 || level > 10) {
      throw new HttpError(400, 'Expected { mode: "normal" | "easy", level: 1-10 }');
    }
    res.json({ best: store.submitLevel(user, mode as GameMode, level) });
  });

  app.use((err: unknown, _req: Request, res: Response, _next: NextFunction) => {
    if (err instanceof HttpError) {
      res.status(err.status).json({ error: err.message });
      return;
    }
    // simplewebauthn reports origin/RP/signature mismatches by throwing, so
    // anything else is treated as a bad request rather than a server fault.
    console.error(err);
    res.status(400).json({ error: err instanceof Error ? err.message : String(err) });
  });

  return app;
}
