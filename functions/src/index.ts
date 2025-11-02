import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';
import * as logger from 'firebase-functions/logger';

// v2 https onRequest
import { onRequest } from 'firebase-functions/v2/https';

import express from 'express';
import cors from 'cors';

admin.initializeApp();
setGlobalOptions({ region: 'asia-southeast1', maxInstances: 10 });

/**
 * Trigger: push when a notification doc is created under users/{userId}/notifications/{notiId}
 * (This is your existing handler, preserved and slightly hardened.)
 */
export const sendPushOnNotificationCreate = onDocumentCreated(
  'users/{userId}/notifications/{notiId}',
  async (event) => {
    try {
      const snap = event.data;
      if (!snap) return;

      const { userId } = event.params as { userId: string; notiId: string };
      const data = snap.data() as any;

      // Read tokens list (doc id = token)
      const tSnap = await admin.firestore()
        .collection('users').doc(userId)
        .collection('fcmTokens').get();
      const tokens = tSnap.docs.map(d => d.id).filter(Boolean);
      if (!tokens.length) {
        logger.info(`No FCM tokens for user ${userId}`);
        return;
      }

      // Title/body defaults
      const type = data.type ?? 'general';
      const title = data.title ?? (type === 'like'
        ? 'Bài viết được thích'
        : type === 'follow'
          ? 'Có người theo dõi bạn'
          : 'Thông báo');
      const body = data.body ?? (type === 'like'
        ? `${data.actorName ?? 'Ai đó'} đã thích bài viết của bạn`
        : type === 'follow'
          ? `${data.actorName ?? 'Ai đó'} đã theo dõi bạn`
          : 'Bạn có hoạt động mới');

      // Chunk tokens (max 500 per multicast)
      const chunkSize = 500;
      const chunks: string[][] = [];
      for (let i = 0; i < tokens.length; i += chunkSize) {
        chunks.push(tokens.slice(i, i + chunkSize));
      }

      let totalSuccess = 0;
      let totalFailure = 0;

      for (const chunk of chunks) {
        try {
          const resp = await admin.messaging().sendEachForMulticast({
            notification: { title, body },
            data: {
              type: String(type),
              actorId: data.actorId ? String(data.actorId) : '',
              foodId: data.foodId ? String(data.foodId) : '',
            },
            tokens: chunk,
            android: { priority: 'high', notification: { sound: 'default' } },
            apns: { payload: { aps: { alert: { title, body }, sound: 'default' } } },
          });

          totalSuccess += resp.successCount;
          totalFailure += resp.failureCount;

          // Cleanup invalid tokens in this chunk
          if (resp.failureCount > 0) {
            const batch = admin.firestore().batch();
            resp.responses.forEach((r, i) => {
              if (!r.success) {
                const code = r.error?.code ?? '';
                // Common codes: registration-token-not-registered, messaging/invalid-registration-token
                if (code.includes('registration-token-not-registered') || code.includes('invalid-argument') || code.includes('messaging/invalid-registration-token')) {
                  const tokenId = chunk[i];
                  if (tokenId) {
                    const ref = admin.firestore().collection('users').doc(userId).collection('fcmTokens').doc(tokenId);
                    batch.delete(ref);
                    logger.info(`Deleting invalid token ${tokenId} for user ${userId}`);
                  }
                } else {
                  logger.warn(`FCM error for token index=${i}: ${String(r.error)}`);
                }
              }
            });
            await batch.commit();
          }
        } catch (e) {
          logger.error('FCM chunk send error', e);
        }
      }

      logger.info(`Push sent — tokens=${tokens.length}, success=${totalSuccess}, failure=${totalFailure}`);
    } catch (err) {
      logger.error('sendPushOnNotificationCreate handler error:', err);
    }
  }
);

