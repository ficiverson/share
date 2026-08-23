const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

/**
 * Se dispara cuando se escribe un nuevo doc en
 * `notifications/{uid}/pending/{docId}`.
 *
 * Lee el token FCM del destinatario en `users/{uid}/fcmToken` y envía
 * la notificación push. Incluye `notifDocId` en el data payload para que
 * el cliente pueda borrar el doc de Firestore tras recibirlo en primer plano
 * (evita mostrarla dos veces).
 */
exports.sendPushOnNewNotification = onDocumentCreated(
  'notifications/{uid}/pending/{docId}',
  async (event) => {
    const uid = event.params.uid;
    const docId = event.params.docId;
    const payload = event.data?.data();
    if (!payload) return null;

    // Leer token FCM del destinatario.
    const userSnap = await getFirestore().collection('users').doc(uid).get();
    const token = userSnap.data()?.fcmToken;
    if (!token) {
      console.log(`No FCM token for uid=${uid}, skipping push.`);
      return null;
    }

    try {
      await getMessaging().send({
        token,
        notification: {
          title: payload.title ?? 'Share',
          body: payload.body ?? '',
        },
        data: {
          groupId: payload.groupId ?? '',
          expenseId: payload.expenseId ?? '',
          notifDocId: docId,          // usado por el cliente para borrar el doc
        },
        android: {
          priority: 'high',
          notification: { sound: 'default' },
        },
        apns: {
          payload: { aps: { sound: 'default', badge: 1 } },
        },
      });
      console.log(`Push sent to uid=${uid}, doc=${docId}`);
    } catch (err) {
      console.error(`Error sending push to uid=${uid}:`, err);
    }

    return null;
  }
);
