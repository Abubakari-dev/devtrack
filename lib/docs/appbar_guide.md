# AppBar Usage Guide

## Overview
The project now uses custom AppBar components optimized for iPhone displays with centered titles, clean design, and better spacing.

## Components

### 1. CustomAppBar
Standard AppBar for most screens with a clean, centered design.

```dart
import '../../../core/widgets/custom_app_bar.dart';

Scaffold(
  appBar: CustomAppBar(
    title: 'Screen Title',
    // Optional parameters:
    actions: [IconButton(...)],
    showBackButton: true,
    onBackPressed: () => Navigator.pop(context),
  ),
)
```

### 2. CustomSliverAppBar
For scrollable screens with collapsing headers.

```dart
CustomScrollView(
  slivers: [
    CustomSliverAppBar(
      title: 'Screen Title',
      expandedHeight: 120,
      pinned: true,
      floating: false,
      actions: [IconButton(...)],
    ),
    // Other slivers...
  ],
)
```

## Features

- **Centered titles** - All titles are centered by default
- **Consistent sizing** - 17pt font size (iOS standard)
- **Proper spacing** - 56pt toolbar height
- **Clean borders** - Subtle bottom border for separation
- **Back button** - iOS-style back button with proper sizing
- **Safe area** - Respects device notches and status bars

## Migration Examples

### Before:
```dart
AppBar(
  title: Text('My Screen'),
  centerTitle: true,
)
```

### After:
```dart
CustomAppBar(
  title: 'My Screen',
)
```

## Customization

### Custom Background Color
```dart
CustomAppBar(
  title: 'Screen Title',
  backgroundColor: AppColors.surface,
)
```

### Custom Leading Widget
```dart
CustomAppBar(
  title: 'Screen Title',
  leading: IconButton(
    icon: Icon(Icons.menu),
    onPressed: () => _openDrawer(),
  ),
  showBackButton: false,
)
```

### With Actions
```dart
CustomAppBar(
  title: 'Screen Title',
  actions: [
    IconButton(
      icon: Icon(Icons.search),
      onPressed: () => _search(),
    ),
    IconButton(
      icon: Icon(Icons.more_vert),
      onPressed: () => _showMenu(),
    ),
  ],
)
```

## Design Principles

1. **Simplicity** - Clean, minimal design
2. **Consistency** - Same look across all screens
3. **iOS-optimized** - Follows iOS design guidelines
4. **Accessibility** - Proper touch targets and contrast
5. **Performance** - Lightweight and efficient
