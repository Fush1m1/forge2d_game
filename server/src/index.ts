import { createApp } from './app.js';
import { buildConfig } from './config.js';
import { Store } from './store.js';

const config = buildConfig(process.env);
const app = createApp(config, new Store(config.dataFile));

app.listen(config.port, () => {
  console.log(`Passkey server listening on :${config.port}`);
  console.log(`  RP ID:            ${config.rpId}`);
  console.log(`  Expected origins: ${config.expectedOrigins.join(', ')}`);
});
