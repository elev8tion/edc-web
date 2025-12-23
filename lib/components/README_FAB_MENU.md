# Glassmorphic FAB Navigation Menu

A custom, brand-focused navigation menu that replaces traditional drawer navigation with a modern floating action button approach.

## Features

✅ **Brand Identity** - Uses your app logo instead of generic icons
✅ **Glassmorphic Design** - Matches your existing blur_dropdown styling
✅ **Full-Screen Blur** - Beautiful backdrop when menu opens
✅ **Smooth Animations** - Staggered menu item animations
✅ **Responsive** - Adapts to mobile, tablet, and desktop
✅ **Haptic Feedback** - Tactile response on interactions
✅ **8 Navigation Routes** - Quick access to all major features

## Implementation

### Basic Usage

The component is already integrated into `HomeScreen`:

```dart
import '../components/glassmorphic_fab_menu.dart';

Scaffold(
  body: YourContent(),
  floatingActionButton: const GlassmorphicFABMenu(),
)
```

### Adding to Other Screens

Simply add the FAB to any screen's Scaffold:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Your Screen')),
    body: YourBody(),
    floatingActionButton: const GlassmorphicFABMenu(),
  );
}
```

## Customization

### Modifying Menu Items

Edit the `_menuOptions` list in `glassmorphic_fab_menu.dart`:

```dart
final List<MenuOption> _menuOptions = [
  MenuOption(
    title: "Your Feature",
    icon: Icons.your_icon,
    color: Colors.yourColor,
    route: AppRoutes.yourRoute,
  ),
  // Add more items...
];
```

### Changing Logo

Replace the logo in `assets/images/logo_transparent.png` or update the path:

```dart
Image.asset(
  'assets/images/your_logo.png',  // Change this
  width: 36,
  height: 36,
)
```

### Adjusting Animations

Modify the animation duration in `initState`:

```dart
_controller = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 700),  // Adjust speed
);
```

### Styling Menu Items

Update the glassmorphic styling in `_buildMenuItem`:

```dart
decoration: BoxDecoration(
  borderRadius: BorderRadius.circular(24),  // Corner radius
  gradient: LinearGradient(
    colors: [
      Colors.white.withValues(alpha: 0.2),  // Transparency
      Colors.white.withValues(alpha: 0.1),
    ],
  ),
  border: Border.all(
    color: Colors.white.withValues(alpha: 0.3),  // Border
    width: 1.5,
  ),
)
```

## Responsive Behavior

- **Mobile (< 480px)**: Menu items at 85% scale
- **Tablet (480-895px)**: Full size
- **Desktop (> 895px)**: Menu items at 120% scale

Spacing and positioning automatically adjust using `ResponsiveUtils`.

## Navigation Routes

Current menu includes:

1. **Bible Reading** - Browse and read Bible chapters
2. **AI Guidance** - Chat with AI for biblical wisdom
3. **Prayer Journal** - Track prayers and answered prayers
4. **Daily Devotional** - Daily spiritual reflections
5. **Reading Plans** - Structured Bible reading
6. **Verse Library** - Search saved verses
7. **Profile** - User profile and stats
8. **Settings** - App configuration

## User Experience

### Opening Menu
- Tap logo FAB → Haptic feedback + menu animates in
- Backdrop blur fades in
- Menu items slide up with stagger effect

### Selecting Option
- Tap menu item → Light haptic feedback
- Menu animates closed
- Navigate to selected route after 300ms

### Closing Menu
- Tap anywhere outside menu items
- Menu animates closed smoothly

## Performance

- Uses `RepaintBoundary` for optimization
- `BackdropFilter` with cached blur
- Overlay system prevents unnecessary rebuilds
- Staggered animations use `CurvedAnimation`

## Accessibility

- Haptic feedback for tactile users
- High contrast menu items
- Large touch targets (200x56 dp)
- Semantic color coding per feature

## Troubleshooting

### Logo Not Showing
Check that `assets/images/logo_transparent.png` exists and is listed in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/images/logo_transparent.png
```

### Navigation Not Working
Verify routes are defined in `app_routes.dart` and registered in `main.dart`.

### Animations Stuttering
- Reduce blur sigma values
- Simplify menu item designs
- Test on physical device (simulator can lag)

## Future Enhancements

Potential additions:
- [ ] Badge notifications on menu items
- [ ] Long-press for additional actions
- [ ] User-customizable menu order
- [ ] Recent/favorite items at top
- [ ] Search filter for menu items
- [ ] Swipe gestures to open/close
- [ ] Theme-aware colors (dark/light mode)

## Credits

Created for **Everyday Christian** app
Design: Glassmorphic UI with modern Flutter
Animation: Staggered reveal with easing curves