/**
 * Express REST API (exported as one HTTP Cloud Function 'api')
 * - GET  /menu                 -> generate menu for authenticated user
 * - POST /slot/reload          -> return one food for slot
 * - POST /mealPlan             -> save meal plan for user
 * - GET  /comments?foodId=...  -> list comments for food
 * - POST /comments             -> create comment
 * - DELETE /comments/:id       -> delete comment (author or admin)
 *
 * All endpoints require Firebase ID token in header Authorization: Bearer <idToken>
 */

const app = express();
app.use(cors({ origin: true }));
app.use(express.json({ limit: '1mb' }));

// Middleware to validate Firebase ID token
async function validateFirebaseIdToken(req: express.Request, res: express.Response, next: express.NextFunction) {
  const authHeader = (req.headers.authorization || '') as string;
  if (!authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized - missing token' });
  }
  const idToken = authHeader.split('Bearer ')[1];
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    // attach uid and token claims to request
    (req as any).uid = decoded.uid;
    (req as any).claims = decoded;
    return next();
  } catch (err) {
    logger.error('Token verify failed:', err);
    return res.status(401).json({ error: 'Unauthorized - invalid token' });
  }
}

app.use(validateFirebaseIdToken);

/* ---------- Helper: detect slot ---------- */
function detectSlot(data: any): 'main' | 'side' | 'appetizer' | 'dessert' | null {
  try {
    const mealType = data.mealType ?? data.meal_type ?? data.mealTypes;
    if (Array.isArray(mealType)) {
      for (const m of mealType) {
        const s = String(m).toLowerCase();
        if (s.includes('main') || s.includes('chính')) return 'main';
        if (s.includes('side') || s.includes('phụ')) return 'side';
        if (s.includes('appetizer') || s.includes('khai') || s.includes('starter')) return 'appetizer';
        if (s.includes('dessert') || s.includes('tráng')) return 'dessert';
      }
    } else if (typeof mealType === 'string') {
      const s = mealType.toLowerCase();
      if (s.includes('main') || s.includes('chính')) return 'main';
      if (s.includes('side') || s.includes('phụ')) return 'side';
      if (s.includes('appetizer') || s.includes('khai') || s.includes('starter')) return 'appetizer';
      if (s.includes('dessert') || s.includes('tráng')) return 'dessert';
    }
    const cat = String(data.categoryName ?? data.category ?? '').toLowerCase();
    if (cat.includes('tráng') || cat.includes('dessert')) return 'dessert';
    if (cat.includes('khai') || cat.includes('appetizer') || cat.includes('starter')) return 'appetizer';
    if (cat.includes('phụ') || cat.includes('side') || cat.includes('snack')) return 'side';
    if (cat.includes('chính') || cat.includes('main')) return 'main';
  } catch (e) {
    // ignore
  }
  return null;
}

