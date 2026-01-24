Create Product API Documentation
Endpoint
POST /api/products

Authentication
Required: Admin Token Header: Cookie: admin_token=<token> or potentially strict cookie-based depending on client handling, but currently 
requireAdmin
 checks req.cookies.admin_token. Note: If you need to call this from mobile app for regular users, the backend needs modification to allow non-admin access.

Content-Type
multipart/form-data

Parameters
Field	Type	Required	Description
name
String	Yes	Product name
description	String	No	Product description
price	Number	Yes	Price of the product
discount	Number	No	Discount percentage (0-100)
stock	Integer	No	Stock quantity
status	String	No	'active', 'draft', 'disabled' (Default: 'draft')
category	Integer	Yes	ID of the category
brand	Integer	No	ID of the brand
metadata	JSON String	No	Dynamic Form Data. JSON string containing key-value pairs for category-specific attributes (e.g., {"Color": "Red", "Size": "XL"})
images	File[]	No	Array of image files (Max 5). Key name: images
Example Request (Dart/Flutter with http package)
var request = http.MultipartRequest('POST', Uri.parse('YOUR_BASE_URL/api/products'));
// ... headers ...
request.fields['name'] = 'New Sneaker';
request.fields['price'] = '120.00';
request.fields['category'] = '1';
// Dynamic Form Data (Metadata)
// Collect your dynamic form values into a Map and encode as JSON string
Map<String, dynamic> dynamicAttributes = {
  'Size': '42',
  'Color': 'Black',
  'Material': 'Leather'
};
request.fields['metadata'] = jsonEncode(dynamicAttributes);
// ... files ...
// assuming imageFile is a File object request.files.add(await http.MultipartFile.fromPath('images', imageFile.path));

var response = await request.send();

if (response.statusCode == 201) { print('Product created!'); } else { print('Failed!'); }

## Response Success (201 Created)
```json
{
  "status": "success",
  "data": {
    "product": {
      "id": 101,
      "name": "New Sneaker",
      "price": "120.00",
      "images": [
        "/uploads/products/101/image-name.jpg"
      ],
      ...
    }
  }
}