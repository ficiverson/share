/**
 * Cloudflare Worker — FCM sender
 *
 * Recibe un POST del cliente Flutter con el token FCM del destinatario y el
 * contenido de la notificación, genera un token OAuth 2.0 a partir de la
 * cuenta de servicio de Firebase (almacenada como secreto de Wrangler) y
 * llama a la FCM HTTP v1 API.
 *
 * Secrets requeridos (configurar con `wrangler secret put`):
 *   FIREBASE_SERVICE_ACCOUNT  — contenido del JSON de cuenta de servicio
 *   SHARED_SECRET             — cadena aleatoria para autenticar al cliente
 *
 * Body esperado (JSON):
 *   { token, title, body, data? }
 */
export default {
  async fetch(request, env) {
    if (request.method !== 'POST') {
      return new Response('Method Not Allowed', { status: 405 });
    }

    // Autenticación mínima: Bearer compartido con el cliente Flutter.
    const auth = request.headers.get('Authorization') ?? '';
    if (auth !== `Bearer ${env.SHARED_SECRET}`) {
      return new Response('Unauthorized', { status: 401 });
    }

    let payload;
    try {
      payload = await request.json();
    } catch {
      return new Response('Bad Request', { status: 400 });
    }

    const { token, title, body, data } = payload;
    if (!token || !title) {
      return new Response('Missing token or title', { status: 400 });
    }

    let sa;
    try {
      sa = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT);
    } catch {
      return new Response('Worker misconfigured: bad FIREBASE_SERVICE_ACCOUNT', { status: 500 });
    }

    try {
      const accessToken = await getOAuthToken(sa);

      const fcmRes = await fetch(
        `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            message: {
              token,
              notification: { title, body: body ?? '' },
              data: stringifyValues(data ?? {}),
              android: {
                priority: 'high',
                notification: { sound: 'default' },
              },
              apns: {
                payload: { aps: { sound: 'default', badge: 1 } },
              },
            },
          }),
        }
      );

      const fcmJson = await fcmRes.json().catch(() => ({}));
      return new Response(JSON.stringify(fcmJson), {
        status: fcmRes.status,
        headers: { 'Content-Type': 'application/json' },
      });
    } catch (err) {
      return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
    }
  },
};

// ── OAuth 2.0 via service account JWT ────────────────────────────────────────

async function getOAuthToken(sa) {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claimSet = {
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };

  const signingInput =
    toBase64Url(JSON.stringify(header)) + '.' + toBase64Url(JSON.stringify(claimSet));

  const privateKey = await importPrivateKey(sa.private_key);
  const signature = await crypto.subtle.sign(
    { name: 'RSASSA-PKCS1-v1_5' },
    privateKey,
    new TextEncoder().encode(signingInput)
  );

  const jwt = `${signingInput}.${arrayBufferToBase64Url(signature)}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body:
      'grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer' +
      `&assertion=${encodeURIComponent(jwt)}`,
  });

  const json = await res.json();
  if (!json.access_token) {
    throw new Error(`OAuth error: ${JSON.stringify(json)}`);
  }
  return json.access_token;
}

async function importPrivateKey(pem) {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '');
  const binary = atob(b64);
  const buf = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) buf[i] = binary.charCodeAt(i);
  return crypto.subtle.importKey(
    'pkcs8',
    buf.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  );
}

function toBase64Url(str) {
  // unescape(encodeURIComponent()) → convierte UTF-8 a latin1 para btoa
  return btoa(unescape(encodeURIComponent(str)))
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

function arrayBufferToBase64Url(buf) {
  const bytes = new Uint8Array(buf);
  let str = '';
  for (const b of bytes) str += String.fromCharCode(b);
  return btoa(str).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
}

// FCM data payload solo acepta strings
function stringifyValues(obj) {
  return Object.fromEntries(Object.entries(obj).map(([k, v]) => [k, String(v)]));
}
