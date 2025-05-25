import {firestore} from "firebase-functions/v1";
import {getApps, initializeApp, applicationDefault} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";

if (!getApps().length) {
  initializeApp({credential: applicationDefault()});
}

const db = getFirestore();

const onAdSubmitted = firestore
  .document("ads/{adId}")
  .onCreate(async (snap) => {
    const ad = snap.data();
    if (!ad) return null;

    const title = ad.title ?? "New Advertisement";
    const rawRegion = ad.region ?? "a region";
    const region = rawRegion
      .replace(/([a-z])([A-Z])/g, "$1 $2")
      .replace(/^./, (c: string) => c.toUpperCase());


    await db.collection("adminNotifications").add({
      title: "New Ad Approval Request",
      body: `A new ad "${title}" was submitted in ${region}.`,
      type: "ad",
      createdAt: FieldValue.serverTimestamp(),
      isRead: false,
    });

    return null;
  });

export default onAdSubmitted;
