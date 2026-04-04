# 🎓 CampusEats: Production-Grade Food Ordering System

CampusEats is a robust, full-stack food ordering solution designed for university campuses. It streamlines the process of ordering, paying for, and fulfilling canteen orders through a professional Flutter application and a secure NestJS backend.

---

## 🚀 Project Overview

The project is split into three main components:
1.  **Student App (Flutter)**: A modern interface for browsing menus, managing a cart, and making secure payments.
2.  **Canteen App (Flutter)**: A dedicated management portal for canteen staff to receive, verify, and fulfill orders.
3.  **Production Backend (NestJS)**: A secure, PostgreSQL-backed API handling authentication, order processing, and payment verification.

---

## 🛠️ Technology Stack

### Frontend (Flutter)
- **State Management**: Riverpod (Notifier & Provider)
- **Navigation**: GoRouter
- **Networking**: Http (with custom standardized `ApiClient`)
- **Payments**: Razorpay Flutter SDK
- **Styling**: Custom Design System (Premium Dark/Light modes)

### Backend (NestJS)
- **Framework**: NestJS (TypeScript)
- **Database**: PostgreSQL
- **ORM**: Prisma
- **Authentication**: JWT (Access + Refresh tokens) + Bcrypt
- **Payment Processing**: Razorpay Node SDK
- **Validation**: Class-validator + Class-transformer

---

## ✨ Features

### Student Side
- **Secure Registration/Login**: Email-based auth with password hashing.
- **Dynamic Menu**: Real-time menu categories and items fetched from the DB.
- **Advanced Cart**: Local state management for complex orders.
- **Razorpay Integration**: End-to-end secure payment flow.
- **Order History**: Track past and current orders with real-time status.
- **Digital Slips**: Instant receipt generation with unique 4-digit tokens.

### Canteen Side
- **OTP Authentication**: Secure login via phone number and one-time password (stored in DB).
- **Order Dashboard**: List of all paid orders sorted by time.
- **Status Management**: One-click "Complete" action to fulfill orders.
- **Order Verification**: Match 4-digit tokens printed on student slips.

---

## 📝 API Documentation

### Authentication (`/api/v1/auth`)
- `POST /student/register`: Register a new student.
- `POST /student/login`: Student login (Email/Password).
- `POST /canteen/request-otp`: Request a 4-digit OTP for canteen staff.
- `POST /canteen/verify-otp`: Verify OTP and login canteen staff.
- `POST /refresh`: Revoke old and issue new JWT tokens.

### Menu (`/api/v1/menu`)
- `GET /categories`: Fetch all menu categories.
- `GET /items`: Fetch menu items (supports `?category=` and `?search=` filters).
- `GET /items/:id`: Get single item details.

### Orders (`/api/v1/orders`)
- `POST /`: Create a new order (Status: `created`).
- `GET /my`: Fetch current student's order history.
- `GET /:id/slip`: Fetch generated receipt/slip data.

### Payments (`/api/v1/payments`)
- `POST /create-order`: Create a Razorpay Order ID on the backend.
- `POST /verify`: Verify HMAC signature and finalize order status to `paid`.

---

## 🧮 Core Algorithms & Logic

### 1. Server-Side Price Calculation
To prevent price tampering, the frontend only sends `menuItemId` and `quantity`. The backend fetches the latest prices from the database and calculates the `total` and `subtotal` securely.

### 2. Item Snapshotting
When an order is created, the system stores a "Snapshot" of the item name and price. This ensures that if the canteen changes a dish's price or name later, the student's past receipts remain accurate to what they actually paid.

### 3. Razorpay Signature Verification
The backend verifies every payment using a **SHA256 HMAC**.
`expected_signature = hmac_sha256(order_id + "|" + payment_id, secret)`
Only when this signature matches the one sent by the Razorpay SDK does the backend set the order status to `paid`.

### 4. 4-Digit Token Generation
For every order, a unique 4-digit **Token Number** is generated. The algorithm ensures uniqueness for all active orders on a given day, making it easy for canteen staff to call out numbers.

---

## 📂 File Structure

### Backend (`/backend`)
```text
src/
├── auth/            # JWT, Bcrypt, and OTP logic
├── menu/            # Menu & Category management
├── orders/          # Order lifecycle & Slip generation
├── payments/        # Razorpay SDK integration
├── prisma/          # Prisma Service setup
├── main.ts          # App entry & Global pipes
└── common/          # Guards, decorators, and interceptors
prisma/
└── schema.prisma    # PostgreSQL Schema Definition
```

### Frontend (`/lib`)
```text
lib/
├── core/            # Theme, Constants, and Shared Widgets
├── data/
│   ├── api/         # Base API Client
│   └── repositories/# Logic for Auth, Menu, Orders, Payments
├── features/
│   ├── auth/        # Login/Register UI
│   ├── student/     # Student Home, Cart, Checkout, History
│   └── canteen/     # Canteen Dashboard & Verification
└── models/          # Data classes (Order, MenuItem, etc.)
```

---

## 💡 Special Notes for Developers

### Physical Device Testing
If testing on a physical Android/iOS device while the backend runs on `localhost`, use **ADB Port Forwarding**:
```bash
adb reverse tcp:3000 tcp:3000
```
Then configure the app to hit `http://127.0.0.1:3000/api/v1`.

### Backend Dev Mode
When `OTP_DEV_MODE=true` in `.env`, the 4-digit canteen OTP is printed directly to the NestJS console to bypass the need for a real SMS gateway during development.

---

**Built with ❤️ by the CampusEats Team.**
