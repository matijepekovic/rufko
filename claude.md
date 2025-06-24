# CLAUDE DEVELOPMENT RULES - RUFKO PROJECT

## 🚨 CRITICAL ARCHITECTURE RULES

### UI AND BUSINESS LOGIC SEPARATION
- **NEVER mix UI and business logic** - This is the cardinal rule
- Always use existing controllers/services/providers
- Never put business logic in UI widgets
- UI components take callbacks only, contain ZERO business logic
- Controllers handle ALL state management and business operations

### PRESERVE EXISTING FUNCTIONALITY
- Always examine existing code before modifying
- Never break existing architectural patterns
- Follow established controller/service patterns exactly
- Preserve 100% of functionality during transformations

### DATA INTEGRITY
- No arbitrary mappings or fake business logic based on non-existent data
- No quick hacks, shortcuts, or workarounds that break data model integrity
- Proper data modeling comes FIRST, then UI reflects those capabilities
- UI must show only what the system can actually deliver

## 🔍 PRE-CODE MANDATORY CHECKS

**Before ANY code prompt, MUST verify:**

1. **Logic Location Check:**
    - ❓ Am I putting business logic in UI widgets? → **FORBIDDEN**
    - ❓ Am I adding state management to presentation layer? → **FORBIDDEN**
    - ❓ Should this logic be in a controller/service? → **REQUIRED**

2. **Data Flow Check:**
    - ❓ Does UI widget directly manipulate data? → **FORBIDDEN**
    - ❓ Am I using existing controllers/providers? → **REQUIRED**
    - ❓ Is data flowing through proper channels? → **REQUIRED**

3. **Responsibility Check:**
    - ❓ Is UI only handling presentation? → **REQUIRED**
    - ❓ Is business logic in business layer? → **REQUIRED**
    - ❓ Am I duplicating existing functionality? → **FORBIDDEN**

**IF ANY CHECK FAILS → STOP AND REDESIGN**

## 🗄️ HIVE TO SQLITE MIGRATION PROGRESS

### Migration Status: [IN_PROGRESS]
- **Started**: December 22, 2024
- **Current Phase**: Phase 5 - Project Media Migration
- **Completed Phases**: Phase 1 (Inventory Data), Phase 2 (Customer Data), Phase 3 (Product Data), Phase 4 (Quote Data)
- **Remaining Phases**: 9 phases

### Migration Goal:
Convert all data storage from Hive to SQLite for better performance, reliability, and standardization. Each phase migrates one data type at a time with user validation before proceeding.

### Phase Completion Log:
- [x] Phase 1: Inventory Data ✅ (Already SQLite)
- [x] Phase 2: Customer Data ✅
- [x] Phase 3: Product Data ✅
- [x] Phase 4: Quote Data ✅
- [ ] Phase 5: Project Media
- [ ] Phase 6: PDF Templates
- [ ] Phase 7: Message Templates
- [ ] Phase 8: Email Templates
- [ ] Phase 9: Template Categories
- [ ] Phase 10: App Settings
- [ ] Phase 11: Custom App Data Fields
- [ ] Phase 12: Roof Scope Data
- [ ] Phase 13: Inspection Documents

### Phase 1: Inventory Data - COMPLETED ✅
- **Completed Date**: December 22, 2024
- **Files Modified**: 
  - Created entire inventory SQLite infrastructure
  - inventory_database.dart, inventory_repository.dart, inventory_controller.dart
  - Full UI implementation with dialogs and screens
- **Test Data Created**: Sample products with various inventory levels and stock statuses
- **Testing Results**: All inventory functionality working correctly
- **User Approval**: ✅ APPROVED

### Phase 2: Customer Data - COMPLETED ✅
- **Completed Date**: December 22, 2024
- **Files Modified**: 
  - customer.dart (removed Hive annotations)
  - database_service.dart (replaced Hive with SQLite repository calls)
  - customer_database.dart (NEW - SQLite schema and operations)
  - customer_repository.dart (NEW - repository pattern implementation)
  - customer_migrator.dart (NEW - migration service)
  - customer_test_data.dart (NEW - development test data)
  - main.dart (removed CustomerAdapter, added SQLite initialization)
- **Test Data Created**: 15 sample customers with realistic scenarios (commercial, residential, emergency, etc.)
- **Testing Results**: SQLite infrastructure working, automatic migration on app startup
- **User Validation**: PENDING

### Phase 3: Product Data - COMPLETED ✅
- **Completed Date**: December 22, 2024
- **Files Modified**: 
  - product.dart (removed Hive annotations, kept all business logic)
  - database_service.dart (replaced Hive with SQLite repository calls)
  - product_database.dart (NEW - SQLite schema with normalized level prices table)
  - product_repository.dart (NEW - comprehensive repository with advanced queries)
  - product_migrator.dart (NEW - migration service with level price conversion)
  - product_test_data.dart (NEW - extensive test data with all product types)
  - main.dart (removed ProductAdapter and related Hive adapters)
