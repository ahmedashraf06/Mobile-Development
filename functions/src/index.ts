import * as functions from "firebase-functions/v1";
import {Resend} from "resend";
import fetch from "node-fetch";
export {
  default as onAnnouncementCreated,
} from "./notifications/onAnnouncementCreated.js";

export {
  default as onReportResolved,
} from "./notifications/onReportResolved.js";

export {
  default as onAdSubmitted,
} from "./notifications/admin_onAdSubmitted.js";

export {
  default as onReportSubmitted,
} from "./notifications/admin_onReportSubmitted.js";

export {
  default as onAnnouncementEdited,
} from "./notifications/onAnnouncementEdited.js";

export {
  default as onAnnouncementDeleted,
} from "./notifications/onAnnouncementDeleted.js";

const resend = new Resend(functions.config().resend.key);

export const sendConfirmationEmail = functions.https.onCall(
  async (data) => {
    const {email} = data;

    if (!email || typeof email !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Email is required and must be a string."
      );
    }

    try {
      const result = await resend.emails.send({
        from: "Balaghny <noreply@balaghny.online>",
        to: email,
        subject: "Your Ad Has Been Submitted",
        html: `
          <p>
            Thank you for submitting your advertisement!<br />
            We will review it and contact you soon.
          </p>
        `,

      });

      console.log("Email sent successfully:", result);
      return {success: true};
    } catch (error) {
      console.error("Email sending failed:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to send email."
      );
    }
  }
);

export const notifyAdStatusChange = functions.firestore
  .document("ads/{adId}")
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();

    const email = after.contactEmail;
    const title = after.title;

    if (before.status === after.status) return null;
    if (!["approved", "rejected"].includes(after.status)) return null;
    if (!email || !title) return null;

    let subject = "";
    if (after.status === "approved") {
      subject = "Ad Approved 🎉";
    } else {
      subject = "Ad Rejected ❌";
    }

    let html = "";
    if (after.status === "approved") {
      html =
        "<p>Congratulations! Your ad titled <b>\"" + title +
        "\"</b> has been approved and is now live on Balaghny.</p>";
    } else {
      html =
        "<p>Unfortunately, your ad titled <b>\"" + title +
        "\"</b> has been rejected. Please revise it and try again.</p>";
    }

    try {
      await resend.emails.send({
        from: "Balaghny <noreply@balaghny.online>",
        to: email,
        subject,
        html,
      });
      console.log(`Status update email sent to ${email}`);
    } catch (err) {
      console.error("Failed to send status update email", err);
    }

    return null;
  });


export const sendAdDeletedEmail = functions.https.onCall(async (data) => {
  const {email, title} = data;
  try {
    await resend.emails.send({
      from: "Balaghny <noreply@balaghny.online>",
      to: email,
      subject: "Ad Deleted by Admin",
      html: `
        <p>Hello,</p>
        <p>Your ad titled <strong>${title}</strong> has been deleted.</p>
        <p>If you have any questions, feel free to contact support.</p>
      `,
    });

    console.log(`Ad deletion email sent to ${email}`);
    return {success: true};
  } catch (error) {
    console.error("Failed to send ad deletion email", error);
    throw new functions.https.HttpsError("internal", "Failed to send email.");
  }
});
export const moderateComment = functions.https.onCall(async (data, context) => {
  const text = data.text as string;

  console.log("Received comment:", text);

  if (!text || typeof text !== "string") {
    console.log("Invalid comment format");
    return {allowed: false, reason: "Invalid comment"};
  }

  const PERSPECTIVE_API_KEY = "AIzaSyCkYtDJ7S1qAHqdCTthMFiQkq8Ssk8z3X0";

  try {
    const response = await fetch(
      `https://commentanalyzer.googleapis.com/v1alpha1/comments:analyze?key=
      ${PERSPECTIVE_API_KEY}`,
      {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({
          comment: {text},
          languages: ["en", "ar"],
          requestedAttributes: {
            TOXICITY: {},
            INSULT: {},
            PROFANITY: {},
          },
        }),
      }
    );

    const result = await response.json();
    console.log("Perspective result:", JSON.stringify(result, null, 2));

    const toxicity = result.attributeScores?.TOXICITY?.summaryScore?.value || 0;
    const insult = result.attributeScores?.INSULT?.summaryScore?.value || 0;
    const profanity = result.attributeScores?.PROFANITY?.summaryScore?.
      value || 0;

    const blocked = toxicity >= 0.3 || insult >= 0.3 || profanity >= 0.3;

    return {allowed: !blocked, score: {toxicity, insult, profanity}};
  } catch (error) {
    console.error("Perspective API error:", error);
    return {allowed: true, reason: "API error fallback"};
  }
});


