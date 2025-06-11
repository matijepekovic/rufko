# rufko

roofing thing

This repository previously contained a nested `rufko/` directory with a duplicate Flutter project. The duplicate has been removed to simplify the project structure.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


Here are detailed guidelines for creating responsive UI, drawing on the provided sources and our conversation history:

**Understanding Responsive vs. Adaptive Design**

*   **Responsive design** utilizes a single layout that is fluid and can adapt to changing window sizes, allowing a feature to work across various screen sizes.
*   **Adaptive design** involves replacing one layout with another, having multiple fixed layout sizes and triggering a different layout based on available space.
*   The concept of building "adaptive apps" in Flutter encompasses adapting to device size and shape, different input types, and new APIs for devices like folding phones.

**Core Principles for Building Adaptive Apps**

*   **One Codebase, Multiple Platforms:** Flutter allows building for multiple platforms from a single codebase. Techniques developed for one platform, like mouse support for Android tablets, can transfer to Flutter desktop or web apps.
*   **Adapt to Window Size, Not Device Type:** It is critical to build an app that functions well on a wide range of devices based on the **size of the window** your app is rendering in, not solely based on a definition of a device type like "tablet" or "phone". The space an app is given isn't always tied to the full screen size of the physical device, especially with multi-window modes on Android and iOS, resizable windows on web and desktop, or picture-in-picture.
*   **Break Down Complex Widgets:** Refactoring large, complex widgets into simpler, smaller ones can reduce complexity by sharing core code. Smaller, `const` widgets can improve rebuild times because Flutter can reuse `const` instances. They are also more readable, easier to refactor, and less likely to have surprising behavior. You can gauge complexity by the amount of documentation needed to describe a widget's behavior.
*   **Do Not Lock Screen Orientation:** An adaptive app should look good on windows of all different sizes and shapes. Locking orientation, even to portraitUp and portraitDown, can hinder adaptation efforts later. Multi-window and foldable use cases often work best with apps running side by side, requiring various orientations. Android and Flutter design guidance recommends against locking screen orientation. If you must restrict orientation, use the new display API introduced in Flutter 3.13 to get physical screen dimensions, rather than `MediaQuery.sizeOf`, to avoid issues like letterboxing caused by Portrait Compatibility Mode.

**Adapting Layouts Based on Window Size**

You can dynamically change widgets or layouts based on available space by measuring the rendering area and adding branching logic.

1.  **Measure the Rendering Area:**
    *   **`MediaQuery`**: Provides information about the app's current window size, accessibility settings, and display features like hinges or folds. `MediaQuery.sizeOf(context)` gives the size of the app window in logical pixels (density-independent pixels), which is the recommended measurement as a logical pixel has roughly the same visual size across devices. Using `sizeOf` causes the build context to rebuild specifically when the size property changes. Use `MediaQuery.sizeOf` when the layout decision should be based on the size of the **whole app window**. Avoid using the general `MediaQuery.of(context)` if only the size is needed, as it rebuilds the widget when *any* `MediaQuery` property changes, leading to unnecessary rebuilds.
    *   **`LayoutBuilder`**: Provides the layout constraints from the parent widget. This means sizing information is based on the **specific spot in the widget tree** where `LayoutBuilder` is used. It provides `BoxConstraints` with a valid width and height range (minimum and maximum) rather than a fixed size. Use `LayoutBuilder` for more **local sizing decisions** within a specific part of the UI.

2.  **Add Branching Logic:**
    *   Once you have the size or constraint information, use conditional logic to switch between different widgets or layouts.
    *   The **Material Design Layout Guidelines** suggest using breakpoints based on logical pixel width. Common suggested window size classes are:
        *   **Compact Layout:** App window less than 600 logical pixels wide. Often suitable for phone-like UIs.
        *   **Medium Layout:** Between 600 and 840 logical pixels wide.
        *   **Expanded Layout:** 840 logical pixels wide and above. Often suitable for tablet or desktop-like UIs.
    *   These are starting points; you can use custom breakpoints and groupings that make sense for your app.
    *   Avoid using `MediaQuery.orientationOf` or `OrientationBuilder` to switch layouts, as device orientation doesn't necessarily reflect the app window size. Base decisions on size breakpoints instead.

3.  **Abstract Shared Code:**
    *   When switching between different widgets (e.g., a standard dialog and a fullscreen dialog, or a bottom navigation bar and a navigation rail), analyze their constructors and abstract out shared elements like content or lists of destinations. This helps maintain clean and readable code.

**Examples of Adaptive UI Techniques**