- **Test Data Created**: 18 sample products including main differentiators, sub-leveled options, addons, and various categories
- **Testing Results**: SQLite infrastructure working, automatic migration on app startup
- **User Validation**: PENDING

### Phase 4: Quote Data - COMPLETED ✅
- **Completed Date**: December 22, 2024
- **Files Modified**: 
  - simplified_quote.dart (removed Hive annotations, kept all business logic)
  - quote.dart (removed Hive annotations)
  - database_service.dart (replaced Hive with SQLite repository calls)
  - quote_database.dart (NEW - comprehensive SQLite schema with normalized tables)
  - quote_repository.dart (NEW - repository with advanced search and statistics)
  - quote_migrator.dart (NEW - migration service with backup and verification)
  - quote_test_data.dart (NEW - extensive test data with all quote scenarios)
  - main.dart (removed Quote adapters and related Hive adapters)
- **Test Data Created**: 7 comprehensive sample quotes including multi-level, commercial, emergency, expired, and rejected scenarios
- **Testing Results**: SQLite infrastructure working, automatic migration on app startup
- **User Validation**: PENDING

### Current Phase Details:
- **Phase**: 5 - Project Media Migration
- **Files to Modify**: project_media.dart, database_service.dart, media_database.dart
- **Test Data**: Sample media files with various types and metadata
- **Testing Status**: NOT STARTED
- **User Validation**: PENDING

## 📋 DEVELOPMENT PROCESS RULES

### EXAMINATION AND PLANNING
- Always examine existing code structure before making changes
- Document current state vs desired state before proceeding
- Ask for clarification when requirements are unclear
- Create step-by-step plan before implementation

### HYPERDETAILED PROMPTS
- Provide hyperdetailed, step-by-step terminal prompts
- Each prompt should be copy-pasteable for terminal use
- Include exact file paths, line numbers, and code blocks
- Specify expected verification steps and error reporting

### PHASE-BASED DEVELOPMENT
- Break large changes into systematic phases
- Complete and verify each phase before proceeding
- Clean up failed attempts immediately
- Maintain working state between phases

## 🧪 TESTING AND VERIFICATION REQUIREMENTS

### STEP-BY-STEP VERIFICATION
- Test each step before proceeding to next
- Report actual vs expected results
- Verify no regressions introduced
- Confirm all existing functionality preserved

### END-TO-END TESTING
- Test complete navigation flows after changes
- Verify all user workflows still function
- Check for visual regressions or layout issues
- Confirm no crashes during normal usage

### ERROR REPORTING
- Report any errors immediately with exact error messages
- Document what works vs what's broken
- Provide specific steps to reproduce issues

## 💎 CODE QUALITY STANDARDS

### FILE ORGANIZATION
- Follow existing project structure exactly
- Use proper imports and file organization
- Create shared components when code is duplicated
- Maintain consistent naming conventions

### CONTROLLER PATTERNS
- Always use existing controller patterns
- Never bypass established service layers
- Maintain proper separation of concerns
- Document any changes to controller interfaces

### CLEAN CODE PRINCIPLES
- Remove unused code and failed attempts immediately
- Keep functions and classes focused on single responsibility
- Use descriptive variable and method names
- Maintain consistent formatting and style

## 🔧 FLUTTER DEVELOPMENT COMMANDS

### ESSENTIAL FLUTTER COMMANDS
```bash
# Check Flutter installation and setup
flutter doctor

# Static analysis and linting
flutter analyze

# Build commands
flutter build apk --debug          # Build debug APK
flutter build apk --release        # Build release APK
flutter build windows --debug      # Build debug Windows app
flutter build windows --release    # Build release Windows app

# Development commands
flutter run                        # Run app in debug mode
flutter run --release             # Run app in release mode
flutter hot-reload                 # Hot reload during development
flutter clean                     # Clean build artifacts

# Package management
flutter pub get                   # Get dependencies
flutter pub upgrade              # Upgrade dependencies
flutter pub deps                 # Show dependency tree

# Testing commands
flutter test                     # Run unit and widget tests
flutter integration_test         # Run integration tests
```

### PROJECT VERIFICATION WORKFLOW
1. `flutter doctor` - Verify setup
2. `flutter analyze` - Check for code issues (expect some warnings)
3. `flutter build apk --debug` - Verify compilation
4. `flutter run` - Test functionality

## 🏗️ PROJECT-SPECIFIC RULES

