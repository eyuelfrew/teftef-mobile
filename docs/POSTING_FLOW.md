# Product Posting Flow Documentation

## Overview

The Tef Tef app implements a sophisticated multi-step product posting system with hierarchical category selection and dynamic form generation based on category-specific attributes.

---

## Flow Diagram

```
User clicks Post Tab
    ↓
[Authentication Check]
    ↓
CategorySelectionScreen (Root Categories)
    ↓
[User selects category with children]
    ↓
CategorySelectionScreen (Sub-categories) - Recursive drill-down
    ↓
[User selects leaf category (no children)]
    ↓
PostProductPage (Multi-step form)
    ↓
Step 1: Dynamic Attributes (if category has attributes)
Step 2: Basic Info (Title, Price, Description)
Step 3: Review & Post
    ↓
Submit Product
```

---

## Components

### 1. Authentication Gate

**Location:** `lib/production_bottom_navigation.dart`

**Behavior:**
- When user taps Post tab (index 2), checks authentication status
- If not logged in → Shows login bottom sheet
- If logged in → Navigates to CategorySelectionScreen

**Code:**
```dart
if (index == 2) { // Post tab index
  if (!isLoggedIn) {
    _showLoginBottomSheet(context);
    return;
  }
  _pageController.jumpToPage(index);
}
```

---

### 2. Category Selection Screen

**File:** `lib/category_selection_screen.dart`

**Purpose:** Hierarchical category navigation with drill-down capability

#### Features:
- Fetches category tree from backend API
- Supports recursive navigation through category hierarchy
- Visual indicators for parent vs leaf categories
- Category icons from backend
- Clean list UI with separators

#### API Integration:
```dart
GET /api/categories/tree
```

**Response Format:**
```json
{
  "data": {
    "categories": [
      {
        "id": 1,
        "name": "Electronics",
        "icon_url": "https://...",
        "children": [
          {
            "id": 2,
            "name": "Phones",
            "icon_url": "https://...",
            "children": []
          }
        ]
      }
    ]
  }
}
```

#### Navigation Logic:

**Parent Category (has children):**
- Shows arrow icon (→)
- On tap → Pushes new CategorySelectionScreen with subcategories
- Allows drilling down through hierarchy

**Leaf Category (no children):**
- No arrow icon
- On tap → Navigates to PostProductPage
- Passes selected category data

#### UI Components:
- AppBar with dynamic title
- Loading indicator while fetching
- Empty state for no categories
- ListView with separators
- ListTile with:
  - Leading: Category icon (CircleAvatar)
  - Title: Category name
  - Trailing: Arrow icon (if has children)

---

### 3. Post Product Page

**File:** `lib/post_product_page.dart`

**Purpose:** Multi-step form for creating product listings

#### Architecture:
- Uses `PageController` for step navigation
- Dynamic form generation based on category
- Validation at each step
- Progress tracking

#### Data Models:

**ProductData Class:**
```dart
class ProductData {
  String? name;
  String? description;
  double? price;
  String? category;
}
```

**Dynamic Form Values:**
```dart
Map<String, dynamic> _dynamicFormValues = {};
```

---

## Step-by-Step Breakdown

### Step 1: Dynamic Attributes (Conditional)

**Shown:** Only if category has attributes

**API Call:**
```dart
GET /api/attributes/{categoryId}
```

**Response Format:**
```json
{
  "data": {
    "attributes": [
      {
        "field_label": "Brand",
        "field_type": "dropdown",
        "field_options": ["Apple", "Samsung", "Huawei"],
        "is_required": true
      },
      {
        "field_label": "Storage",
        "field_type": "number",
        "is_required": true
      },
      {
        "field_label": "Color",
        "field_type": "text",
        "is_required": false
      }
    ]
  }
}
```

#### Supported Field Types:

**1. Dropdown:**
- Renders: `DropdownButton` with predefined options
- Options from: `field_options` array
- User selects from list

**2. Number:**
- Renders: `TextField` with number keyboard
- Input type: `TextInputType.number`
- User enters numeric value

**3. Text:**
- Renders: `TextField` with text keyboard
- Input type: `TextInputType.text`
- User enters free text

#### Validation:
- Required fields marked with red asterisk (*)
- Cannot proceed if any required field is empty
- Validation checked in `_canProceed()` method

#### UI Layout:
```
[Category Name] Specs
Fill in the specific details

[Field Label] *
[Input Widget]

[Field Label]
[Input Widget]

...
```

---

### Step 2: Basic Info

**Always shown**

#### Fields:

**1. Title**
- Type: TextField
- Label: "Title"
- Required: Yes (implied)
- Stores in: `_productData.name`

**2. Price**
- Type: TextField
- Label: "Price"
- Keyboard: Number
- Stores in: `_productData.price`
- Converts to: `double`

**3. Description**
- Type: TextField
- Label: "Description"
- Lines: 4 (multiline)
- Stores in: `_productData.description`

#### UI Layout:
```
Basic Info

[Title TextField]

[Price TextField]

[Description TextField (4 lines)]
```

---

### Step 3: Review & Post

**Always shown as final step**

#### Display Sections:

**1. Category**
```
Category:
[Selected Category Name]
```

**2. Product Specifics**
- Shows all dynamic attributes in summary card
- Format: Key-Value pairs
- Grey background container
- If empty: "No specifics added"

**3. Basic Info** (implied, could be added)
- Title
- Price
- Description

#### UI Layout:
```
Review & Post
Check everything looks good before publishing

Category:
Electronics > Phones

Product Specifics:
┌─────────────────────────┐
│ Brand        Apple      │
│ Storage      128        │
│ Color        Black      │
└─────────────────────────┘
```

---

## Navigation Controls

### Bottom Navigation Bar

