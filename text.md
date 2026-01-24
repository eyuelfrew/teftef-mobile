# Application User Interface Description

The application is a marketplace app with a clear and intuitive user interface. The UI is composed of five main screens:

1.  **Intro Screen**: This is the first screen the user sees. It serves as a welcome page and provides a brief introduction to the application's purpose. It has a "Get Started" button that navigates the user to the Home Page.

2.  **Home Page**: This is the main hub of the application. It displays a list of product categories and a grid of featured products. Users can tap on a category to see a list of products in that category or tap on a featured product to see its details.

3.  **Product List Page**: This screen displays a grid of products. It can show all products or be filtered to show products from a specific category. Each product is displayed in a `ProductCard` which shows the product's image, name, and price.

4.  **Product Detail Page**: This screen shows the details of a single product, including its image, name, description, and price. It also includes a "Contact Seller" button, which navigates the user to the Chat Page.

5.  **Chat Page**: This screen allows the user to communicate with the seller. It displays a history of chat messages and a text input field for sending new messages. The chat functionality is currently a simulation.

## UI Components

The application uses several reusable UI components to maintain a consistent look and feel:

*   **Category Card**: A card that displays a category's name and an icon. Tapping on it navigates to the `ProductListPage` for that category.
*   **Product Card**: A card that displays a product's image, name, and price. Tapping on it navigates to the `ProductDetailPage`.
*   **Message Item**: A component that displays a single chat message, with different styling for incoming and outgoing messages.

## Navigation Flow

The navigation flow is straightforward:

1.  The user starts at the **Intro Screen**.
2.  After tapping "Get Started", they are taken to the **Home Page**.
3.  From the **Home Page**, they can navigate to the **Product List Page** (by tapping a category) or the **Product Detail Page** (by tapping a product).
4.  From the **Product Detail Page**, they can navigate to the **Chat Page** to contact the seller.
