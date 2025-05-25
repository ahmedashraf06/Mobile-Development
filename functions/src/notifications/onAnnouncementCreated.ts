import {firestore} from "firebase-functions/v1";
import {getApps, initializeApp, applicationDefault} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";

if (!getApps().length) {
  initializeApp({credential: applicationDefault()});
}

const db = getFirestore();
const messaging = getMessaging();

function normalize(region: string): string {
  return region.toLowerCase().replace(/\s+/g, "");
}

const onAnnouncementCreated = firestore
  .document("announcements/{announcementId}")
  .onCreate(async (snap) => {
    const announcement = snap.data();
    if (!announcement || !announcement.region) return null;

    const announcementRegion = normalize(announcement.region);

    const usersSnapshot = await db.collection("users").get();
    const tokens: string[] = [];
    const batch = db.batch();

    for (const doc of usersSnapshot.docs) {
      const uid = doc.id;
      const userData = doc.data();
      const token = userData.fcmToken;
      const userRegionRaw = userData.region ?? "";

      if (normalize(userRegionRaw) !== announcementRegion) continue;

      const notificationRef = db
        .collection("notifications")
        .doc(uid)
        .collection("userNotifications")
        .doc();

      batch.set(notificationRef, {
        title: "New Announcement",
        body: "A new announcement has been posted.",
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
          title: "New Announcement",
          body: announcement.title ?? "An announcement was posted.",
        },
        data: {
          route: "announcement",
          timestamp: new Date().toISOString(),
        },
      });
    }

    return null;
  });

export default onAnnouncementCreated;
