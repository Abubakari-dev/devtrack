# DevTrack — Flutter App

> Developer Productivity Operating System

## Project Structure

```
lib/
├── core/
│   ├── theme/
│   │   └── app_theme.dart          # All colors, typography, theme
│   └── widgets/
│       └── shared_widgets.dart     # GlowButton, GlassCard, DevTextField, etc.
│
├── screens/
│   ├── splash/
│   │   └── splash_screen.dart      # Animated hex logo + terminal cursor
│   ├── onboarding/
│   │   └── onboarding_screen.dart  # 3 animated slides with custom illustrations
│   ├── auth/
│   │   ├── welcome_screen.dart     # Auth choice screen with floating cards
│   │   └── auth_screens.dart       # Login, SignUp, ForgotPassword screens
│   ├── dashboard/
│   │   └── dashboard_screen.dart   # Main home with animated productivity ring
│   ├── tasks/
│   │   ├── task_screens.dart       # TaskList + TaskDetail screens
│   │   └── create_task_screen.dart # Full create task form
│   ├── focus/
│   │   └── focus_screen.dart       # Pomodoro timer with animated ring
│   └── analytics/
│       └── analytics_screen.dart   # Charts, heatmap, insights
│
└── main.dart                       # App entry + routing
```

## Setup

```bash
# 1. Create Flutter project
flutter create devtrack
cd devtrack

# 2. Replace lib/ folder with this code

# 3. Install dependencies
flutter pub get

# 4. Run
flutter run
```

## Screens

| Screen | File | Key Features |
|---|---|---|
| Splash | `splash_screen.dart` | Hex logo, terminal cursor blink, grid bg |
| Onboarding | `onboarding_screen.dart` | 3 slides, custom canvas illustrations |
| Welcome | `welcome_screen.dart` | Floating task cards, dual CTA |
| Login | `auth_screens.dart` | Shake animation, biometric icon, remember me |
| Sign Up | `auth_screens.dart` | Password strength bar, GitHub OAuth |
| Forgot Password | `auth_screens.dart` | Countdown resend timer |
| Dashboard | `dashboard_screen.dart` | Animated progress ring, streak badge |
| Task List | `task_screens.dart` | Tabs, filters, priority borders |
| Task Detail | `task_screens.dart` | Subtasks, timer, timeline, notes |
| Create Task | `create_task_screen.dart` | Category grid, priority, estimate slider |
| Focus Timer | `focus_screen.dart` | Pomodoro ring with glow, ambient mode |
| Analytics | `analytics_screen.dart` | Line chart, heatmap, category bars |

## Design Tokens

```dart
// Colors
AppColors.bg         = #0D1117  // Background
AppColors.surface    = #161B22  // Cards
AppColors.blue       = #58A6FF  // Primary
AppColors.green      = #3FB950  // Success
AppColors.amber      = #D29922  // Warning
AppColors.red        = #F85149  // Critical/Error
AppColors.purple     = #BC8CFF  // Learning
```