/* ---------- Endpoint: GET /menu ---------- */
app.get('/menu', async (req, res) => {
  const uid = (req as any).uid as string;
  try {
    // 1) read user_saves/{uid}/foods last 10
    const savedSnap = await admin.firestore()
      .collection('user_saves').doc(uid).collection('foods')
      .orderBy('createdAt', 'desc').limit(10).get();
    const savedIds = savedSnap.docs.map(d => d.id);

    if (savedIds.length === 0) {
      // fallback: top 3 foods
      const top = await admin.firestore().collection('foods').limit(3).get();
      const docs = top.docs.map(d => ({ id: d.id, data: d.data() }));
      return res.json({ main: docs[0] || null, side: docs[1] || null, appetizer: docs[2] || null, dessert: null });
    }

    // load saved foods in batches
    const loaded: Array<{ id: string; data: any }> = [];
    for (let i = 0; i < savedIds.length; i += 10) {
      const chunk = savedIds.slice(i, i + 10);
      const snap = await admin.firestore().collection('foods').where(admin.firestore.FieldPath.documentId(), 'in', chunk).get();
      snap.docs.forEach(d => loaded.push({ id: d.id, data: d.data() }));
    }

    // assign slots preferring detected slot
    const slots: any = { main: null, side: null, appetizer: null, dessert: null };
    const used = new Set<string>();

    for (const item of loaded) {
      const slot = detectSlot(item.data);
      if (slot && !slots[slot]) {
        slots[slot] = item;
        used.add(item.id);
      }
      if (Object.values(slots).filter(Boolean).length === 4) break;
    }

    // ensure main exists
    if (!slots.main) {
      for (const item of loaded) {
        if (used.has(item.id)) continue;
        slots.main = item;
        used.add(item.id);
        break;
      }
    }

    // fill remaining slots from liked
    for (const item of loaded) {
      if (used.has(item.id)) continue;
      for (const s of ['side', 'appetizer', 'dessert']) {
        if (!slots[s]) {
          slots[s] = item;
          used.add(item.id);
          break;
        }
      }
      if (Object.values(slots).filter(Boolean).length === 4) break;
    }

    // final fallback any foods
    if (!slots.side || !slots.appetizer || !slots.dessert) {
      const any = await admin.firestore().collection('foods').limit(100).get();
      for (const d of any.docs) {
        if (used.has(d.id)) continue;
        if (!slots.side) { slots.side = { id: d.id, data: d.data() }; used.add(d.id); continue; }
        if (!slots.appetizer) { slots.appetizer = { id: d.id, data: d.data() }; used.add(d.id); continue; }
        if (!slots.dessert) { slots.dessert = { id: d.id, data: d.data() }; used.add(d.id); continue; }
      }
    }

    return res.json(slots);
  } catch (err) {
    logger.error('GET /menu error', err);
    return res.status(500).json({ error: 'server_error', details: String(err) });
  }
});

/* ---------- Endpoint: POST /slot/reload ---------- */
app.post('/slot/reload', async (req, res) => {
  const uid = (req as any).uid as string;
  const slot = req.body?.slot as string | undefined;
  const excludeIds = Array.isArray(req.body?.excludeIds) ? req.body?.excludeIds as string[] : [];
  if (!slot) return res.status(400).json({ error: 'slot required' });

  try {
    // 1) prefer liked items matching slot
    const savedSnap = await admin.firestore()
      .collection('user_saves').doc(uid).collection('foods')
      .orderBy('createdAt', 'desc').limit(50).get();
    const savedIds = savedSnap.docs.map(d => d.id);

    const loaded: Array<{ id: string; data: any }> = [];
    for (let i = 0; i < savedIds.length; i += 10) {
      const chunk = savedIds.slice(i, i + 10);
      const snap = await admin.firestore().collection('foods').where(admin.firestore.FieldPath.documentId(), 'in', chunk).get();
      snap.docs.forEach(d => loaded.push({ id: d.id, data: d.data() }));
    }

    const candidates = loaded.filter(item => {
      if (excludeIds.includes(item.id)) return false;
      const detected = detectSlot(item.data);
      return detected === slot;
    });
    if (candidates.length > 0) return res.json(candidates[Math.floor(Math.random() * candidates.length)]);

    // 2) try mealType synonyms queries
    const slotToSyn: Record<string, string[]> = {
      main: ['Bữa chính','main','chính'],
      side: ['Món phụ','side','phụ'],
      appetizer: ['Khai vị','appetizer','starter'],
      dessert: ['Tráng miệng','dessert'],
    };
    const syns = slotToSyn[slot] || [];
    for (const s of syns) {
      try {
        const snap = await admin.firestore().collection('foods').where('mealType', 'array-contains', s).limit(50).get();
        const list = snap.docs.filter(d => !excludeIds.includes(d.id));
        if (list.length > 0) return res.json(list[Math.floor(Math.random() * list.length)]);
      } catch (e) {
        // ignore
      }
    }

    // 3) final fallback: larger scan detect by fields
    const any = await admin.firestore().collection('foods').limit(500).get();
    const finals = any.docs.filter(d => {
      if (excludeIds.includes(d.id)) return false;
      return detectSlot(d.data()) === slot;
    });
    if (finals.length > 0) return res.json(finals[Math.floor(Math.random() * finals.length)]);

    return res.status(404).json({ error: 'no_candidate' });
  } catch (err) {
    logger.error('POST /slot/reload error', err);
    return res.status(500).json({ error: 'server_error', details: String(err) });
  }
});

