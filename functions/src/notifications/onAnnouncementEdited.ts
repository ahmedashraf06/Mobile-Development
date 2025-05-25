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

const onAnnouncementEdited = firestore
  .document("announcements/{announcementId}")
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!before || !after) return null;

    const changes: string[] = [];
    if (before.title !== after.title) changes.push("title");
    if (before.details !== after.details) changes.push("details");
    if (before.attachment !== after.attachment) changes.push("attachment");
    if (before.category !== after.category) changes.push("category");
    if (before.region !== after.region) changes.push("region");

    if (changes.length === 0) return null;

    const fieldMap: Record<string, string> = {
      title: "title",
      details: "details",
      attachment: "photo or file",
      category: "category",
      region: "region",
    };

    const readableChanges = changes
      .filter((c) => c !== "title")
      .map((c) => fieldMap[c]);

    let changeSummary = "";
    if (readableChanges.length > 0) {
      const last = readableChanges.pop();
      changeSummary = readableChanges.length ?
        ` The ${readableChanges.join(", ")} and ${last} were also updated.` :
        ` The ${last} was also updated.`;
    }

    const bodyText =
      before.title !== after.title ?
        `The announcement titled "${before.title}" 
        was changed to "${after.title}".${changeSummary}` :
        `The announcement titled "${after.title}" was updated.${changeSummary}`;

    const normalizedRegion = normalizeRegion(after.region);
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
        title: "Announcement Edited",
        body: bodyText,
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
          title: "Announcement Edited",
          body: bodyText,
        },
        data: {
          route: "announcement",
          timestamp: new Date().toISOString(),
        },
      });
    }

    return null;
  });

export default onAnnouncementEdited;
