const { spawnSync } = require('node:child_process');

const args = process.argv.slice(2);
const env = { ...process.env };

if (process.platform === 'win32' && !env.DOCKER_HOST) {
  env.DOCKER_HOST = 'npipe:////./pipe/dockerDesktopLinuxEngine';
}

const command = process.platform === 'win32' ? 'supabase.cmd' : 'supabase';
const result = spawnSync(command, args, {
  cwd: process.cwd(),
  env,
  stdio: 'inherit',
  shell: process.platform === 'win32',
});

if (result.error) {
  console.error(result.error.message);
  process.exit(1);
}

process.exit(result.status ?? 1);