/* ---------- Endpoint: POST /mealPlan ---------- */
app.post('/mealPlan', async (req, res) => {
  const uid = (req as any).uid as string;
  const body = req.body || {};
  const date = body.date || new Date().toISOString().substring(0, 10);
  const meals = Array.isArray(body.meals) ? body.meals : [];
  try {
    await admin.firestore().collection('users').doc(uid).collection('mealPlans').doc(date).set({
      date,
      meals,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      source: 'api',
    }, { merge: true });
    return res.json({ ok: true, date });
  } catch (err) {
    logger.error('POST /mealPlan error', err);
    return res.status(500).json({ error: 'server_error', details: String(err) });
  }
});

/* ---------- Comments endpoints ---------- */
/**
 * Firestore structure:
 * collection 'comments' documents:
 *  {
 *    foodId: string,
 *    authorId: string,
 *    authorName?: string,
 *    text: string,
 *    replyTo?: string|null,
 *    createdAt: Timestamp
 *  }
 */

// GET /comments?foodId=...&limit=...
app.get('/comments', async (req, res) => {
  const foodId = String(req.query.foodId || '');
  const limit = Math.min(parseInt(String(req.query.limit || '50')) || 50, 200);
  if (!foodId) return res.status(400).json({ error: 'foodId required' });
  try {
    const snap = await admin.firestore().collection('comments')
      .where('foodId', '==', foodId)
      .orderBy('createdAt', 'desc')
      .limit(limit)
      .get();
    const comments = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    return res.json({ ok: true, comments });
  } catch (err) {
    logger.error('GET /comments error', err);
    return res.status(500).json({ error: 'server_error', details: String(err) });
  }
});

// POST /comments { foodId, text, replyTo? }
app.post('/comments', async (req, res) => {
  const uid = (req as any).uid as string;
  const body = req.body || {};
  const foodId = body.foodId && String(body.foodId).trim();
  const text = body.text && String(body.text).trim();
  const replyTo = body.replyTo ? String(body.replyTo) : null;
  if (!foodId || !text) return res.status(400).json({ error: 'foodId and text required' });

  try {
    let authorName: string | null = null;
    try {
      const userRecord = await admin.auth().getUser(uid);
      authorName = userRecord.displayName || userRecord.email || null;
    } catch (_) { /* ignore */ }

    const ref = await admin.firestore().collection('comments').add({
      foodId,
      text,
      authorId: uid,
      authorName,
      replyTo: replyTo || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    const newDoc = await ref.get();
    return res.status(201).json({ ok: true, comment: { id: ref.id, ...newDoc.data() } });
  } catch (err) {
    logger.error('POST /comments error', err);
    return res.status(500).json({ error: 'server_error', details: String(err) });
  }
});

// DELETE /comments/:id
app.delete('/comments/:id', async (req, res) => {
  const uid = (req as any).uid as string;
  const claims = (req as any).claims || {};
  const commentId = req.params.id;
  if (!commentId) return res.status(400).json({ error: 'commentId required' });

  try {
    const docRef = admin.firestore().collection('comments').doc(commentId);
    const snap = await docRef.get();
    if (!snap.exists) return res.status(404).json({ error: 'not_found' });
    const data = snap.data() || {};
    const authorId = data.authorId;

    const isAdmin = claims.admin === true || claims.role === 'admin';
    if (authorId !== uid && !isAdmin) return res.status(403).json({ error: 'forbidden' });

    await docRef.delete();
    return res.json({ ok: true });
  } catch (err) {
    logger.error('DELETE /comments error', err);
    return res.status(500).json({ error: 'server_error', details: String(err) });
  }
});

/* ---------- Export Express app as Cloud Function (v2) ---------- */
export const api = onRequest(app);