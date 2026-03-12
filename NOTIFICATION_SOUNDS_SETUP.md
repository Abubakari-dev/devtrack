# Notification Sounds Setup Guide

Your notification service has been updated to support custom notification sounds like SMS! Follow these steps to add sound files to your project.

## 📱 What's Been Updated

✅ Added custom sound support to all notification channels
✅ Different sounds for different notification types:
- `critical_alert.wav` - Critical alerts (payment overdue, project overdue)
- `payment_sound.wav` - Payment notifications
- `project_alert.wav` - Project deadlines and updates
- `reminder_tone.wav` - Task reminders
- `success_sound.wav` - Success notifications (completion, payment received)
- `finance_alert.wav` - Finance and budget alerts
- `notification_gentle.wav` - Daily summaries
- `notification_soft.wav` - General updates

## 🔧 Setup Instructions

### Step 1: Get Sound Files

You have two options:

#### Option A: Use Default System Sounds (Easiest)
Remove the custom sound lines and the notifications will use the default system sound (already sounds like SMS).

#### Option B: Add Custom Sound Files

1. **Download or create sound files** (WAV or MP3 format, keep them under 30 seconds)
   - You can download free notification sounds from:
     - https://notificationsounds.com/
     - https://freesound.org/
     - https://mixkit.co/free-sound-effects/notification/

2. **For Android:**
   - Create folder: `android/app/src/main/res/raw/`
   - Add your sound files (must be lowercase, no spaces):
     ```
     android/app/src/main/res/raw/
       ├── critical_alert.wav
       ├── payment_sound.wav
       ├── project_alert.wav
       ├── reminder_tone.wav
       ├── success_sound.wav
       ├── finance_alert.wav
       ├── notification_gentle.wav
       └── notification_soft.wav
     ```

3. **For iOS:**
   - Open your project in Xcode
   - Add sound files to `Runner` folder
   - Make sure "Copy items if needed" is checked
   - Add to target: Runner
   - Sound files must be in WAV, AIFF, or CAF format

### Step 2: Test Notifications

Run this command to test:
```bash
flutter run
```

Then trigger a notification to hear the custom sound!

## 🎵 Sound File Requirements

### Android
- Format: WAV, MP3, OGG
- Max duration: 30 seconds (recommended: 2-5 seconds)
- Filename: lowercase, no spaces, no special characters
- Location: `android/app/src/main/res/raw/`

### iOS
- Format: WAV, AIFF, CAF (Linear PCM or IMA4)
- Max duration: 30 seconds
- Sample rate: 8-48 kHz
- Location: Add to Xcode project in Runner folder

## 🚀 Quick Start (Use Default Sounds)

If you want to use the default system sound (which already sounds like SMS), you can simplify by removing the custom sound configuration. The notifications will automatically use the system default sound which is similar to SMS notifications.

## 🔔 Notification Types & Their Sounds

| Notification Type | Sound File | When It Plays |
|------------------|------------|---------------|
| Payment Overdue | critical_alert | When payment is overdue |
| Project Overdue | critical_alert | When project deadline passed |
| Budget Exceeded | critical_alert | When budget is exceeded |
| Payment Due | payment_sound | Payment reminder |
| Project Deadline | project_alert | 3 days before deadline |
| Task Reminder | reminder_tone | Task reminders |
| Project Completed | success_sound | When project is completed |
| Payment Received | success_sound | When payment is received |
| Budget Warning | finance_alert | When 80% of budget is used |
| Daily Summary | notification_gentle | Daily reports |
| General Updates | notification_soft | App updates |

## 📝 Notes

- Sounds play automatically when notifications are shown
- Each notification channel has its own sound
- Vibration patterns are also configured for each type
- LED colors are set for visual alerts (Android)
- iOS uses interruption levels (critical, timeSensitive, passive)

## 🐛 Troubleshooting

**Sound not playing?**
1. Check device is not in silent mode
2. Check notification permissions are granted
3. Verify sound files are in correct folders
4. Check file names match exactly (case-sensitive)
5. For Android: Uninstall and reinstall app after adding sounds

**iOS sound not working?**
1. Sound files must be in WAV, AIFF, or CAF format
2. Files must be added to Xcode project
3. Check "Copy items if needed" was selected
4. Verify files are in Runner target

## ✅ Current Status

Your notification service is now configured with:
- ✅ Custom sounds for each notification type
- ✅ Vibration patterns
- ✅ LED colors (Android)
- ✅ Priority levels
- ✅ Full-screen intents for critical alerts
- ✅ iOS interruption levels

Just add the sound files to complete the setup!