*   **Handling Screen Intrusions:** Use the `SafeArea` widget to inset child widgets and avoid intrusions like notches, camera cutouts, status bars, or rounded corners. `SafeArea` uses `MediaQuery.paddingOf` to find the covered areas. It modifies its child's `MediaQuery` so that the padding appears not to exist, allowing safe nesting where only the topmost `SafeArea` applies padding when needed. Wrapping the `body` of your `Scaffold` widget is a good starting point.
*   **Adapting Lists for Large Screens:**
    *   Transform a vertical `ListView` into a `GridView` to arrange items in a two-dimensional array. `GridView.builder` is recommended for a large number of items as it only builds visible widgets.
    *   Use `SliverGridDelegateWithMaxCrossAxisExtent` as the grid delegate. This allows defining a maximum item width, and Flutter automatically handles the number of columns based on the available width, rather than hardcoding a fixed column count.
    *   Wrap the `GridView` or other content in a `ConstrainedBox` or `Container` (which functions similarly) and set a `maxWidth` to prevent content from stretching edge-to-edge on very large displays. Material 3 recommends a `maxWidth` of 840 for expanded screens.
*   **Dynamic Widgets (Dialogs, Navigation, Custom Layouts):** As described above, use `MediaQuery.sizeOf` or `LayoutBuilder` with branching logic based on breakpoints.
    *   **Dialogs:** Show content as fullscreen on smaller devices (`Dialog.fullscreen`) and a modal on larger screens (default `Dialog`) by checking `MediaQuery.sizeOf` against a breakpoint like 600 logical pixels.
    *   **Navigation:** Switch between a `BottomNavigationBar` for smaller apps and a `NavigationRail` for larger apps, typically using `MediaQuery.sizeOf` and the 600 logical pixel breakpoint.
    *   **Custom Layouts:** Create different arrangements of widgets (e.g., stacking vertically or placing side-by-side) based on constraints from `LayoutBuilder`, such as determining if the space is wider than it is tall. Other custom layout techniques include repositioning, resizing margins/size, reflowing content into columns or different arrangements, showing/hiding elements or metadata based on space, and re-architecting parts of the app. Adaptive layout can also mean entirely replacing a UI based on breakpoints.
*   **Handling Foldable Devices:** Android and Flutter design guidance strongly recommends **not locking screen orientation**. If you must restrict orientation, use the new display API available from Flutter 3.13+ to get physical screen dimensions to avoid issues with Portrait Compatibility Mode causing letterboxing. Android large screen guidelines require supporting foldable postures like tabletop and book posture. Camera apps should adjust previews for folded/unfolded states and support front/back screen previews.

**Adapting to Different Input Types**

Adaptive apps should support various input methods, including touch, mouse, keyboard, and stylus. Building mouse support for Android tablets, for instance, carries over to Flutter desktop or web apps due to the shared codebase.

*   **Android Large Screen App Quality Tiers:** Android defines tiers of large screen support, including input requirements.
    *   **Tier 3 (Basic):** Requires basic support for external keyboard (text input, switching keyboards) and basic mouse or trackpad interactions (click, select, scroll). Basic stylus input is the same as touch input and supported by default.
    *   **Tier 2 (Better):** Requires enhanced support, including keyboard navigation (Tab, arrow keys), keyboard shortcuts (copy/paste, media control, send in communication apps), mouse/trackpad right-click for options menus, mouse scroll wheel/trackpad pinch for zoom, and hover states for actionable UI elements. A focused state must be created for interactive custom drawables when not in Touch Mode.
    *   **Tier 1 (Best):** Requires differentiated support, including comprehensive keyboard shortcuts, mouse/keyboard combinations for selection (Ctrl+click, Shift+click), scrollbars on mouse/trackpad scroll, fly-out menus/tooltips on hover, desktop-style menus, reconfigurable UI panels, and triple-click text selection. It also includes drawing/writing support with a stylus, stylus drag and drop, and enhanced stylus features like low latency, pressure sensitivity, tilt detection, and palm/finger rejection. Custom cursors should be displayed where appropriate.
*   **Implementing Input States in Flutter:** If you are using `MaterialApp`, theme, buttons, and selectors, you often get support for various additional input states like hover out of the box. For custom widgets, you can add interactivity for hover and selection states. The `FocusableActionDetector` widget is frequently used in the Material Library to combine functions like mouse region and focus, providing callbacks for state changes. You can add visual cues like corner radius or transparency and animate transitions for these states.

**Accessibility**

*   Ensure touch targets are of adequate size. Material Design recommends at least 48dp, while Apple guidelines suggest at least 44 points x 44 points.
*   A focused state should be created for interactive custom drawables when not in Touch Mode, with a clear visual indication.

**Testing Your Adaptive App**

