import { Socket } from 'node:net';
import { EvidenceError, scanWithClamd } from './scan.mjs';

const MAX_FRESHNESS_MS = 72 * 60 * 60 * 1000;
const DEFAULT_FRESHNESS_MS = 48 * 60 * 60 * 1000;
const FUTURE_SKEW_MS = 5 * 60 * 1000;
const VERSION = /^ClamAV ([0-9][A-Za-z0-9.+_-]*)\/([1-9][0-9]*)\/((?:Mon|Tue|Wed|Thu|Fri|Sat|Sun) [A-Z][a-z]{2}\s+\d{1,2} \d{2}:\d{2}:\d{2} \d{4})$/;

function fail() {
  throw new EvidenceError('SCANNER_UNAVAILABLE', 'Antivirus health or signature freshness could not be verified');
}
function settings({host, port, timeoutMs, maxAgeMs}) {
  if (!['127.0.0.1', '::1'].includes(host) ||
      !Number.isInteger(port) || port < 1 || port > 65535 ||
      !Number.isInteger(timeoutMs) || timeoutMs < 100 || timeoutMs > 120000 ||
      !Number.isSafeInteger(maxAgeMs) || maxAgeMs < 1 || maxAgeMs > MAX_FRESHNESS_MS) fail();
}

/** Parse the clamd VERSION reply; never trust a process/container "healthy" flag alone. */
export function parseClamdVersion(reply, {nowMs = Date.now(), maxAgeMs = DEFAULT_FRESHNESS_MS} = {}) {
  if (typeof reply !== 'string' || reply.length > 256 ||
      !Number.isSafeInteger(maxAgeMs) || maxAgeMs < 1 || maxAgeMs > MAX_FRESHNESS_MS ||
      !Number.isFinite(nowMs)) fail();
  const match = VERSION.exec(reply.replace(/\0$/, '').trim());
  if (!match) fail();
  // clamd emits the signature timestamp in GMT as an English ctime string.
  const updatedMs = Date.parse(match[3] + ' GMT');
  if (!Number.isFinite(updatedMs) ||
      updatedMs - nowMs > FUTURE_SKEW_MS ||
      nowMs - updatedMs > maxAgeMs) fail();
  return Object.freeze({
    engine: match[1],
    signatureVersion: Number(match[2]),
    updatedAt: new Date(updatedMs).toISOString(),
    ageMs: Math.max(0, nowMs - updatedMs),
    fresh: true,
  });
}

/**
 * Local-only, bounded ClamAV version/freshness preflight. No input bytes are
 * sent in this probe. This is NOT a live evidence-admission endpoint.
 */
export async function requireFreshClamd({
  host = '127.0.0.1', port = 3310, timeoutMs = 5000,
  maxAgeMs = DEFAULT_FRESHNESS_MS,
} = {}) {
  settings({host, port, timeoutMs, maxAgeMs});
  const version = await new Promise((resolve, reject) => {
    const socket = new Socket();
    let done = false, text = '';
    const finish = (error, value) => {
      if (done) return;
      done = true;
      socket.destroy();
      if (error) reject(new EvidenceError('SCANNER_UNAVAILABLE', 'Antivirus freshness probe failed'));
      else resolve(value);
    };
    socket.setTimeout(timeoutMs);
    socket.once('timeout', () => finish(true));
    socket.once('error', () => finish(true));
    socket.on('data', chunk => {
      text += chunk.toString('utf8');
      if (text.length > 256) return finish(true);
      if (text.includes('\0')) finish(false, text);
    });
    socket.once('end', () => {
      if (!done) finish(false, text);
    });
    socket.once('close', () => {
      if (!done) finish(true);
    });
    socket.once('connect', () => socket.write(Buffer.from('zVERSION\0', 'ascii')));
    socket.connect(port, host);
  });
  return parseClamdVersion(version, {maxAgeMs});
}

/** Quarantine scanner path: insist on current definitions BEFORE scanning data. */
export async function scanWithFreshClamd(bytes, options = {}) {
  await requireFreshClamd(options);
  return scanWithClamd(bytes, options);
}
