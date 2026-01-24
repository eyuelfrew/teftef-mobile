# Product Management API Requirements

This document describes the API endpoints needed for the "My Products" feature in the mobile app.

Users need to be able to:
- View all their posted products
- Filter products by status (active, draft, disabled)
- Update product status
- Delete products

---

## 1. Get User Products

**Endpoint:** `GET /api/users/me/products`

**Authentication:** Required (JWT Bearer Token)

**Query Parameters:**
- `status` (optional): Filter by status - 'active', 'draft', 'disabled'
- `page` (optional): Page number for pagination (default: 1)
- `limit` (optional): Items per page (default: 20)

**Request Headers:**
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

**Success Response (200):**
```json
{
  "status": "success",
  "data": {
    "products": [
      {
        "id": 101,
        "name": "iPhone 13 Pro Max",
        "description": "Brand new, sealed",
        "price": "45000.00",
        "status": "active",
        "category": {
          "id": 21,
          "name": "Mobile Phones"
        },
        "images": [
          "/uploads/products/101/image1.jpg",
          "/uploads/products/101/image2.jpg"
        ],
        "views": 150,
        "favorites": 12,
        "metadata": {
          "Storage": "256GB",
          "Color": "Sierra Blue"
        },
        "created_at": "2026-01-10T10:30:00Z",
        "updated_at": "2026-01-10T10:30:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 3,
      "total_items": 45,
      "items_per_page": 20
    }
  }
}
```

**Error Response (401):**
```json
{
  "status": "error",
  "message": "Authentication required"
}
```

---

## 2. Update Product Status

**Endpoint:** `PATCH /api/products/:productId`

**Authentication:** Required (JWT Bearer Token)

**URL Parameters:**
- `productId`: The ID of the product to update

**Request Headers:**
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

**Request Body:**
```json
{
  "status": "active"
}
```

**Allowed Status Values:**
- `active` - Product is live and visible to buyers
- `draft` - Product is saved but not published
- `disabled` - Product is hidden from listings

**Success Response (200):**
```json
{
  "status": "success",
  "message": "Product status updated successfully",
  "data": {
    "product": {
      "id": 101,
      "name": "iPhone 13 Pro Max",
      "status": "active",
      "updated_at": "2026-01-10T11:00:00Z"
    }
  }
}
```

**Error Response (403):**
```json
{
  "status": "error",
  "message": "You don't have permission to update this product"
}
```

**Error Response (404):**
```json
{
  "status": "error",
  "message": "Product not found"
}
```

---

## 3. Delete Product

**Endpoint:** `DELETE /api/products/:productId`

**Authentication:** Required (JWT Bearer Token)

**URL Parameters:**
- `productId`: The ID of the product to delete

**Request Headers:**
```
Authorization: Bearer <JWT_TOKEN>
```

**Success Response (200):**
```json
{
  "status": "success",
  "message": "Product deleted successfully"
}
```

**Error Response (403):**
```json
{
  "status": "error",
  "message": "You don't have permission to delete this product"
}
```

**Error Response (404):**
```json
{
  "status": "error",
  "message": "Product not found"
}
```

---

## Security Requirements

### Authorization Rules:
1. Users can only view/edit/delete their own products
2. Verify JWT token on all requests
3. Check product ownership before allowing updates/deletes
4. Admin users can manage all products (optional)

### Implementation Notes:
1. Extract user_id from JWT token
2. Query products where `user_id = <token_user_id>`
3. For updates/deletes, verify ownership:
   ```sql
   SELECT * FROM products 
   WHERE id = :productId AND user_id = :userId
   ```

---

## Database Schema Considerations

Ensure the `products` table has:
- `user_id` column (foreign key to users table)
- `status` column (enum: 'active', 'draft', 'disabled')
- `views` column (integer, default 0) - optional
- `favorites` column (integer, default 0) - optional
- Indexes on `user_id` and `status` for performance

---

## Testing with cURL

### Get User Products:
```bash
curl -X GET "http://localhost:5000/api/users/me/products?status=active" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Update Product Status:
```bash
curl -X PATCH "http://localhost:5000/api/products/101" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status": "draft"}'
```

### Delete Product:
```bash
curl -X DELETE "http://localhost:5000/api/products/101" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## Flutter App Implementation

The Flutter app already has:
- ✅ `MyProductsPage` - UI for managing products
- ✅ `ApiService.getUserProducts()` - Fetch user products
- ✅ `ApiService.updateProductStatus()` - Update status
- ✅ `ApiService.deleteProduct()` - Delete product
- ✅ JWT token authentication
- ✅ Navigation from Profile page

All API calls include the JWT token in the Authorization header.

---

## Next Steps for Backend

1. **Create the endpoints** listed above
2. **Add user_id to products table** if not already present
3. **Implement ownership verification** for update/delete operations
4. **Test with the mobile app** to ensure proper integration
5. **Add pagination support** for better performance with many products

---

## Questions?

If you need clarification on any endpoint or have questions about the expected behavior, please ask!
