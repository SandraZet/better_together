# Push Notifications Implementation

## Overview
This implementation allows users to receive notifications when their submitted ideas are scheduled.

## How It Works

### User Flow
1. User submits an idea
2. First-time submitters see an opt-in dialog: "Get notified when your idea goes live!"
3. If they accept:
   - Android system permission dialog appears (Android 13+)
   - FCM token is collected and saved with their idea
4. When you schedule their idea via your Google Sheets SyncAll script, a Cloud Function automatically sends them a notification

### Data Stored
In Firebase `ideas` collection, each idea document now includes:
```javascript
{
  idea: "...",
  nickname: "...",
  location: "...",
  date: "2026-02-22",
  timestamp: <serverTimestamp>,
  fcmToken: "eXaMpLe_ToKeN...",  // Only if user opted in
  notificationSent: false         // Tracks if notification was sent
}
```

## Setup Instructions

### 1. Deploy Cloud Functions
```bash
cd functions
npm install
firebase deploy --only functions
```

### 2. Update Your Google Sheets SyncAll Script
Modify your script to assign `taskId` when syncing slots. The Cloud Function will automatically trigger when a slot is updated with a new `taskId`.

Example modification:
```javascript
// When syncing a slot back to Firebase
slotRef.update({
  taskId: ideaDocId,  // ID of the idea from 'ideas' collection
  headline: editedHeadline,
  // ... other fields
});
```

### 3. Firebase Console Setup
1. Go to Firebase Console → Project Settings → Cloud Messaging
2. Verify that your Android app is registered
3. No additional FCM configuration needed if you already have Firebase setup

### 4. Google Play Console - Data Safety Update

When you submit your next app update, declare in Data Safety:

**Data types collected:**
- ✅ Device or other IDs (FCM Token)

**Purpose:**
- App functionality - Notifications

**Data handling:**
- ☑ Optional (user can choose not to provide)
- ☑ Stored in Firebase
- ☐ Not shared with third parties
- ☐ Data can be deleted (will delete automatically when idea is processed)

## Testing

### Test Notification Manually
Use the test Cloud Function:
```bash
https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/sendTestNotification?token=USER_FCM_TOKEN
```

### Check FCM Tokens in Firebase
1. Open Firestore Database
2. Go to `ideas` collection
3. Look for documents with `fcmToken` field

### Debug Logs
View Cloud Function logs:
```bash
firebase functions:log
```

## User Preferences

Users can change notification preferences later (you can add this to settings):
```dart
// In settings screen
final notificationService = NotificationService();
await notificationService.setIdeaNotificationsOptIn(false); // Opt out
```

## Privacy Compliance

✅ Privacy policy updated (app & HTML)
✅ Opt-in consent dialog implemented
✅ Only stores token if user agrees
✅ Clear explanation of data usage

## Notification Message Format

When an idea is scheduled, users receive:

**Title:** 🎉 Your idea is live!  
**Body:** "[Idea text]" is scheduled for 2026-02-22 Morning!

## Cost Considerations

Firebase Cloud Messaging (FCM) is **free** for unlimited notifications.

Cloud Functions pricing:
- 2 million invocations/month free
- Each notification = 1 invocation
- Even with 1000 ideas/month, you'll stay in free tier

## Troubleshooting

**Notification not received?**
1. Check Firestore - does idea have `fcmToken`?
2. Check Cloud Function logs for errors
3. Verify Android permissions granted
4. Test with sendTestNotification function

**Permission denied?**
- User can enable in Android Settings → Apps → Better Together → Notifications

## Future Enhancements

Potential additions:
- Schedule notifications for day before idea goes live
- Remind users to complete their own scheduled tasks
- Weekly digest of community activity
