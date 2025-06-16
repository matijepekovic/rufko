# Rufko - Professional Roofing Estimator Wireframe Documentation

## Application Structure

### Main Sections
- **Dashboard** - Home screen with statistics, recent activity, and quick actions
- **Customers** - Customer management with contact info, communication history, and project media
- **Quotes** - Quote creation, management, and PDF generation
- **Products** - Product catalog with pricing levels and categories
- **Templates** - PDF templates, message templates, email templates, and custom fields
- **Settings** - Application configuration, company info, and data management

### Key User Flows
- **Quote Creation Flow**: Customer Selection → Quote Configuration → Product Selection → PDF Generation → Send/Save
- **Customer Management Flow**: Add Customer → Project Documentation → Communication → Quote Creation
- **Template Management Flow**: Upload PDF → Field Mapping → Template Configuration → Usage in Quotes
- **Product Configuration Flow**: Basic Info → Pricing Levels → Category Assignment → Integration with Quotes

### Application Architecture
- **Entry Point**: MaterialApp with HomeScreen as initial route
- **State Management**: Provider pattern with multiple providers (AppStateProvider, CustomerProvider, QuoteProvider, etc.)
- **Navigation**: Bottom navigation bar with PageView for main sections
- **Responsive Design**: Adaptive layouts for mobile, tablet, and desktop with breakpoint-based responsive mixins

## Navigation Structure

### Primary Navigation
- **Dashboard Tab** → Dashboard screen with overview statistics and quick actions
- **Customers Tab** → Customer list with search, filters, and management options
- **Quotes Tab** → Quote list with status filtering and creation tools
- **Products Tab** → Product catalog with category tabs and management
- **Templates Tab** → Template management with tabbed interface (PDF, Messages, Email, Fields)

### Secondary Navigation
- **AppBar Actions**: Search toggle, sort options, refresh, settings access
- **Floating Action Buttons**: Context-specific creation actions per screen
- **Tab Navigation**: Sub-tabs within main sections (customer status, quote status, template types)
- **Card Navigation**: Tap cards to access detail screens

### Navigation Rules
- **Back Button**: Standard Android back navigation throughout
- **Bottom Navigation**: Persistent across main app sections
- **Modal Navigation**: Dialogs and forms overlay current screen
- **Deep Linking**: Direct access to specific customers, quotes, and templates via navigation

### Responsive Navigation Patterns
- **Mobile/Tablet**: Bottom navigation with full-screen pages
- **Desktop**: Side navigation rail with expanded content area
- **Adaptive Layouts**: HomeSmallLayout vs HomeLargeLayout based on screen size

## Interactive Elements

### Primary Action Buttons
| Button Label | Location | Action Triggered | Target/Result |
|--------------|----------|------------------|---------------|
| "Quick Create" | Dashboard FAB | QuickActionsController.showQuickCreateDialog | Quick creation dialog for customers/quotes |
| "New Quote" | Quotes screen FAB | QuoteNavigationController.navigateToCreateQuote | Navigate to SimplifiedQuoteScreen |
| "Add Customer" | Customers screen FAB | CustomerDialogManager.showAddCustomerDialog | Customer form dialog |
| "Import" | Customers screen secondary FAB | CustomerDialogManager.showImportOptions | Import options dialog |
| "Add Product" | Products screen FAB | ProductDialogManager.showAddProductDialog | Product form dialog |
| "Create PDF/Message/Email" | Templates screen FAB | Context-based template creation | Template editor screens |

### AppBar Actions
| Button Label | Location | Action Triggered | Target/Result |
|--------------|----------|------------------|---------------|
| Search Icon | All main screens | toggleSearch() | Expands/collapses search bar |
| Sort Icon | Customers/Products | PopupMenuButton | Sort options menu |
| Refresh Icon | All main screens | Reload data providers | Refreshes current data |
| Settings Icon | Dashboard | Navigator.push | Settings screen |

### Card Actions
| Element | Location | Action Triggered | Target/Result |
|---------|----------|------------------|---------------|
| Customer Card Tap | Customers list | Navigate to CustomerDetailScreen | Customer detail view |
| Customer Card Menu | Customers list | PopupMenuButton (Edit/Delete) | Edit dialog or delete confirmation |
| Product Card Edit | Products list | ProductDialogManager.showEditProductDialog | Product edit dialog |
| Quote Card Tap | Quotes list | Navigate to quote detail | Quote detail/edit screen |

### Form Controls
| Control Type | Behavior | Validation | Error Handling |
|--------------|----------|------------|----------------|
| Text Fields | Real-time validation, focus management | Required fields (*), format validation | Inline error messages |
| Dropdowns | Searchable, categorized options | Selection required | Error state styling |
| Switches/Toggles | Immediate state change | None | Visual feedback only |
| Date Pickers | Calendar popup | Date range validation | Date format errors |

