import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname } from 'node:path';

export type GameMode = 'normal' | 'easy';
export const gameModes: readonly GameMode[] = ['normal', 'easy'];

export interface StoredCredential {
  id: string; // base64url credential ID
  publicKey: string; // base64url COSE public key
  counter: number;
  transports?: string[];
}

export interface User {
  id: string; // base64url WebAuthn user handle
  username: string;
  credentials: StoredCredential[];
  best: Record<GameMode, number>;
}

interface Data {
  users: User[];
  sessions: Record<string, string>; // token → user id
}

/**
 * Users, credentials, sessions and best records. Kept in memory and written
 * through to a JSON file (when [file] is given) so a server restart doesn't
 * orphan passkeys already saved on devices.
 */
export class Store {
  private data: Data;

  constructor(private readonly file?: string) {
    this.data =
      file && existsSync(file)
        ? (JSON.parse(readFileSync(file, 'utf8')) as Data)
        : { users: [], sessions: {} };
  }

  findByUsername(username: string): User | undefined {
    return this.data.users.find((u) => u.username === username);
  }

  findByCredentialId(credentialId: string): { user: User; credential: StoredCredential } | undefined {
    for (const user of this.data.users) {
      const credential = user.credentials.find((c) => c.id === credentialId);
      if (credential) return { user, credential };
    }
    return undefined;
  }

  addUser(user: User): void {
    this.data.users.push(user);
    this.save();
  }

  updateCounter(credential: StoredCredential, counter: number): void {
    credential.counter = counter;
    this.save();
  }

  createSession(token: string, userId: string): void {
    this.data.sessions[token] = userId;
    this.save();
  }

  deleteSession(token: string): void {
    delete this.data.sessions[token];
    this.save();
  }

  userForToken(token: string): User | undefined {
    const userId = this.data.sessions[token];
    return userId ? this.data.users.find((u) => u.id === userId) : undefined;
  }

  /** Raises the user's best for [mode] to [level] if higher; returns the resulting bests. */
  submitLevel(user: User, mode: GameMode, level: number): Record<GameMode, number> {
    if (level > user.best[mode]) {
      user.best[mode] = level;
      this.save();
    }
    return user.best;
  }

  private save(): void {
    if (!this.file) return;
    mkdirSync(dirname(this.file), { recursive: true });
    writeFileSync(this.file, JSON.stringify(this.data, null, 2));
  }
}