*   Test your app on devices with a wide variety of screen sizes, including phones, foldable phones, small and large tablets, and ChromeOS devices.
*   Run the app in multi-window mode on these devices.
*   Verify that layouts respond and adapt correctly to different screen and window sizes. Check that elements like navigation rails expand/contract, grid columns scale, and text flows into columns.
*   Use Android emulators for testing large screen compatibility, such as Foldable phone (7.6"), 8-inch tablet, 10.5-inch tablet, 13-inch Chromebook, and Dual-display foldable.
*   Test specific requirements related to configuration changes (rotation, folding, resizing), multi-window mode, multi-resume (app updates when not focused, handles loss/regain of resources like camera/mic), input methods (keyboard, mouse, trackpad, stylus interactions), and foldable postures.
*   For apps using activity embedding, test side-by-side display on large screens and stacking on small screens.

**Additional Best Practices**

*   Do not lock screen orientation.
*   Break down large, complex widgets into smaller, simpler ones.
*   Avoid checking for specific device types (phone, tablet, etc.) to make layout decisions. Instead, use `MediaQuery` to get the app window size.
*   Avoid using `MediaQuery.orientationOf` or `OrientationBuilder` to switch layouts. Use size breakpoints based on `MediaQuery.sizeOf` or `LayoutBuilder` instead.
*   Refer to the Material Design Layout Guidelines for suggested breakpoints.

By following these detailed guidelines, you can build Flutter apps that provide a high-quality, adaptable user experience across the diverse landscape of devices available today.


## Codex Setup
Run `setup.sh` before running Flutter commands in Codex.

## 🔨 Refactoring Progress

This project is currently undergoing systematic refactoring to improve maintainability.

### Current Status
- **Large files identified:** 29
- **Files refactored:** 1
- **Current focus:** lib/providers/app_state_provider.dart
- **Progress:** 8% complete

### Priority List Backup
| File | Lines | Priority | Status |
|------|-------|----------|---------|
| lib/providers/app_state_provider.dart | 1139 | HIGH | IN_PROGRESS |
| lib/screens/customer_detail_screen.dart | 1596 | HIGH | PENDING |
| lib/screens/customer_detail/info_tab.dart | 1585 | HIGH | PENDING |
| lib/screens/settings_screen.dart | 1469 | HIGH | PENDING |
| lib/screens/products/product_form_dialog.dart | 1337 | HIGH | PENDING |
| lib/screens/pdf_preview_screen.dart | 1312 | HIGH | PENDING |
| lib/widgets/templates/dialgos/email_template_editor.dart | 1222 | HIGH | PENDING |
| lib/widgets/templates/dialgos/message_template_editor.dart | 1187 | HIGH | PENDING |
| lib/services/database_service.dart | 1176 | HIGH | PENDING |
| lib/screens/home_screen.dart | 1089 | HIGH | PENDING |
| lib/services/pdf_service.dart | 1045 | HIGH | PENDING |
| lib/screens/template_editor_screen.dart | 974 | MEDIUM | PENDING |
| lib/screens/customer_detail/inspection_tab.dart | 944 | MEDIUM | PENDING |
| lib/services/template_service.dart | 776 | MEDIUM | PENDING |
| lib/screens/customer_detail/media_tab_controller.dart | 651 | LOW | PENDING |
| lib/screens/category_management_screen.dart | 649 | LOW | PENDING |
| lib/widgets/templates/dialgos/add_field_dialog.dart | 645 | LOW | PENDING |
| lib/widgets/templates/pdf_templates_tab.dart | 604 | LOW | PENDING |
| lib/widgets/templates/dialgos/edit_field_dialog.dart | 601 | LOW | PENDING |
| lib/screens/templates_screen.dart | 594 | LOW | PENDING |
| lib/providers/helpers/roof_scope_helper.dart | 583 | LOW | PENDING |
| lib/widgets/quote_totals_section.dart | 559 | LOW | PENDING |
| lib/screens/simplified_quote_detail_screen.dart | 555 | LOW | PENDING |
| lib/widgets/templates/fields_tab.dart | 546 | LOW | PENDING |
| lib/mixins/customer_communication_mixin.dart | 518 | LOW | PENDING |
| lib/screens/customers_screen.dart | 514 | LOW | PENDING |
| lib/mixins/template_tab_mixin.dart | 512 | LOW | PENDING |
| lib/mixins/file_sharing_mixin.dart | 504 | LOW | PENDING |
| lib/widgets/templates/email_templates_tab.dart | 503 | LOW | PENDING |

### Refactoring Goals
- Break down files >500 lines into focused, single-responsibility components
- Improve code maintainability and readability
- Preserve all existing functionality
- Follow Flutter/Dart best practices

### Recent Changes
- ⏳ 2025-06-11 Starting systematic refactoring process
- ✅ 2025-06-11 Refactored `lib/providers/app_state_provider.dart` (extracted PDF generation helper)

- ✅ 2025-06-11 Extracted data loading helper (`lib/providers/helpers/data_loading_helper.dart`)
- ✅ 2025-06-11 Extracted RoofScope parsing helper
- ✅ 2025-06-11 Updated setup script to clone Flutter repo
- ✅ 2025-06-11 Extracted template category helper
- ✅ 2025-06-11 Extracted message template helper
- ✅ 2025-06-11 Extracted email template helper
- ✅ 2025-06-11 Removed inline review comment in `app_state_provider.dart`
- ✅ 2025-06-11 Extracted customer helper
- ✅ 2025-06-11 Fixed analyzer errors and cleaned imports
See `AGENTS.MD` for detailed refactoring progress and methodology.
