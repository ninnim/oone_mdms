# MDMS Clone - Property Management System

## Project Overview
This is a Flutter application that clones a property management system UI (BluNest-like interface) and connects it with a Device Management System (MDMS) API. The app provides a consistent, modern UI experience for managing devices, properties, and related data, with support for dark/light mode and reusable widgets/components. Last updated: Wednesday, July 09, 2025, 11:03 AM +07.

## UI Design Requirements

### Design System
- **Color Scheme**:
  - Primary Blue: #2563eb (similar to BluNest)
  - Secondary Gray: #64748b
  - Success Green: #10b981
  - Warning Orange: #f59e0b
  - Error Red: #ef4444
  - Background Light: #f8fafc
  - Background Dark: #1e293b
  - Card Background Light: #ffffff
  - Card Background Dark: #2d3748
- **Typography**:
  - **Headers**: Inter/SF Pro (system font) Bold
  - **Body**: Inter/SF Pro Regular
  - **UI Elements**: Inter/SF Pro Medium
- **Theme Support**: Implement dark/light mode with user-configurable appearance in advanced settings.

### Component Guidelines
1. **Consistent Spacing**: Use 8px grid system (8, 16, 24, 32px)
2. **Border Radius**: 8px for cards, 6px for buttons, 4px for inputs
3. **Elevation**: Subtle shadows for cards (0 1px 3px rgba(0,0,0,0.1) for light, rgba(255,255,255,0.1) for dark)
4. **Icons**: Use consistent icon set (Feather or Lucide icons)

## Core Features to Implement

### Reusable Widgets/Components
- **MainLayout**: Expandable/collapsible sidebar layout inspired by dribbble.com designs.
- **TableView**: Pagination, checkbox for multiple selection, sortable columns, hide/show columns.
- **KanbanView**: Pagination support, card-based layout.
- **MapClusteringMarker**: Pagination, device list in sidebar, clickable cluster markers (styled as ClusterMarker), 360-degree detail view on click.
- **Pagination**: Offset selection, current page input, last/next page buttons.
- **Button**: Consistent styled buttons (primary, secondary, danger).
- **TextInput**: Styled text fields with validation.
- **Filters**: Dynamic filtering options.

### 1. Device Management (Priority 1)
Based on `device_spec.json` and `device_group_spec.json`:
- **Device List View** (Table/Kanban/Map Clustering):
  - Display devices in TableView, KanbanView, or MapClusteringMarker.
  - Columns/Actions: Serial Number, Name, Device Type, Model, Status, Address, Actions (View, Edit, Delete).
  - Search, filter, and pagination support.
  - Status indicators with color coding.
- **Device Details View** (360-degree):
  - Tabs: Overview, Metrics (loadProfile with table/graphs, date range filter via dropdown), Channel, DeviceBilling (table view with dialog for readings), Location (map).
  - Actions: Link HES, Commissioned, Ping.
- **Create/Edit Device Form**:
  - Multi-step form in MainLayout with sections:
    1. **General Info**:
       - Serial Number (required)
       - Model (optional)
       - Device Type (dropdown: None, Smart Meter, ToI)
       - Manufacturer (optional)
       - Device Group (dropdown: None, fetch from `device_group_spec.json`)
       - Schedule (dropdown: None, fetch from `schedule_spec.json`)
    2. **Location**:
       - Map marker picker (use Google Maps API from `device_spec.json` endpoints, no API key required).
    3. **Integration Info**:
       - Status (dropdown: None, Commissioned, Discommoded)
       - Link Status (dropdown: None, MULTIDRIVE, E-POWER)

- **Device Group Management**:
  - List view, details with associated devices, create/edit functionality.
- **Schedule Management**:
  - List view, details, create/edit based on `schedule_spec.json`.

### 2. TOU Management
- **Time of Use**: List and details based on `Time_time.json`.
- **Time Bands**: List and details.
- **Special Day**: List and details based on `special_day_spec.json`.
- **Season**: List and details based on `season_spec.json`.

### 3. Settings
- **Site**: Manage site configurations.
- **Appearance**: Switch between dark/light mode.
- **Advanced Settings**: User preferences, theme selection.

## Data Mapping Strategy

### UI Component → API Data Mapping
1. **Properties Table → Devices Table**
   - Property Name → Device SerialNumber + Name
   - Property ID → Device Id
   - Status → Device Status (Commissioned, None, etc.)
   - Price → Device Type
   - Completion % → Link Status or custom calculation
2. **Property Details → Device Details**
   - Units → Device Channels
   - Property Info → Device Info
   - Tenant Info → Device Attributes
   - Move-in Date → Last Data Date
3. **Add Property Form → Add Device Form**
   - Project Details → Device Details
   - Unit Details → Device Channels
   - Media & Documents → Device Attributes
   - Location → Address information

## Technical Architecture

