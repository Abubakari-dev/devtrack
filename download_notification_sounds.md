# Quick Sound Files Setup

## Option 1: Use System Default Sound (Recommended - Easiest!)

Your notifications are already configured to play sounds! The default system sound on Android and iOS already sounds like SMS notifications. No additional setup needed!

Just make sure:
1. Device is not in silent mode
2. Notification permissions are granted
3. App has been initialized with `EnhancedNotificationService.instance.init()`

## Option 2: Add Custom Sounds

If you want different sounds for different notification types, follow these steps:

### For Android:

1. Create the raw resources folder:
```bash
mkdir -p android/app/src/main/res/raw
```

2. Download free notification sounds from these sites:
   - https://notificationsounds.com/ (Free, no attribution required)
   - https://mixkit.co/free-sound-effects/notification/ (Free license)
   - https://freesound.org/ (Creative Commons)

3. Rename and place files in `android/app/src/main/res/raw/`:
   - critical_alert.wav (or .mp3)
   - payment_sound.wav
   - project_alert.wav
   - reminder_tone.wav
   - success_sound.wav
   - finance_alert.wav
   - notification_gentle.wav
   - notification_soft.wav

4. File requirements:
   - Lowercase names only
   - No spaces or special characters
   - Format: WAV, MP3, or OGG
   - Duration: 2-5 seconds recommended

### For iOS:

1. Open your project in Xcode:
```bash
open ios/Runner.xcworkspace
```

2. In Xcode:
   - Right-click on "Runner" folder
   - Select "Add Files to Runner"
   - Select your sound files
   - Check "Copy items if needed"
   - Make sure "Runner" target is selected

3. File requirements:
   - Format: WAV, AIFF, or CAF
   - Linear PCM or IMA4 encoding
   - Duration: 2-5 seconds recommended

## Recommended Free Sounds

Here are some good free notification sounds you can use:

### Critical Alerts (Urgent)
- Search for: "alarm", "urgent", "alert"
- Example: https://notificationsounds.com/notification-sounds/alarm-frenzy-493

### Payment Sounds
- Search for: "cash register", "coin", "cha-ching"
- Example: https://notificationsounds.com/notification-sounds/cash-register-purchase-87

### Project Alerts
- Search for: "notification", "alert", "bell"
- Example: https://notificationsounds.com/notification-sounds/definite-555

### Reminders
- Search for: "reminder", "gentle", "soft bell"
- Example: https://notificationsounds.com/notification-sounds/pristine-609

### Success Sounds
- Search for: "success", "complete", "achievement"
- Example: https://notificationsounds.com/notification-sounds/accomplished-579

### Finance Alerts
- Search for: "money", "coins", "cash"
- Example: https://notificationsounds.com/notification-sounds/coins-497

## Testing Your Sounds

After adding sound files, test them:

```dart
// In your app, trigger a test notification
await EnhancedNotificationService.instance.showNotification(
  type: NotificationType.paymentDue,
  title: 'Test Notification',
  body: 'Testing custom sound!',
);
```

## Important Notes

1. **Android**: After adding sound files to `res/raw/`, you must uninstall and reinstall the app for sounds to work
2. **iOS**: Sound files must be added through Xcode, not just copied to the folder
3. **File Size**: Keep sounds under 1MB for best performance
4. **Duration**: 2-5 seconds is ideal for notification sounds

## Already Working!

Your notification service is already configured with:
- ✅ Sound enabled for all notification types
- ✅ Vibration patterns
- ✅ LED colors (Android)
- ✅ Priority levels
- ✅ Full-screen intents for critical alerts

The default system sound will play even without custom sound files!
