"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onWorkerTokenUpdated = exports.onNewJobCreated = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const firestore_2 = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
// ─── Helper: Haversine distance in kilometers ────────────────────────────────
function haversineKm(lat1, lon1, lat2, lon2) {
    const R = 6371;
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLon = ((lon2 - lon1) * Math.PI) / 180;
    const a = Math.sin(dLat / 2) ** 2 +
        Math.cos((lat1 * Math.PI) / 180) *
            Math.cos((lat2 * Math.PI) / 180) *
            Math.sin(dLon / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}
// ─── Cloud Function: Notify nearby workers when a new job is created ──────────
exports.onNewJobCreated = (0, firestore_1.onDocumentCreated)("jobs/{jobId}", async (event) => {
    var _a, _b, _c, _d, _e, _f;
    const snapshot = event.data;
    if (!snapshot)
        return;
    const job = snapshot.data();
    const jobId = event.params.jobId;
    // Only notify for pending jobs
    if (job["status"] !== "pending") {
        console.log(`Job ${jobId} is not pending. Skipping.`);
        return;
    }
    const jobLat = (_a = job["customerLat"]) !== null && _a !== void 0 ? _a : 0;
    const jobLng = (_b = job["customerLng"]) !== null && _b !== void 0 ? _b : 0;
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
    const notificationPromises = [];
    for (const workerDoc of workersSnap.docs) {
        const worker = workerDoc.data();
        const fcmToken = worker["fcmToken"];
        const workerLat = worker["lat"];
        const workerLng = worker["lng"];
        if (!fcmToken || workerLat === undefined || workerLng === undefined) {
            continue;
        }
        const distance = haversineKm(jobLat, jobLng, workerLat, workerLng);
        if (distance > RADIUS_KM)
            continue;
        console.log(`Notifying worker ${workerDoc.id} (${distance.toFixed(1)} km away)`);
        const message = {
            token: fcmToken,
            notification: {
                title: `New ${(_c = job["category"]) !== null && _c !== void 0 ? _c : "Job"} Nearby!`,
                body: `${job["title"]} • ${distance.toFixed(1)} km • Est. Rs. ${job["estimatedPrice"]}`,
            },
            data: {
                jobId: jobId,
                jobTitle: String((_d = job["title"]) !== null && _d !== void 0 ? _d : ""),
                category: String((_e = job["category"]) !== null && _e !== void 0 ? _e : ""),
                urgency: String((_f = job["urgency"]) !== null && _f !== void 0 ? _f : "Normal"),
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
});
// ─── Optional: Log FCM token changes ─────────────────────────────────────────
exports.onWorkerTokenUpdated = (0, firestore_2.onDocumentUpdated)("workers/{workerId}", async (event) => {
    var _a, _b;
    const before = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
    const after = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
    if (!before || !after)
        return;
    if (before["fcmToken"] !== after["fcmToken"] && before["fcmToken"]) {
        console.log(`FCM token refreshed for worker ${event.params.workerId}`);
    }
});
//# sourceMappingURL=index.js.map