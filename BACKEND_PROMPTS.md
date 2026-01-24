# Backend API Implementation Prompts

## 1. User Authentication & Sync API

### Prompt:

```
I need to implement a user authentication sync endpoint for my marketplace app.

Requirements:

1. **Endpoint:** POST /api/auth/sync-user
   - No authentication required (this is the login endpoint)
   - Content-Type: application/json

2. **Request Body:**
```json
{
  "firebase_uid": "string (unique)",
  "email": "string",
  "display_name": "string",
  "photo_url": "string (optional)",
  "phone_number": "string (optional)",
  "email_verified": "boolean",
  "provider": "string (google/facebook)",
  "id_token": "string (Firebase ID token for verification)",
  "metadata": {
    "creation_time": "ISO 8601 datetime",
    "last_sign_in_time": "ISO 8601 datetime"
  }
}
```

3. **Response (200/201):**
```json
{
  "status": "success",
  "data": {
    "user_id": 123,
    "firebase_uid": "...",
    "email": "...",
    "display_name": "...",
    "photo_url": "...",
    "access_token": "jwt_token_here",
    "is_new_user": true/false
  },
  "message": "User synced successfully"
}
```

4. **Business Logic:**
   - Check if user exists by firebase_uid
   - If exists: Update user info and last_sign_in_time
   - If new: Create new user record
   - Generate JWT access token for the user
   - Return user data with token

5. **Database Schema (users table):**
   - id (primary key)
   - firebase_uid (unique, indexed)
   - email (unique)
   - display_name
   - photo_url
   - phone_number
   - email_verified
   - provider
   - created_at
   - updated_at
   - last_sign_in_at

Please implement this endpoint with proper error handling.
```

---

## 2. Modify Product Creation for Regular Users

### Prompt:

```
I need to modify the existing POST /api/products endpoint to allow regular authenticated users (not just admins) to create products.

Current Issue:
- Endpoint requires admin authentication (admin_token cookie)
- Regular users can't post products

Required Changes:

1. **Authentication:**
   - Accept JWT token from Authorization header: `Bearer <token>`
   - Verify JWT token and extract user_id
   - Allow both admin and regular users to create products

2. **Modified Endpoint:** POST /api/products
   - Headers: 
     - Authorization: Bearer <jwt_token>
     - Content-Type: multipart/form-data

3. **Additional Fields:**
   - Automatically set `user_id` from authenticated user
   - Set `status` to 'draft' by default for regular users
   - Admins can set any status

4. **Request Fields (same as before):**
   - name (required)
   - description
   - price (required)
   - discount
   - stock
   - status (default: 'draft')
   - category (required)
   - brand
   - metadata (JSON string for dynamic attributes)
   - images (file array, max 5)

5. **Response (201):**
```json
{
  "status": "success",
  "data": {
    "product": {
      "id": 101,
      "name": "Product Name",
      "user_id": 123,
      "status": "draft",
      ...
    }
  },
  "message": "Product created successfully"
}
```

6. **Database Schema Update (products table):**
   - Add `user_id` column (foreign key to users table)
   - Index on user_id for faster queries

7. **Middleware:**
   - Create `authenticateUser` middleware to verify JWT
   - Replace `requireAdmin` with `authenticateUser` for product creation
   - Keep `requireAdmin` for product approval/deletion

Please implement these changes with proper JWT verification and error handling.
```

---

## 3. Get User's Products API

### Prompt:

```
Create an endpoint to fetch products posted by the authenticated user.

Endpoint: GET /api/users/me/products

Authentication: Required (JWT Bearer token)

Query Parameters:
- status: Filter by status (active, draft, disabled) - optional
- page: Page number (default: 1)
- limit: Items per page (default: 20)

Response (200):
```json
{
  "status": "success",
  "data": {
    "products": [
      {
        "id": 101,
        "name": "Product Name",
        "price": "120.00",
        "status": "draft",
        "category": {
          "id": 1,
          "name": "Category Name"
        },
        "images": ["/uploads/..."],
        "created_at": "2024-01-10T...",
        "views": 0,
        "favorites": 0
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 5,
      "total_items": 100,
      "items_per_page": 20
    }
  }
}
```

Please implement this endpoint with pagination and filtering.
```

---

## 4. JWT Token Generation & Verification

### Prompt:

```
Implement JWT token generation and verification utilities for user authentication.

Requirements:

1. **Generate JWT Token:**
```javascript
function generateToken(userId, email) {
  // Payload
  const payload = {
    user_id: userId,
    email: email,
    type: 'access'
  };
  
  // Options
  const options = {
    expiresIn: '7d' // Token valid for 7 days
  };
  
  // Sign with secret
  return jwt.sign(payload, process.env.JWT_SECRET, options);
}
```

2. **Verify JWT Token Middleware:**
```javascript
function authenticateUser(req, res, next) {
  // Get token from Authorization header
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      status: 'error',
      message: 'No token provided'
    });
  }
  
  const token = authHeader.split(' ')[1];
  
  try {
    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Attach user info to request
    req.user = {
      id: decoded.user_id,
      email: decoded.email
    };
    
    next();
  } catch (error) {
    return res.status(401).json({
      status: 'error',
      message: 'Invalid or expired token'
    });
  }
}
```

3. **Environment Variable:**
   - Add JWT_SECRET to .env file
   - Use a strong random string (at least 32 characters)

4. **Dependencies:**
   - Install: `npm install jsonwebtoken`

Please implement these utilities and integrate them into the authentication flow.
```

---

## 5. Update API Service Base URL Configuration

### Note for Flutter App:

The Flutter app is currently configured to use:
- **Web/Windows/iOS Simulator:** `http://localhost:5000/api`
- **Android Emulator:** `http://10.0.2.2:5000/api`

Make sure your backend is running on port 5000, or update the Flutter app's `lib/services/api_service.dart` to match your backend port.

---

## Implementation Order:

1. ✅ **First:** Implement User Sync API (Prompt #1)
2. ✅ **Second:** Implement JWT utilities (Prompt #4)
3. ✅ **Third:** Modify Product Creation API (Prompt #2)
4. ✅ **Fourth:** Implement Get User Products API (Prompt #3)

---

## Testing:

After implementation, test with these curl commands:

### 1. Test User Sync:
```bash
curl -X POST http://localhost:5000/api/auth/sync-user \
  -H "Content-Type: application/json" \
  -d '{
    "firebase_uid": "test123",
    "email": "test@example.com",
    "display_name": "Test User",
    "provider": "google",
    "email_verified": true
  }'
```

### 2. Test Product Creation:
```bash
curl -X POST http://localhost:5000/api/products \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "name=Test Product" \
  -F "price=100" \
  -F "category=1" \
  -F "description=Test description" \
  -F 'metadata={"Color":"Red","Size":"M"}'
```

### 3. Test Get User Products:
```bash
curl -X GET http://localhost:5000/api/users/me/products \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```
