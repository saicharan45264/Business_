import { createHmac, randomBytes, scryptSync, timingSafeEqual } from 'node:crypto';
import { Pool } from 'pg';

const SESSION_LIFETIME_MS = 12 * 60 * 60 * 1000;
function sessionKey():Buffer { return scryptSync(process.env.APP_PASSWORD || '', 'giri-fruits-session-v1', 32); }
export function createSessionToken():string {
  const payload=Buffer.from(JSON.stringify({exp:Date.now()+SESSION_LIFETIME_MS,nonce:randomBytes(16).toString('hex')})).toString('base64url');
  const signature=createHmac('sha256',sessionKey()).update(payload).digest('base64url');
  return `session.${payload}.${signature}`;
}
function validSessionToken(token:string):boolean {
  try {
    const [prefix,payload,signature,...extra]=token.split('.');
    if(prefix!=='session'||!payload||!signature||extra.length)return false;
    const expected=createHmac('sha256',sessionKey()).update(payload).digest();
    const actual=Buffer.from(signature,'base64url');
    if(actual.length!==expected.length||!timingSafeEqual(actual,expected))return false;
    const decoded=JSON.parse(Buffer.from(payload,'base64url').toString('utf8'));
    return Number.isSafeInteger(decoded.exp)&&decoded.exp>Date.now()&&decoded.exp<=Date.now()+SESSION_LIFETIME_MS;
  } catch {return false;}
}

// A shared password is intentionally kept in memory only by the browser.
// Attempts are counted in PostgreSQL so limits apply across serverless instances.
export function passwordGuard(pool: Pool) {
  const password = process.env.APP_PASSWORD || '';
  if (password.length < 6) throw new Error('APP_PASSWORD must contain at least 6 characters');
  const salt = 'giri-fruits-access';
  const expected = scryptSync(password, salt, 32);
  return async (req: any, res: any, next: () => void) => {
    if (req.method === 'OPTIONS') return next();
    const supplied = String(req.headers.authorization || '').replace(/^Bearer /, '');
    if (!supplied || supplied.length > 200) return res.status(401).json({ message: 'Password required' });
    if(supplied.startsWith('session.')) {
      if(!validSessionToken(supplied))return res.status(401).json({message:'Session expired. Please sign in again.'});
      res.setHeader('Cache-Control','no-store');return next();
    }
    let candidate: string;
    try { candidate = Buffer.from(supplied, 'base64').toString('utf8'); } catch { return res.status(401).end(); }
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query("INSERT INTO app_login_guard (id, failures) VALUES (1, 0) ON CONFLICT (id) DO NOTHING");
      const { rows } = await client.query('SELECT failures, locked_until FROM app_login_guard WHERE id=1 FOR UPDATE');
      if (rows[0].locked_until && new Date(rows[0].locked_until).getTime() > Date.now()) {
        await client.query('COMMIT');
        return res.status(429).json({ message: 'Too many attempts. Try again later.' });
      }
      const actual = scryptSync(candidate, salt, 32);
      if (!timingSafeEqual(expected, actual)) {
        await client.query("UPDATE app_login_guard SET failures=CASE WHEN locked_until IS NOT NULL AND locked_until <= now() THEN 1 ELSE failures+1 END, locked_until=CASE WHEN (CASE WHEN locked_until IS NOT NULL AND locked_until <= now() THEN 1 ELSE failures+1 END) >= 5 THEN now()+interval '15 minutes' ELSE NULL END WHERE id=1");
        await client.query('COMMIT');
        return res.status(401).json({ message: 'Incorrect password' });
      }
      await client.query('UPDATE app_login_guard SET failures=0, locked_until=NULL WHERE id=1');
      await client.query('COMMIT');
      res.setHeader('Cache-Control', 'no-store');
      return next();
    } catch {
      await client.query('ROLLBACK').catch(() => {});
      return res.status(503).json({ message: 'Unable to verify access' });
    } finally { client.release(); }
  };
}
