import {firestore} from "firebase-functions/v1";
import {getApps, initializeApp, applicationDefault} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";

if (!getApps().length) {
  initializeApp({credential: applicationDefault()});
}

const db = getFirestore();

const onReportSubmitted = firestore
  .document("reports/{reportId}")
  .onCreate(async (snap) => {
    const report = snap.data();
    if (!report) return null;

    const category = report.category ?? "general";
    const title = report.title ?? "New Report";

    await db.collection("adminNotifications").add({
      title: "New Report Submitted",
      body: `A new ${category} report "${title}" was submitted.`,
      type: "report",
      createdAt: FieldValue.serverTimestamp(),
      isRead: false,
    });

    return null;
  });

export default onReportSubmitted;