### DOMAIN CONTEXT
- This is a roofing estimation app with complex domain logic
- Customer/Quote/Product management with established workflows
- PDF generation, template management, and pricing systems
- Job scheduling and pipeline management features

### DESIGN REQUIREMENTS
- Mobile-first design approach
- Desktop responsive design marked as TODO for future
- Material Design 3 compliance where applicable
- Mockup fidelity for visual consistency

### ARCHITECTURE PATTERNS
- Provider pattern for state management
- Service layer for business logic
- Controller layer for UI coordination
- Mixin pattern for reusable UI behaviors

## 🛡️ PROJECT RESPECT RULES

### CLEANLINESS COMMITMENT
- This project was cleaned for a month - keep it pristine
- Never introduce architectural debt or shortcuts
- Remove any temporary or experimental code
- Maintain high code quality standards

### SHARED COMPONENTS
- When same code appears twice → create shared component
- Extract common UI patterns into reusable widgets
- Maintain separation between UI components and business logic
- Document component interfaces and usage patterns

## ⚠️ FORBIDDEN PRACTICES

### NEVER DO THESE:
- Mix UI and business logic in any way
- Create arbitrary data mappings for non-existent fields
- Put controller logic in UI widgets
- Bypass existing service/provider patterns
- Leave broken or partially implemented features
- Create duplicate functionality without extracting shared components
- Proceed without verifying previous steps work correctly

## ✅ SUCCESS CRITERIA

### FOR EVERY CHANGE:
- All existing functionality preserved
- Clean separation maintained
- Proper controller usage
- No architectural regressions
- Code remains maintainable and testable
- Project stays organized and clean

## DESIGN GUIDELINES

# Material Design 3 Implementation Guide for Rufko Roofing App

## Introduction

Material Design 3 (MD3), also known as Material You, represents Google's latest evolution in design philosophy, emphasizing personalization, accessibility, and expressive UI. As of Flutter 3.16 (November 2023), Material 3 is enabled by default, making it the standard for modern Flutter applications. This comprehensive guide provides actionable instructions for implementing Material Design 3 in the Rufko roofing estimation app, focusing on practical implementation rather than theoretical concepts.

## Core Material Design 3 principles and setup




### Professional color scheme for roofing industry

Implement a construction-appropriate color palette with high contrast for outdoor visibility:



### Typography configuration for business apps

Set up professional typography suitable for forms and data display:


## Navigation implementation for complex business apps

### Adaptive navigation based on screen size

Implement responsive navigation that adapts to different device sizes:



## Material 3 components for business applications

### Professional card designs for data display

Implement Material 3 card variants for different types of content:


### Form components with Material 3 styling

Create professional forms for roofing estimates:


### SegmentedButton for view options

Use Material 3's SegmentedButton for filtering and view options:



## Dashboard implementation with Material 3

Create a professional dashboard for the roofing app:


## Comprehensive responsive design and layout optimization

### Material 3 breakpoint system


### Responsive dimensions and spacing


### Advanced responsive widget patterns


### Comprehensive responsive layouts



### Responsive grid systems


### Adaptive form layouts

### Screen density and orientation handling


### Testing responsive layouts



## Performance optimization best practices

### Efficient state management with Provider



### Lazy loading for large datasets


## Theme extension for custom properties




## Migration from Material 2 to Material 3

### Key component replacements

Replace Material 2 components with their Material 3 equivalents:


### Color scheme updates




## Testing Material 3 implementations

### Widget testing with Material 3


### Visual regression testing


## Common pitfalls and solutions

### Avoiding performance issues



### Proper theme access



## Best practices summary

1. **Always use Material 3**: Set `useMaterial3: true` explicitly for clarity
2. **Use ColorScheme.fromSeed()**: Generate consistent color palettes from brand colors
3. **Implement responsive layouts**: Use LayoutBuilder and adaptive navigation
4. **Follow Material 3 spacing**: Use consistent padding (16dp standard, 24dp for cards)
5. **Test thoroughly**: Include widget tests, integration tests, and visual regression tests
6. **Use semantic color roles**: Prefer `colorScheme.primary` over hardcoded colors
7. **Implement proper error states**: Always show meaningful error messages with retry options
8. **Cache theme values**: Store frequently accessed theme values to avoid rebuilds
9. **Use const constructors**: Maximize performance with const widgets where possible
10. **Follow accessibility guidelines**: Ensure 48dp touch targets and proper contrast ratios

This comprehensive guide provides actionable instructions for implementing Material Design 3 in the Rufko roofing estimation app. By following these patterns and best practices, you'll create a professional, performant, and user-friendly application that leverages the latest Material Design principles while maintaining the specific requirements of a business-focused roofing industry app.