## Dialogs and Modals

### Modal Triggers
| Trigger Element | Modal/Dialog Opened | Purpose | Actions Available |
|-----------------|---------------------|---------|-------------------|
| Add Customer FAB | Customer Form Dialog | Create new customer | Cancel, Add Customer |
| Edit Customer Menu | Customer Form Dialog (Edit) | Edit customer details | Cancel, Update Customer |
| Add Product FAB | Product Form Dialog | Create new product | Cancel, Create Product |
| Quick Create FAB | Quick Actions Dialog | Quick creation menu | Create Customer, Create Quote, Cancel |
| Add Communication | Enhanced Communication Dialog | Add customer communication | Cancel, Add Communication |
| Delete Actions | Confirmation Dialogs | Confirm deletions | Cancel, Delete |
| Template Creation | Template Editor Screens | Create/edit templates | Cancel, Save, Preview |

### Dialog Types

#### **Form Dialogs**
- **Customer Form Dialog**: Name*, phone, email, address fields with validation
- **Product Form Dialog**: Tabbed interface (Basic Info, Product Type, Pricing Levels)
- **Enhanced Communication Dialog**: Type selection, content editor with rich formatting
- **Add Product to Quote Dialog**: Product selection with expandable categories

#### **Management Dialogs**
- **Category Manager Dialog**: Add/edit/delete categories with inline editing
- **Discount Dialog**: Discount configuration with type selection and validation
- **Tax Rate Dialogs**: Manual tax entry and automatic tax rate addition

#### **Editor Dialogs**
- **Email Template Editor**: Rich template editor with field insertion and preview
- **Message Template Editor**: SMS template creation with character counting
- **Field Dialog**: Custom field creation and configuration

#### **Information Dialogs**
- **Premium Feature Dialog**: Feature explanation with upgrade prompts
- **Help Dialog**: Application help and documentation
- **Placeholder Help Dialog**: Field insertion help with searchable categories

### Dialog Behavior
- **Opening**: Modal overlay with fade-in animation and backdrop
- **Closing**: X button (top-right), Cancel button, outside click, ESC key
- **Data Flow**: Form validation before submission, callback patterns for results
- **Loading States**: Progress indicators during async operations
- **Responsive**: Adaptive sizing for mobile/desktop, scrollable content

### Bottom Sheet Modals
- **Inspection Viewer**: Draggable bottom sheet with inspection document viewer
  - Initial: 90% screen height
  - Resizable: 50% minimum to 95% maximum
  - Features: Drag handle, close button, full document viewing

## Forms and Input Handling

### Form Locations
- **Customer Forms**: Customer creation/editing in dedicated dialog
- **Product Forms**: Complex tabbed product configuration dialog
- **Quote Forms**: SimplifiedQuoteScreen with multi-section configuration
- **Template Forms**: Dedicated editor screens for each template type
- **Communication Forms**: Inline communication entry with rich formatting

### Input Types
- **Text Inputs**: Name, description, notes with character limits and validation
- **Email Inputs**: Format validation with real-time feedback
- **Phone Inputs**: Optional formatting with validation
- **Number Inputs**: Price, quantity, percentage with range validation
- **Dropdowns**: Category selection, status selection, product type selection
- **Rich Text**: Template content with placeholder insertion
- **File Uploads**: Template PDF uploads with format validation
- **Date Pickers**: Integrated Material date selection

### Form Submission Flow
1. **User Input**: Real-time validation with immediate feedback
2. **Validation**: Form-wide validation on submit attempt
3. **Loading State**: Progress indicator during submission
4. **Success Handling**: SnackBar notification and navigation/dialog dismissal
5. **Error Handling**: Error messages with retry options

### Form Validation Rules
- **Required Fields**: Marked with asterisk (*), prevent submission if empty
- **Email Validation**: RFC-compliant email format checking
- **Phone Validation**: Flexible phone number format acceptance
- **Number Ranges**: Price (≥0), percentage (0-100%), quantity (>0)
- **Text Lengths**: Character limits with real-time counting
- **File Validation**: PDF format checking, size limits

## Content Display Patterns

### Lists and Tables
- **Customer List**: Card-based layout with search, filtering, and sorting
- **Product List**: Category-tabbed interface with card-based product display
- **Quote List**: Status-filtered tabs with list items showing key quote info
- **Template Lists**: Type-tabbed interface with action menus on items

### Content Loading
- **Initial Load**: Circular progress indicator with loading message
- **Pull-to-Refresh**: RefreshIndicator on scrollable lists
- **Pagination**: Not implemented - all data loaded at once
- **Search Results**: Real-time filtering with debounced search input