### Project Structure
```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_sizes.dart
│   │   └── api_constants.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   ├── device_service.dart
│   │   └── auth_service.dart
│   ├── models/
│   │   ├── device.dart
│   │   ├── device_group.dart
│   │   ├── address.dart
│   │   ├── schedule.dart
│   │   └── response_models.dart
│   └── utils/
│       ├── date_utils.dart
│       └── validators.dart
├── presentation/
│   ├── widgets/
│   │   ├── common/
│   │   │   ├── main_layout.dart
│   │   │   ├── table_view.dart
│   │   │   ├── kanban_view.dart
│   │   │   ├── map_clustering_marker.dart
│   │   │   ├── pagination.dart
│   │   │   ├── app_button.dart
│   │   │   ├── text_input.dart
│   │   │   ├── filters.dart
│   │   │   └── status_chip.dart
│   │   ├── forms/
│   │   │   ├── device_form.dart
│   │   │   └── ticket_form.dart
│   │   └── modals/
│   │       ├── create_device_modal.dart
│   │       └── create_ticket_modal.dart
│   ├── screens/
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart
│   │   ├── devices/
│   │   │   ├── devices_screen.dart
│   │   │   ├── device_details_screen.dart
│   │   │   └── widgets/
│   │   ├── device_groups/
│   │   │   └── device_groups_screen.dart
│   │   ├── schedules/
│   │   │   └── schedules_screen.dart
│   │   └── settings/
│   │       ├── settings_screen.dart
│   │       └── advanced_settings_screen.dart
│   └── themes/
│       └── app_theme.dart
└── main.dart
```

### Dependencies to Add
```yaml
dependencies:
  # HTTP & State Management
  dio: ^5.4.0
  provider: ^6.1.1
  
  # UI Components
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  
  # Navigation
  go_router: ^12.1.3
  
  # Date/Time
  intl: ^0.19.0
  
  # Forms & Validation
  flutter_form_builder: ^9.1.1
  form_builder_validators: ^9.1.0
  
  # Maps (for location)
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  
  # Theme
  flutter_bloc: ^8.1.3
```

## Implementation Phases

### Phase 1: Core Setup & Design System
1. Setup project dependencies
2. Create design system (colors, typography, spacing, themes)
3. Build reusable components (MainLayout, TableView, KanbanView, MapClusteringMarker, Pagination, Button, TextInput, Filters)
4. Setup navigation structure and theme switching

### Phase 2: Device Management
1. Create models based on `device_spec.json`, `device_group_spec.json`, `schedule_spec.json`
2. Implement API service layer with real data
3. Build devices list screens (Table/Kanban/Map)
4. Build device details screen (360-degree view)
5. Create device form modal with sections

### Phase 3: Additional Modules & Features
1. Implement Device Groups and Schedule management
2. Add TOU Management (Time of Use, Time Bands, Special Day, Season)
3. Implement Settings (Appearance, Advanced)

### Phase 4: Polish & Optimization
1. Add loading states and error handling
2. Implement responsive design
3. Add animations and micro-interactions
4. Testing and bug fixes

## Key Components to Build

### 1. MainLayout
- Expandable/collapsible sidebar inspired by dribbble.com
- Navigation items with icons
- User profile section
- Theme toggle

### 2. TableView
- Sortable columns, checkbox selection, hide/show columns
- Pagination integration

### 3. KanbanView
- Card-based layout with pagination

### 4. MapClusteringMarker
- Styled as ClusterMarker with 360-degree detail view
- Sidebar device list, marker click navigation

### 5. Pagination
- Offset selection, page input, last/next buttons

### 6. AppButton
- Primary, secondary, danger variants

### 7. TextInput
- Styled with validation

### 8. Filters
- Dynamic filtering options

## API Integration Notes

### Headers Required
```dart
{
  'x-hasura-admin-secret': '4)-g$xR&M0siAov3Fl4O',
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Authorization': token,
  'x-hasura-tenant': '0a12968d-2a38-48ee-b60a-ce2498040825',
  'x-hasura-user': 'admin',
  'x-hasura-role': 'super-admin'
}
```

### Key Endpoints
- GET `/api/rest/Device` - List devices
- GET `/api/rest/Device/{id}` - Get device by ID
- POST `/api/rest/Device` - Create/Update device
- DELETE `/api/rest/Device/{id}` - Delete device
- GET `/api/rest/v1/DeviceGroup` - List device groups
- GET `/core/api/rest/v1/Schedule` - List schedules
- POST `/core/api/rest/v1/Device/LinkHes` - Link to HES

## Quality Standards
- **Code**: Follow Dart/Flutter best practices
- **Performance**: Lazy loading, efficient rendering
- **Accessibility**: Proper labels, semantic widgets
- **Testing**: Unit tests for models and services
- **Documentation**: Comment complex business logic

## Success Criteria
1. ✅ UI matches BluNest aesthetic with dark/light mode
2. ✅ All device CRUD operations work with real API data
3. ✅ Responsive design across screen sizes
4. ✅ Consistent, reusable components
5. ✅ Clean, maintainable code structure
6. ✅ Proper error handling and loading states