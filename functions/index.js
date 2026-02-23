/**
 * Cloud Function to send push notifications when ideas are scheduled
 * 
 * This function triggers when a slot document is updated.
 * It checks if a task with an FCM token has been assigned to the slot,
 * and sends a push notification to the user who submitted the idea.
 * 
 * Deploy with: firebase deploy --only functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Initialize Firestore with custom database ID
const db = admin.firestore();
db.settings({ databaseId: 'nowdb' });

/**
 * Send notification when a slot is updated with a new task
 * Triggered when slots/{slotId} is updated
 */
exports.notifyIdeaScheduled = functions.firestore
  .database('nowdb')
  .document('slots/{slotId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    const slotId = context.params.slotId;

    // Check if taskId changed (new task was assigned)
    if (!newData.taskId || newData.taskId === oldData.taskId) {
      console.log('No new task assigned, skipping notification');
      return null;
    }

    const taskId = newData.taskId;
    console.log(`New task ${taskId} assigned to slot ${slotId}`);

    try {
      // Step 1: Get the task document to find the ideaId
      const taskRef = db.collection('tasks').doc(taskId);
      const taskDoc = await taskRef.get();
      
      if (!taskDoc.exists) {
        console.log(`Task document ${taskId} not found`);
        return null;
      }
      
      const taskData = taskDoc.data();
      console.log(`Task ${taskId} data:`, JSON.stringify(taskData));
      const ideaId = taskData.ideaId;
      
      if (!ideaId) {
        console.log(`Task ${taskId} has no ideaId - not submitted by user`);
        console.log(`Available fields:`, Object.keys(taskData));
        return null;
      }
      
      console.log(`Found ideaId: ${ideaId} for task ${taskId}`);
      
      // Step 2: Get the idea document to find the FCM token
      const ideaRef = db.collection('ideas').doc(ideaId);
      const ideaDoc = await ideaRef.get();

      if (!ideaDoc.exists) {
        console.log(`Idea document ${ideaId} not found`);
        return null;
      }

      const ideaData = ideaDoc.data();
      
      // Check if FCM token exists
      if (!ideaData.fcmToken) {
        console.log('No FCM token found, user did not opt-in');
        return null;
      }

      // Parse slot info from slotId (format: YYYY-MM-DD_morning)
      const [date, slot] = slotId.split('_');
      const slotNames = {
        morning: 'morning',
        noon: 'noon', 
        afternoon: 'afternoon'
      };
      const slotName = slotNames[slot] || slot;

      // Format date nicely
      const dateObj = new Date(date);
      const options = { weekday: 'long', month: 'long', day: 'numeric' };
      const formattedDate = dateObj.toLocaleDateString('en-US', options);

      // Build notification payload - use headline from task, not original idea text
      const message = {
        token: ideaData.fcmToken,
        notification: {
          title: '🎉 Your idea goes live!',
          body: `"${taskData.headline}"\n\nScheduled for ${formattedDate} in the ${slotName} slot. Thanks!`
        },
        data: {
          slotId: slotId,
          taskId: taskId,
          date: date,
          slot: slot,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          route: '/slot'
        },
        android: {
          priority: 'normal', // silent delivery — may arrive at night
          notification: {
            channelId: 'idea_silent',
            icon: 'ic_notification',
            color: '#EC407A',
            defaultSound: false,
            defaultVibrateTimings: false,
            notificationPriority: 'PRIORITY_LOW'
          }
        }
      };

      // Send notification
      await admin.messaging().send(message);
      console.log(`Silent scheduling notification sent to ${ideaData.nickname} for slot ${slotId}`);

      return null;
    } catch (error) {
      console.error('Error sending notification:', error);
      return null;
    }
  });

/**
 * Manual function to send a test notification
 * Call this via HTTP: https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/sendTestNotification?token=YOUR_FCM_TOKEN
 */
exports.sendTestNotification = functions.https.onRequest(async (req, res) => {
  const token = req.query.token;
  
  if (!token) {
    res.status(400).send('Missing token parameter');
    return;
  }

  const message = {
    token: token,
    notification: {
      title: 'Test Notification',
      body: 'This is a test from Better Together!'
    }
  };

  try {
    await admin.messaging().send(message);
    res.send('Test notification sent successfully!');
  } catch (error) {
    console.error('Error:', error);
    res.status(500).send('Error sending notification: ' + error.message);
  }
});

// =============================================================================
// SLOT-START NOTIFICATIONS
// Fires when UTC+14 (first timezone on Earth) hits each slot start time.
// Slot documents are keyed by the LOCAL date, so at the moment of firing we
// compute the UTC+14 date — that is the document the UTC+14 user is seeing.
// Silent notification, so arrival time for other timezones doesn't matter.
//
// UTC+14 slot times → UTC:
//   Morning   05:00 UTC+14 = 15:00 UTC  (cron: 0 15 * * *)
//   Noon      12:00 UTC+14 = 22:00 UTC  (cron: 0 22 * * *)
//   Afternoon 17:00 UTC+14 = 03:00 UTC  (cron: 0 3  * * *)
//   Night     22:00 UTC+14 = 08:00 UTC  (cron: 0 8  * * *)
// =============================================================================

