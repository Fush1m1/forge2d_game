import request from 'supertest';
import { beforeEach, describe, expect, it, vi } from 'vitest';

vi.mock('@simplewebauthn/server', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@simplewebauthn/server')>();
  return {
    ...actual,
    verifyRegistrationResponse: vi.fn(),
    verifyAuthenticationResponse: vi.fn(),
  };
});

import { verifyAuthenticationResponse, verifyRegistrationResponse } from '@simplewebauthn/server';

import { createApp } from '../src/app.js';
import { androidOrigin, buildConfig } from '../src/config.js';
import { Store } from '../src/store.js';

const config = buildConfig({
  RP_ID: 'game.example.com',
  ANDROID_CERT_SHA256: 'AA:BB:CC',
});

const clientData = (challenge: string) =>
  Buffer.from(JSON.stringify({ challenge })).toString('base64url');

let app: ReturnType<typeof createApp>;

beforeEach(() => {
  vi.mocked(verifyRegistrationResponse).mockReset();
  vi.mocked(verifyAuthenticationResponse).mockReset();
  app = createApp(config, new Store());
});

async function register(username: string, credentialId = `cred-${username}`) {
  const options = await request(app).post('/auth/register/options').send({ username });
  expect(options.status).toBe(200);
  vi.mocked(verifyRegistrationResponse).mockResolvedValueOnce({
    verified: true,
    registrationInfo: {
      credential: { id: credentialId, publicKey: new Uint8Array([1, 2, 3]), counter: 0 },
    },
  } as never);
  return request(app)
    .post('/auth/register/verify')
    .send({
      response: { id: credentialId, response: { clientDataJSON: clientData(options.body.challenge) } },
    });
}

describe('config', () => {
  it('derives the android apk-key-hash origin from the cert fingerprint', () => {
    expect(androidOrigin('AA:BB:CC')).toBe('android:apk-key-hash:qrvM');
    expect(config.expectedOrigins).toEqual(['https://game.example.com', 'android:apk-key-hash:qrvM']);
  });
});

describe('well-known files', () => {
  it('serves the apple-app-site-association webcredentials entry', async () => {
    const res = await request(app).get('/.well-known/apple-app-site-association');
    expect(res.headers['content-type']).toMatch(/application\/json/);
    expect(JSON.parse(res.text)).toEqual({
      webcredentials: { apps: ['M9A89S749A.com.fush1m1.forge2dgame'] },
    });
  });

  it('serves assetlinks.json with get_login_creds', async () => {
    const res = await request(app).get('/.well-known/assetlinks.json');
    expect(res.body[0].relation).toContain('delegate_permission/common.get_login_creds');
    expect(res.body[0].target.sha256_cert_fingerprints).toEqual(['AA:BB:CC']);
  });
});

describe('registration', () => {
  it('issues resident-key options for the configured RP', async () => {
    const res = await request(app).post('/auth/register/options').send({ username: 'alice' });
    expect(res.body.rp.id).toBe('game.example.com');
    expect(res.body.user.name).toBe('alice');
    expect(res.body.authenticatorSelection.residentKey).toBe('required');
  });

  it('rejects invalid usernames', async () => {
    const res = await request(app).post('/auth/register/options').send({ username: 'a' });
    expect(res.status).toBe(400);
  });

  it('registers a user and returns a session token', async () => {
    const res = await register('alice');
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ username: 'alice', best: { normal: 0, easy: 0 } });
    expect(res.body.token).toEqual(expect.any(String));
    expect(vi.mocked(verifyRegistrationResponse).mock.calls[0][0]).toMatchObject({
      expectedRPID: 'game.example.com',
      expectedOrigin: config.expectedOrigins,
    });
  });

  it('rejects a taken username', async () => {
    await register('alice');
    const res = await request(app).post('/auth/register/options').send({ username: 'alice' });
    expect(res.status).toBe(409);
  });

  it('rejects an unknown challenge', async () => {
    const res = await request(app)
      .post('/auth/register/verify')
      .send({ response: { id: 'x', response: { clientDataJSON: clientData('nope') } } });
    expect(res.status).toBe(400);
  });
});

describe('sign-in', () => {
  async function signIn(credentialId: string, verified = true) {
    const options = await request(app).post('/auth/login/options').send({});
    expect(options.body.allowCredentials).toEqual([]);
    vi.mocked(verifyAuthenticationResponse).mockResolvedValueOnce({
      verified,
      authenticationInfo: { newCounter: 5 },
    } as never);
    return request(app)
      .post('/auth/login/verify')
      .send({
        response: { id: credentialId, response: { clientDataJSON: clientData(options.body.challenge) } },
      });
  }

  it('signs in with a registered passkey', async () => {
    await register('alice', 'cred-1');
    const res = await signIn('cred-1');
    expect(res.status).toBe(200);
    expect(res.body.username).toBe('alice');
    expect(vi.mocked(verifyAuthenticationResponse).mock.calls[0][0].credential).toMatchObject({
      id: 'cred-1',
      publicKey: new Uint8Array([1, 2, 3]),
    });
  });

  it('rejects an unknown passkey', async () => {
    const res = await signIn('cred-unknown');
    expect(res.status).toBe(404);
  });

  it('rejects a failed verification', async () => {
    await register('alice', 'cred-1');
    const res = await signIn('cred-1', false);
    expect(res.status).toBe(401);
  });
});

describe('session and scores', () => {
  it('requires a valid token', async () => {
    expect((await request(app).get('/me')).status).toBe(401);
    expect((await request(app).get('/me').set('Authorization', 'Bearer bogus')).status).toBe(401);
  });

  it('keeps the highest level per mode', async () => {
    const { token } = (await register('alice')).body;
    const auth = { Authorization: `Bearer ${token}` };

    await request(app).post('/scores').set(auth).send({ mode: 'normal', level: 6 });
    const lower = await request(app).post('/scores').set(auth).send({ mode: 'normal', level: 3 });
    expect(lower.body.best).toEqual({ normal: 6, easy: 0 });

    await request(app).post('/scores').set(auth).send({ mode: 'easy', level: 8 });
    const me = await request(app).get('/me').set(auth);
    expect(me.body).toEqual({ username: 'alice', best: { normal: 6, easy: 8 } });
  });

  it('rejects malformed scores', async () => {
    const { token } = (await register('alice')).body;
    const res = await request(app)
      .post('/scores')
      .set('Authorization', `Bearer ${token}`)
      .send({ mode: 'hard', level: 11 });
    expect(res.status).toBe(400);
  });

  it('invalidates the token on logout', async () => {
    const { token } = (await register('alice')).body;
    const auth = { Authorization: `Bearer ${token}` };
    expect((await request(app).post('/auth/logout').set(auth)).status).toBe(204);
    expect((await request(app).get('/me').set(auth)).status).toBe(401);
  });
});
