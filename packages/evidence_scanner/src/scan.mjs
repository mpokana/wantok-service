import { createHash } from 'node:crypto';
import { extname, basename } from 'node:path';
import { Socket } from 'node:net';

export const MAX_BYTES = 5 * 1024 * 1024;
const MIME_FOR_EXTENSION = Object.freeze({
  '.pdf': 'application/pdf', '.png': 'image/png',
  '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg',
});

export class EvidenceError extends Error {
  constructor(code, message) {
    super(message);
    this.name = 'EvidenceError';
    this.code = code;
  }
}

function expectedMime(filename) {
  if (typeof filename !== 'string' || filename.length < 5 || filename.length > 160 ||
      filename !== basename(filename) ||
      (/[\\/:]/.test(filename) || /[\x00-\x1F\x7F\u202A-\u202E\u2066-\u2069]/u.test(filename)) ||
      filename.startsWith('.') || filename.trim() !== filename) {
    throw new EvidenceError('INVALID_FILENAME', 'Unsafe evidence filename');
  }
  const mime = MIME_FOR_EXTENSION[extname(filename).toLowerCase()];
  if (!mime) throw new EvidenceError('DISALLOWED_EXTENSION', 'Unsupported evidence extension');
  return mime;
}

function detectMime(data) {
  if (data.length >= 33 &&
      data.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10]))) {
    if (data.readUInt32BE(8) !== 13 ||
        data.toString('ascii', 12, 16) !== 'IHDR') {
      throw new EvidenceError('INVALID_CONTENT', 'Invalid PNG header');
    }
    const width = data.readUInt32BE(16);
    const height = data.readUInt32BE(20);
    if (!width || !height || width * height > 25_000_000) {
      throw new EvidenceError('IMAGE_DIMENSIONS', 'Image dimensions are not permitted');
    }
    let offset = 8;
    let ended = false;
    while (offset + 12 <= data.length) {
      const len = data.readUInt32BE(offset);
      const type = data.toString('ascii', offset + 4, offset + 8);
      const next = offset + 12 + len;
      if (next > data.length) throw new EvidenceError('INVALID_CONTENT', 'Truncated PNG chunk');
      if (type === 'IEND') {
        if (len !== 0 || next !== data.length) {
          throw new EvidenceError('INVALID_CONTENT', 'Unexpected content after PNG end');
        }
        ended = true;
        break;
      }
      offset = next;
    }
    if (!ended) throw new EvidenceError('INVALID_CONTENT', 'Missing PNG end');
    return 'image/png';
  }
  if (data.length >= 12 && data[0] === 0xff && data[1] === 0xd8 &&
      data[2] === 0xff && data[data.length - 2] === 0xff &&
      data[data.length - 1] === 0xd9) return 'image/jpeg';

  if (data.length >= 12 &&
      data.subarray(0, 5).equals(Buffer.from('%PDF-')) &&
      /%%EOF[\s\x00]*$/.test(
        data.subarray(Math.max(0, data.length - 2048)).toString('latin1')
      )) return 'application/pdf';

  throw new EvidenceError('INVALID_CONTENT', 'Unknown or truncated signature');
}

export function inspectEvidence({ filename, declaredMime, bytes }) {
  const requiredMime = expectedMime(filename);
  if (!Buffer.isBuffer(bytes)) throw new EvidenceError('INVALID_BUFFER', 'Expected a Buffer');
  if (bytes.length < 12 || bytes.length > MAX_BYTES) {
    throw new EvidenceError('INVALID_SIZE', 'File size not permitted');
  }
  if (typeof declaredMime !== 'string' ||
      declaredMime.toLowerCase() !== requiredMime) {
    throw new EvidenceError('MIME_MISMATCH', 'Declared MIME does not match filename');
  }
  const actualMime = detectMime(bytes);
  if (actualMime !== requiredMime) {
    throw new EvidenceError('SIGNATURE_MISMATCH', 'Content does not match filename/MIME');
  }
  return Object.freeze({
    sha256: createHash('sha256').update(bytes).digest('hex'),
    mime: actualMime, bytes: bytes.length,
  });
}

/** ClamAV clamd zINSTREAM; local-only, no public listener and fail-closed. */
export async function scanWithClamd(bytes, {
  host = '127.0.0.1', port = 3310, timeoutMs = 5000,
} = {}) {
  if (!Buffer.isBuffer(bytes) || bytes.length < 1 || bytes.length > MAX_BYTES) {
    throw new EvidenceError('INVALID_SIZE', 'Invalid scanner input');
  }
  if (!['127.0.0.1', '::1'].includes(host) ||
      !Number.isInteger(port) || port <= 0 || port > 65535 ||
      !Number.isInteger(timeoutMs) || timeoutMs < 100 || timeoutMs > 120000) {
    throw new EvidenceError('INVALID_SCANNER_CONFIG', 'Invalid local scanner configuration');
  }
  return new Promise((resolve, reject) => {
    const socket = new Socket();
    let finished = false;
    let response = '';
    const finish = (err, value) => {
      if (finished) return;
      finished = true;
      socket.destroy();
      if (err) reject(err);
      else resolve(value);
    };
    socket.setTimeout(timeoutMs);
    socket.on('timeout', () => finish(
      new EvidenceError('SCANNER_UNAVAILABLE', 'Antivirus scan timed out')));
    socket.on('error', () => finish(
      new EvidenceError('SCANNER_UNAVAILABLE', 'Scanner connection failed')));
    socket.on('connect', () => {
      socket.write(Buffer.from('zINSTREAM\0', 'ascii'));
      for (let i = 0; i < bytes.length; i += 65536) {
        const piece = bytes.subarray(i, i + 65536);
        const length = Buffer.alloc(4);
        length.writeUInt32BE(piece.length);
        socket.write(length);
        socket.write(piece);
      }
      socket.write(Buffer.alloc(4));
    });
    socket.on('data', (chunk) => {
      response += chunk.toString('utf8');
      if (response.length > 4096) finish(
        new EvidenceError('SCANNER_UNAVAILABLE', 'Unexpected scanner output'));
    });
    socket.on('end', () => {
      const answer = response.replace(/\0/g, '').trim();
      if (answer === 'stream: OK') {
        return finish(null, Object.freeze({ verdict: 'candidate_clean' }));
      }
      if (/^stream: .+ FOUND$/.test(answer)) {
        return finish(new EvidenceError('MALWARE_FOUND', 'Malware was detected'));
      }
      return finish(new EvidenceError('SCANNER_UNAVAILABLE', 'No clean verdict from scanner'));
    });
    socket.connect(port, host);
  });
}

/** No side effects. Even a scanner-clean file is NOT eligible for storage/review. */
export async function inspectAndScanEvidence({
  filename, declaredMime, bytes, scanner = scanWithClamd,
}) {
  const inspected = inspectEvidence({ filename, declaredMime, bytes });
  const result = await scanner(bytes);
  if (result?.verdict !== 'candidate_clean') {
    throw new EvidenceError('SCANNER_UNAVAILABLE', 'An explicit clean scan is required');
  }
  return Object.freeze({
    ...inspected,
    verdict: 'candidate_clean',
    storagePermitted: false,
    reviewerAccessPermitted: false,
    approved: false,
  });
}