**Layout:**
```
[Back Button]  [Continue/Post Product Button]
```

#### Back Button:
- Always visible
- Behavior:
  - If on first step → Navigate back to category selection
  - If on other steps → Go to previous step
- Style: Outlined button with black border

#### Continue/Post Button:
- Label changes based on step:
  - Steps 1-2: "Continue"
  - Final step: "Post Product"
- Disabled if validation fails
- Style: Elevated button (black background)
- Disabled style: Grey background

### AppBar Back Button:
- Same behavior as bottom Back button
- Provides alternative navigation method

---

## Validation Logic

### Step 1 (Dynamic Attributes):
```dart
for (var attr in _attributes) {
  if (attr['is_required'] && 
      (_dynamicFormValues[attr['field_label']] == null || 
       _dynamicFormValues[attr['field_label']].toString().isEmpty)) {
    return false; // Cannot proceed
  }
}
return true;
```

### Steps 2 & 3:
- Currently: Always allows continuation
- TODO: Add validation for title, price, description

---

## API Service

**File:** `lib/services/api_service.dart`

### Configuration:
```dart
static const String baseUrl = "http://localhost:5000/api";
// For Android Emulator: "http://10.0.2.2:5000/api"
```

### Endpoints:

#### 1. Fetch Category Tree
```dart
GET /api/categories/tree

Response:
{
  "data": {
    "categories": [...]
  }
}
```

#### 2. Fetch Category Attributes
```dart
GET /api/attributes/{categoryId}

Response:
{
  "data": {
    "attributes": [...]
  }
}
```

### Error Handling:
- Returns empty array on failure
- Catches network exceptions
- No error UI shown to user (graceful degradation)

---

## Data Flow

### 1. Category Selection:
```
User taps category
    ↓
Check if has children
    ↓
If yes: Navigate to subcategories
If no: Navigate to PostProductPage with category data
```

### 2. Attribute Fetching:
```
PostProductPage initialized
    ↓
Extract categoryId from selectedCategory
    ↓
Call ApiService.fetchAttributes(categoryId)
    ↓
Store in _attributes list
    ↓
Generate dynamic form fields
```

### 3. Form Data Collection:
```
User fills dynamic attributes
    ↓
Store in _dynamicFormValues Map
    ↓
User fills basic info
    ↓
Store in _productData object
    ↓
Review step shows combined data
    ↓
Submit
```

---

## Current Implementation Status

### ✅ Implemented:
- Authentication gate for posting
- Hierarchical category navigation
- Dynamic attribute fetching
- Dynamic form generation
- Multi-step form flow
- Field validation (required fields)
- Review screen
- Navigation controls

### ⚠️ Placeholder/Incomplete:
- Image upload (UI exists, not functional)
- Product submission (shows dialog, no API call)
- Location selection
- Delivery options
- Promotion/premium listing options

### ❌ Not Implemented:
- Draft saving
- Form data persistence
- Advanced validation (format, ranges)
- Image compression/optimization
- Progress saving
- Error recovery
- Offline support

---

## Integration Points

### Ready for Integration:

**1. Product Submission API:**
```dart
POST /api/products

Body:
{
  "category_id": int,
  "name": string,
  "description": string,
  "price": double,
  "attributes": {
    "Brand": "Apple",
    "Storage": "128",
    ...
  },
  "images": [...]
}
```

**2. Image Upload:**
- Add image picker
- Implement multi-image selection
- Add image compression
- Upload to storage service
- Get image URLs

**3. Location Service:**
- Add location picker
- Integrate maps
- Store coordinates
- Display location name

**4. Premium Listings:**
- Add promotion selection step
- Integrate payment gateway
- Handle subscription logic

---

## Design Patterns Used

### 1. Hierarchical Navigation
- Recursive category drill-down
- Breadcrumb-style back navigation
- State preservation across navigation

### 2. Dynamic Form Generation
- Backend-driven form structure
- Runtime widget creation
- Type-based rendering

### 3. Progressive Disclosure
- Multi-step form reduces cognitive load
- One concern per screen
- Clear progress indication

### 4. Validation Gates
- Step-by-step validation
- Cannot proceed without required data
- Immediate feedback

### 5. Separation of Concerns
- UI components separate from data
- API service isolated
- State management localized

---

## Best Practices Observed

1. **Error Handling:** Graceful degradation on API failures
2. **Loading States:** Shows indicators during async operations
3. **User Feedback:** Disabled buttons indicate invalid state
4. **Navigation:** Consistent back button behavior
5. **Code Organization:** Clear file structure and naming
6. **Reusability:** Dynamic form generation reduces code duplication

---

## Recommendations for Enhancement

### Short Term:
1. Add basic validation for title, price, description
2. Implement actual product submission API
3. Add success/error feedback after submission
4. Implement image upload functionality
5. Add form field error messages

### Medium Term:
1. Add draft saving functionality
2. Implement location picker
3. Add delivery options selection
4. Integrate premium listing flow
5. Add image preview and editing

### Long Term:
1. Offline support with local storage
2. Auto-save functionality
3. Advanced validation rules from backend
4. Multi-language support for forms
5. Analytics tracking for form completion

---

## Technical Debt

1. **Validation:** Currently simplified, needs comprehensive validation
2. **Error Handling:** Silent failures, needs user-facing error messages
3. **State Management:** Local state could be moved to Provider
4. **Type Safety:** Dynamic types used, could be strongly typed models
5. **Testing:** No unit tests for form logic

---

## Conclusion

The posting flow is well-architected with clear separation of concerns, dynamic form generation, and a user-friendly multi-step process. The hierarchical category navigation provides excellent UX for complex category structures. The system is ready for backend integration and can be extended with additional features like image upload, location selection, and premium listings.

The code follows Flutter best practices and is maintainable, testable, and scalable.
