# CampusEats (Campus-Eats-2) Project Documentation

## 1. Project Overview
**CampusEats** is a modern, production-grade Flutter application designed to streamline the food ordering process in university canteens. It features a dual-user experience tailored for both **Students** (searching, ordering, tracking) and **Canteen Staff** (order management, dashboard analytics).

---

## 2. Technical Stack
- **Framework**: Flutter (Dart ^3.11.0)
- **State Management**: Riverpod (`flutter_riverpod`, `riverpod_annotation`)
- **Navigation**: `go_router`
- **UI/UX**: 
  - `google_fonts` (Inter/Outfit for typography)
  - `flutter_animate` (Micro-animations)
  - `shimmer` (Loading states)
  - `cached_network_image` (Image optimization)
- **Local Persistence**: `shared_preferences` and `hive_flutter`
- **Architecture**: **Clean Architecture** with a Feature-First folder structure:
  - `lib/core`: Global utilities, theme configuration, constants.
  - `lib/data`: Data repositories and data sources (currently using Mock implementations).
  - `lib/features`: Feature-specific UI components and business logic.
  - `lib/models`: Shared data models (Order, User, Cart, Category).

---

## 3. Completed Features

### 🟢 Student Experience
- **Home Dashboard**: Categorized food items (Traditional, Fast Food, Drinks) with search functionality.
- **Cart Management**: Real-time cart updates with increment/decrement logic.
- **Checkout Flow**: Interactive checkout with multiple payment method selection (Mocked).
- **Pro Digital Receipt**: Order tracking with live status updates, itemized breakdown, and QR code security.
- **Order History**: Persistent history of past and active orders.

### 🟡 Canteen Experience
- **Staff Dashboard**: Real-time view of "Preparing" and "Ready" orders.
- **Order Management**: Search orders by Token ID, Student Name, or Department.
- **Quick Status Updates**: One-tap status transitions (e.g., Preparing → Ready → Completed).
- **Analytics Overview**: Daily earnings summary and order volume tracking.

---

## 4. Backend Details & Requirements (The "Gaps")
The application is currently a **fully functional frontend prototype**. All data is handled through **mock repositories** in `lib/data/mock/`. To complete the project fully, the following backend infrastructure is needed:

### 🚀 Backend Checklist

#### 1. Cloud Authentication (Identity)
- **Requirement**: Replace current static mock login with a dynamic service.
- **Goal**: Enable students and staff to log in securely and maintain their profile/history across devices.
- **Best Fit**: **Firebase Auth** (simplest) or a **custom Node.js/FastAPI** server with JWT.

#### 2. Real-time Database (The Engine)
- **Requirement**: A persistent cloud database to store user data, product menus, and orders.
- **Goal**: Sync orders between students and canteen staff. When a student clicks "Order," it should pop up instantly on the canteen's dashboard.
- **Best Fit**: **Firestore** (Real-time sync handles many edge cases automatically).

#### 3. Push Notifications (User Engagement)
- **Requirement**: Send notifications for order status changes.
- **Goal**: "Your food is ready for pickup!" notifications.
- **Best Fit**: **Firebase Cloud Messaging (FCM)**.

#### 4. REST/GraphQL API layer
- **Requirement**: An API to serve menus and handle order processing logic.
- **Goal**: Centralize business logic instead of keeping it all in the frontend.
- **Best Fit**: If using Firebase,Cloud Functions. Otherwise, a standard REST API.

#### 5. Payment Gateway
- **Requirement**: Real-world payment processing.
- **Goal**: Transition from "Mock Payment Successful" to actual transactions.
- **Best Fit**: **Razorpay** or **Stripe** SDKs.

---

## 5. Repository Structure
```text
lib/
├── app/         # Application configuration & Routing
├── core/        # Theme, Utils, Connectivity logic
├── data/        # Repositories & Mock Data Sources
├── features/    # UI Screens & Riverpod Providers
├── models/      # Plain Data Objects
└── main.dart    # App entry point
```
