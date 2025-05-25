import {firestore} from "firebase-functions/v1";
import {getApps, initializeApp, applicationDefault} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";

if (!getApps().length) {
  initializeApp({credential: applicationDefault()});
}

const db = getFirestore();
const messaging = getMessaging();

function normalizeRegion(region: string | undefined): string {
  return (region ?? "").toLowerCase().replace(/\s+/g, "");
}

const onAnnouncementDeleted = firestore
  .document("announcements/{announcementId}")
  .onDelete(async (snap) => {
    const deletedData = snap.data();
    if (!deletedData) return null;

    const normalizedRegion = normalizeRegion(deletedData.region);
    const usersSnapshot = await db.collection("users").get();
    const tokens: string[] = [];
    const batch = db.batch();

    for (const doc of usersSnapshot.docs) {
      const uid = doc.id;
      const userData = doc.data();
      const token = userData.fcmToken;
      const userRegion = normalizeRegion(userData.region);

      if (userRegion !== normalizedRegion) continue;

      const notificationRef = db
        .collection("notifications")
        .doc(uid)
        .collection("userNotifications")
        .doc();

      batch.set(notificationRef, {
        title: "Announcement Removed",
        body: `The announcement "${deletedData.title}" has been deleted.`,
        type: "announcement",
        createdAt: FieldValue.serverTimestamp(),
        isRead: false,
      });

      if (token) tokens.push(token);
    }

    await batch.commit();

    if (tokens.length > 0) {
      await messaging.sendEachForMulticast({
        tokens,
        notification: {
          title: "Announcement Deleted",
          body: `The announcement "${deletedData.title}" was removed.`,
        },
        data: {
          route: "announcement",
          timestamp: new Date().toISOString(),
        },
      });
    }

    return null;
  });

export default onAnnouncementDeleted;
