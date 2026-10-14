/**
 * CX1Q: TEST-ONLY signed-JWT / actor-scoped Track HTTP contract simulator.
 * Does NOT implement or deploy an endpoint, connect to GoTrue/PostgREST,
 * start a listener, or verify production issuer keys.
 * Keys are supplied by an offline test and are NEVER installed or stored.
 */
import assert from 'node:assert/strict';
import {verify} from 'node:crypto';

export const route = '/rest/v1/rpc/list_my_track_bookings_v1';
export const publicFields = Object.freeze(['booking_id','booking_status','scheduled_start','created_at']);
export const expectedRole = 'authenticated';

const uuid = /^[a-f0-9]{8}-[a-f0-9]{4}-[1-8][a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$/i;
const jwtPart = /^[A-Za-z0-9_-]+$/;
const allowedClaims = new Set(['iss','aud','sub','role','iat','nbf','exp','session_id']);
const safeJSON = (part) => {
  if (!jwtPart.test(part)) throw Error('Invalid encoded token component');
  const raw = Buffer.from(part, 'base64url').toString('utf8');
  const obj = JSON.parse(raw);
  if (!obj || typeof obj !== 'object' || Array.isArray(obj)) throw Error('Invalid token JSON');
  return obj;
};
const hasOwn = (o,k) => Object.prototype.hasOwnProperty.call(o,k);

export function verifySyntheticJwt(token, config) {
  if (typeof token !== 'string' || token.length > 4096 || token.length < 50) throw Error('Rejected bearer token');
  const pieces=token.split('.');
  if (pieces.length !== 3) throw Error('Rejected bearer token');
  const [encodedHead,encodedPayload,encodedSig]=pieces;
  const head=safeJSON(encodedHead);
  const claims=safeJSON(encodedPayload);
  // This is a pinned test profile, NOT a full GoTrue/JWKS verifier.
  if (Object.keys(head).sort().join(',') !== 'alg,kid,typ' ||
      head.alg !== 'EdDSA' || head.typ !== 'JWT' || head.kid !== 'cx1q-offline-only') {
    throw Error('Unsupported test JWT header');
  }
  if (typeof encodedSig !== 'string' || !jwtPart.test(encodedSig)) throw Error('Invalid test signature encoding');
  const sig=Buffer.from(encodedSig,'base64url');
  if (sig.length !== 64 || !verify(null,Buffer.from(encodedHead+'.'+encodedPayload),config.publicKey,sig))
    throw Error('Invalid test signature');
  if (!Object.keys(claims).every(k=>allowedClaims.has(k))) throw Error('Unsupported token claims');
  if (claims.iss !== config.issuer || claims.aud !== config.audience ||
      claims.role !== expectedRole || !uuid.test(claims.sub ?? '')) {
    throw Error('Test issuer, audience, role or actor mismatch');
  }
  if (!Number.isSafeInteger(claims.iat) || !Number.isSafeInteger(claims.nbf) ||
      !Number.isSafeInteger(claims.exp) || claims.exp <= claims.iat ||
      claims.nbf < claims.iat || claims.exp-claims.iat > 3600) {
    throw Error('Test token time claims invalid');
  }
  const now=config.now;
  if (!Number.isSafeInteger(now) || claims.iat > now+30 ||
      claims.nbf > now || claims.exp <= now) throw Error('Test token not currently valid');
  if (!uuid.test(claims.session_id ?? '') || config.revokedSessions.has(claims.session_id))
    throw Error('Test session missing or revoked');
  return claims.sub;
}

function deny(status) {
  return {status,headers:{'cache-control':'no-store','content-type':'application/json'},
    body:{error:status===401?'Authentication required':'Not permitted'}};
}

export function simulateTrackRead(req,config) {
  // This is a pure function. It does not listen on a socket, read local DB,
  // or return a live account's data. Only synthetic caller-supplied rows.
  if (!req || typeof req !== 'object' || !config ||
      !Array.isArray(config.rows) || !(config.revokedSessions instanceof Set)) return deny(403);
  if (req.method !== 'GET') return deny(405);
  if (req.path !== route || typeof req.query !== 'undefined') return deny(404);
  if (req.origin !== config.allowedOrigin) return deny(403);
  if (!req.headers || typeof req.headers !== 'object') return deny(401);
  const keys=Object.keys(req.headers);
  if (!keys.every(k=>k==='authorization'||k==='accept') ||
      typeof req.headers.authorization !== 'string' ||
      (hasOwn(req.headers,'accept') && req.headers.accept !== 'application/json')) return deny(401);
  const matched=/^Bearer ([A-Za-z0-9_.-]+)$/.exec(req.headers.authorization);
  if (!matched) return deny(401);
  let actor;
  try {actor=verifySyntheticJwt(matched[1],config);} catch {return deny(401);}
  const permitted=config.rows
    .filter(x=>x.customer_id===actor)
    .sort((a,b)=> b.created_at.localeCompare(a.created_at) ||
      a.booking_id.localeCompare(b.booking_id))
    .slice(0,100)
    .map(x=>Object.fromEntries(publicFields.map(k=>[k,x[k]??null])));
  assert.ok(permitted.every(x=>Object.keys(x).join(',')===publicFields.join(',')));
  return {status:200,headers:{'cache-control':'no-store',
    'content-type':'application/json','access-control-allow-origin':config.allowedOrigin,
    'vary':'Origin'},body:permitted};
}