### State Management
- **Empty States**: Custom empty state widgets with contextual messages and actions
- **Error States**: Error display with retry options and error details
- **Loading States**: Consistent loading indicators with descriptive messages
- **Success States**: SnackBar notifications for successful operations

### Data Presentation
- **Statistics Cards**: Dashboard overview with revenue, quote counts, customer metrics
- **Detail Cards**: Expandable information cards with formatted data
- **Timeline Views**: Communication history with chronological organization
- **Media Galleries**: Image/document galleries with preview capabilities

## Notifications and Feedback

### Notification Types
- **Success Messages**: Green SnackBar for successful operations (3-second duration)
- **Error Messages**: Red SnackBar for errors with dismiss action
- **Warning Messages**: Orange SnackBar for validation warnings
- **Info Messages**: Blue SnackBar for informational updates

### Progress Indicators
- **Form Progress**: Loading spinners in dialog buttons during submission
- **Data Loading**: Circular progress indicators with descriptive text
- **File Upload**: Progress indication during template upload processes
- **Background Tasks**: Subtle progress indication for data synchronization

### Status Indicators
- **Form Validation**: Real-time field validation with color-coded borders
- **Required Fields**: Asterisk indicators and validation styling
- **Save Status**: Visual feedback for save success/failure
- **Connection Status**: Implicit through loading states and error handling

## Mobile and Responsive Patterns

### Breakpoint Behavior
- **Mobile (≤768px)**: Bottom navigation, single-column layouts, full-screen dialogs
- **Tablet (769-1024px)**: Bottom navigation, two-column layouts where appropriate
- **Desktop (≥1025px)**: Side navigation rail, multi-column layouts, modal dialogs

### Touch Interactions
- **Tap Targets**: Minimum 44px touch targets throughout the app
- **Swipe Gestures**: Pull-to-refresh on lists, dismissible items where appropriate
- **Long Press**: Context menus on cards and list items
- **Drag Interactions**: Draggable bottom sheet for inspection viewer

### Mobile Navigation
- **Bottom Navigation**: Five-tab navigation with icons and labels
- **AppBar**: Contextual actions with overflow menu for additional options
- **Floating Action Buttons**: Context-specific primary actions
- **Back Navigation**: Standard Android back button behavior

### Responsive Components
- **Cards**: Adaptive sizing and spacing based on screen size
- **Forms**: Responsive field layouts with adaptive padding
- **Navigation**: Bottom tabs on mobile, side rail on desktop
- **Typography**: Responsive text sizing using responsive text mixins

## Technical Implementation Notes

### Component Hierarchy
- **Screens**: Top-level widgets containing AppBar, body, and FAB
- **Controllers**: Business logic separation from UI components
- **Widgets**: Reusable UI components with clear responsibilities
- **Mixins**: Responsive behavior, search functionality, sorting capabilities

### Data Dependencies
- **Provider Pattern**: Centralized state management with multiple providers
- **Service Layer**: Business logic encapsulation with dedicated service classes
- **Database Integration**: Hive local storage with type adapters
- **External APIs**: Tax service integration for automatic tax calculation

### State Changes and User Actions
- **Navigation**: Provider-based state changes trigger UI updates
- **Form Submission**: Async operations with loading states and result handling
- **Data Refresh**: Manual refresh triggers and automatic background updates
- **Search/Filter**: Real-time UI updates based on user input

### Performance Considerations
- **Lazy Loading**: Efficient list building with ListView.builder
- **Image Caching**: Cached image loading with error fallbacks
- **State Optimization**: Selective widget rebuilding with Consumer patterns
- **Memory Management**: Proper disposal of controllers and subscriptions

## Quality Checklist

- [x] Every clickable element is documented
- [x] All navigation paths are mapped
- [x] Every dialog/modal is cataloged with triggers
- [x] Form validation rules are noted
- [x] Error states and edge cases are included
- [x] Mobile/responsive behavior is documented
- [x] Loading states and async operations are covered
- [x] User feedback patterns are identified
- [x] Component relationships are clear
- [x] Data flow is understood and documented

## Usage Guidelines

This wireframe document enables anyone to:
1. **Understand the complete UI structure** through comprehensive screen and component documentation
2. **Navigate any user flow** by following the documented navigation paths and actions
3. **Identify the impact** of proposed changes through component relationship mapping
4. **Communicate changes precisely** using documented component and screen names
5. **Avoid breaking existing functionality** by understanding data dependencies and interaction patterns

## Maintenance

Update this wireframe whenever:
- New features are added to any section
- Existing user flows are modified
- Components are renamed or restructured
- Navigation patterns change
- New dialogs or interactions are introduced
- Responsive behavior is updated

The wireframe should always reflect the current state of the Rufko application UI and serve as the definitive reference for UI structure and interactions.