/**
 * Returns the current date as "YYYY-MM-DD" in UTC+14.
 * Slot documents are keyed by the date the user experiences locally,
 * and UTC+14 is the first timezone to reach any given slot start time.
 */
function getCurrentUtcPlus14Date() {
  const utcPlus14 = new Date(Date.now() + 14 * 60 * 60 * 1000);
  const y = utcPlus14.getUTCFullYear();
  const m = String(utcPlus14.getUTCMonth() + 1).padStart(2, '0');
  const d = String(utcPlus14.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

/**
 * Core helper: look up today's slot, find the user's idea, and send the
 * "your slot just started" notification. Uses a separate deduplication flag
 * (slotStartNotificationSent) so this never conflicts with notifyIdeaScheduled.
 */
async function sendSlotStartNotification(slotName) {
  const date = getCurrentUtcPlus14Date();
  const slotId = `${date}_${slotName}`;
  console.log(`[slotStart] Processing ${slotId}`);

  try {
    const slotDoc = await db.collection('slots').doc(slotId).get();
    if (!slotDoc.exists || !slotDoc.data().taskId) {
      console.log(`No slot/task for ${slotId}`);
      return null;
    }

    const taskDoc = await db.collection('tasks').doc(slotDoc.data().taskId).get();
    if (!taskDoc.exists || !taskDoc.data().ideaId) {
      console.log(`Task missing or not user-submitted for ${slotId}`);
      return null;
    }

    const ideaRef = db.collection('ideas').doc(taskDoc.data().ideaId);
    const ideaDoc = await ideaRef.get();
    if (!ideaDoc.exists) return null;

    const ideaData = ideaDoc.data();
    if (!ideaData.fcmToken) {
      console.log(`No FCM token for idea ${taskDoc.data().ideaId}`);
      return null;
    }

    // Deduplicate: only send this notification once per slot
    if (ideaData.slotStartNotificationSent === true) {
      console.log(`Slot-start notification already sent for ${slotId}, skipping`);
      return null;
    }

    const slotLabel = {
      morning: 'Morning (5 am)',
      noon: 'Noon (12 pm)',
      afternoon: 'Afternoon (5 pm)',
      night: 'Night (10 pm)',
    }[slotName] || slotName;

    const slotTime = {
      morning: '5:00 am',
      noon: '12:00 pm',
      afternoon: '5:00 pm',
      night: '10:00 pm',
    }[slotName] || slotName;

    const taskData = taskDoc.data();

    await admin.messaging().send({
      token: ideaData.fcmToken,
      notification: {
        title: '🌍 Your idea just went live!',
        body: `"${taskData.headline}" — It's ${slotTime} in UTC+14 already. Wait for your timezone to catch up!`,
      },
      data: {
        slotId,
        taskId: slotDoc.data().taskId,
        date,
        slot: slotName,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        route: '/slot',
      },
      android: {
        priority: 'normal', // silent — no sound or vibration
        notification: {
          channelId: 'idea_silent',
          icon: 'ic_notification',
          color: '#EC407A',
          defaultSound: false,
          defaultVibrateTimings: false,
          notificationPriority: 'PRIORITY_LOW',
        },
      },
    });

    console.log(`[slotStart] Sent to ${ideaData.nickname || 'user'} for ${slotId}`);

    await ideaRef.update({
      slotStartNotificationSent: true,
      slotStartNotifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      slotStartNotifiedSlotId: slotId,
    });

    return null;
  } catch (error) {
    console.error(`[slotStart] Error for ${slotName}:`, error);
    return null;
  }
}

/** Morning:   05:00 UTC+14 = 15:00 UTC */
exports.notifyMorningSlotStart = functions.pubsub
  .schedule('0 15 * * *')
  .timeZone('UTC')
  .onRun(() => sendSlotStartNotification('morning'));

/** Noon:      12:00 UTC+14 = 22:00 UTC */
exports.notifyNoonSlotStart = functions.pubsub
  .schedule('0 22 * * *')
  .timeZone('UTC')
  .onRun(() => sendSlotStartNotification('noon'));

/** Afternoon: 17:00 UTC+14 = 03:00 UTC */
exports.notifyAfternoonSlotStart = functions.pubsub
  .schedule('0 3 * * *')
  .timeZone('UTC')
  .onRun(() => sendSlotStartNotification('afternoon'));

/** Night:     22:00 UTC+14 = 08:00 UTC */
exports.notifyNightSlotStart = functions.pubsub
  .schedule('0 8 * * *')
  .timeZone('UTC')
  .onRun(() => sendSlotStartNotification('night'));
