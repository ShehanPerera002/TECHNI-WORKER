import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ─── Helper: Haversine distance in kilometers ────────────────────────────────
function haversineKm(
  lat1: number, lon1: number,
  lat2: number, lon2: number
): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
    Math.cos((lat2 * Math.PI) / 180) *
    Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// ─── Cloud Function: Notify nearby workers when a new job is created ──────────
export const onNewJobCreated = onDocumentCreated(
  "jobs/{jobId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const job = snapshot.data();
    const jobId = event.params.jobId;

    // Only notify for pending jobs
    if (job["status"] !== "pending") {
      console.log(`Job ${jobId} is not pending. Skipping.`);
      return;
    }

    const jobLat: number = job["customerLat"] ?? 0;
    const jobLng: number = job["customerLng"] ?? 0;
    const RADIUS_KM = 10;

    console.log(`New job ${jobId} at (${jobLat}, ${jobLng}). Finding nearby workers...`);

    // Query online, non-DND workers
    const workersSnap = await db
      .collection("workers")
      .where("isOnline", "==", true)
      .where("doNotDisturb", "==", false)
      .get();

    if (workersSnap.empty) {
      console.log("No online workers found.");
      return;
    }

    const notificationPromises: Promise<string>[] = [];

    for (const workerDoc of workersSnap.docs) {
      const worker = workerDoc.data();
      const fcmToken: string | undefined = worker["fcmToken"];
      const workerLat: number | undefined = worker["lat"];
      const workerLng: number | undefined = worker["lng"];

      if (!fcmToken || workerLat === undefined || workerLng === undefined) {
        continue;
      }

      const distance = haversineKm(jobLat, jobLng, workerLat, workerLng);
      if (distance > RADIUS_KM) continue;

      console.log(`Notifying worker ${workerDoc.id} (${distance.toFixed(1)} km away)`);

      const message: admin.messaging.Message = {
        token: fcmToken,
        notification: {
          title: `New ${job["category"] ?? "Job"} Nearby!`,
          body: `${job["title"]} • ${distance.toFixed(1)} km • Est. Rs. ${job["estimatedPrice"]}`,
        },
        data: {
          jobId: jobId,
          jobTitle: String(job["title"] ?? ""),
          category: String(job["category"] ?? ""),
          urgency: String(job["urgency"] ?? "Normal"),
          customerLat: String(jobLat),
          customerLng: String(jobLng),
        },
        android: {
          priority: "high",
          notification: {
            channelId: "job_requests",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      notificationPromises.push(messaging.send(message));
    }

    if (notificationPromises.length === 0) {
      console.log("No eligible nearby workers.");
      return;
    }

    const results = await Promise.allSettled(notificationPromises);
    const succeeded = results.filter((r) => r.status === "fulfilled").length;
    const failed = results.filter((r) => r.status === "rejected").length;
    console.log(`Notifications: ${succeeded} sent, ${failed} failed.`);
  }
);

// ─── Optional: Log FCM token changes ─────────────────────────────────────────
export const onWorkerTokenUpdated = onDocumentUpdated(
  "workers/{workerId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    if (before["fcmToken"] !== after["fcmToken"] && before["fcmToken"]) {
      console.log(`FCM token refreshed for worker ${event.params.workerId}`);
    }
  }
);

// ─── Cloud Function: Notify worker when customer confirms them ────────────────
export const onJobConfirmed = onDocumentUpdated(
  "jobs/{jobId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    // Only trigger when status changes TO 'confirmed'
    if (before["status"] === "confirmed" || after["status"] !== "confirmed") {
      return;
    }

    const workerId: string | undefined = after["workerId"];
    const jobId = event.params.jobId;

    if (!workerId) {
      console.log(`Job ${jobId} confirmed but no workerId assigned.`);
      return;
    }

    console.log(`Job ${jobId} confirmed for worker ${workerId}. Sending notification...`);

    // Get the worker's FCM token
    const workerDoc = await db.collection("workers").doc(workerId).get();
    if (!workerDoc.exists) {
      console.log(`Worker ${workerId} not found.`);
      return;
    }

    const workerData = workerDoc.data();
    const fcmToken: string | undefined = workerData?.["fcmToken"];

    if (!fcmToken) {
      console.log(`Worker ${workerId} has no FCM token.`);
      return;
    }

    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title: "You've been selected! 🎉",
        body: `${after["customerName"] ?? "A customer"} needs ${after["title"] ?? "your service"}. Tap to navigate.`,
      },
      data: {
        jobId: jobId,
        jobTitle: String(after["title"] ?? ""),
        category: String(after["category"] ?? ""),
        customerLat: String(after["customerLat"] ?? ""),
        customerLng: String(after["customerLng"] ?? ""),
        customerName: String(after["customerName"] ?? ""),
        customerPhone: String(after["customerPhone"] ?? ""),
      },
      android: {
        priority: "high",
        notification: {
          channelId: "job_confirmed",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    try {
      await messaging.send(message);
      console.log(`Confirmation notification sent to worker ${workerId}.`);
    } catch (err) {
      console.error(`Failed to send confirmation notification: ${err}`);
    }
  }
);
