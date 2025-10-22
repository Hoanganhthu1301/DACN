import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';
import logger = require('firebase-functions/logger');

admin.initializeApp();
setGlobalOptions({ region: 'asia-southeast1', maxInstances: 10 });

export const sendPushOnNotificationCreate = onDocumentCreated(
  'users/{userId}/notifications/{notiId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const { userId } = event.params as { userId: string; notiId: string };
    const data = snap.data() as any;

    // Lấy token
    const tSnap = await admin.firestore()
      .collection('users').doc(userId)
      .collection('fcmTokens').get();
    const tokens = tSnap.docs.map(d => d.id).filter(Boolean);
    if (!tokens.length) {
      logger.info(`No FCM tokens for user ${userId}`);
      return;
    }

    // Tiêu đề/nội dung
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

    const resp = await admin.messaging().sendEachForMulticast({
      notification: { title, body }, // bắt buộc để Android tự hiện khi nền/đóng
      data: {
        type: String(type),
        actorId: data.actorId ? String(data.actorId) : '',
        foodId: data.foodId ? String(data.foodId) : '',
      },
      tokens,
      android: { priority: 'high', notification: { sound: 'default' } },
      apns: { payload: { aps: { alert: { title, body }, sound: 'default' } } },
    });

    // Dọn token hỏng
    if (resp.failureCount > 0) {
      const batch = admin.firestore().batch();
      resp.responses.forEach((r, i) => {
        if (!r.success) {
          const code = r.error?.code ?? '';
          if (code.includes('registration-token-not-registered') || code.includes('invalid-argument')) {
            batch.delete(admin.firestore()
              .collection('users').doc(userId)
              .collection('fcmTokens').doc(tokens[i]));
          }
        }
      });
      await batch.commit();
    }

    logger.info(`Push sent to ${tokens.length} tokens — success=${resp.successCount}, failure=${resp.failureCount}`);
  }
);