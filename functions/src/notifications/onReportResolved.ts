import {firestore} from "firebase-functions/v1";
import {getApps, initializeApp, applicationDefault} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";

if (!getApps().length) {
  initializeApp({credential: applicationDefault()});
}

const db = getFirestore();

const onReportResolved = firestore
  .document("reports/{reportId}")
  .onUpdate(async (change, _context) => {
    const beforeStatus = change.before.data()?.status;
    const afterStatus = change.after.data()?.status;

    if (beforeStatus !== "approved" && afterStatus === "approved") {
      const reportData = change.after.data();
      if (!reportData) return null;

      const submittedEmail = reportData.submittedBy;
      const reportTitle = reportData.title ?? "a report";

      // 🔍 Look up UID from users collection by submittedBy (email)
      const usersSnapshot = await db
        .collection("users")
        .where("email", "==", submittedEmail)
        .limit(1)
        .get();

      if (usersSnapshot.empty) {
        console.warn(`No user found with email: ${submittedEmail}`);
        return null;
      }

      const userDoc = usersSnapshot.docs[0];
      const uid = userDoc.id;

      await db
        .collection("notifications")
        .doc(uid)
        .collection("userNotifications")
        .add({
          title: "Problem Resolved",
          body: `Your reported problem "${reportTitle}" has been solved.`,
          type: "report",
          createdAt: FieldValue.serverTimestamp(),
          isRead: false,
        });

      console.log(`Notification sent to ${uid} for resolved report.`);
    }

    return null;
  });

export default onReportResolved;
