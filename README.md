# Plokitch

<p align="center">
  <img src="assets/images/logo.svg" width="200" alt="Plokitch Logo">
</p>

Plokitch is a modern Flutter application designed to bridge the gap between local kitchens, riders, and customers. It provides a seamless platform for food discovery, ordering, and delivery tracking.

## Features

- **Multi-Role Support**: Tailored experiences for Customers, Chefs (Kitchens), and Riders.
- **Map Discovery**: Explore nearby kitchens using an interactive map.
- **Marketplace**: Browse menus, filter by categories, and view detailed food information.
- **Real-time Tracking**: Monitor your orders from preparation to delivery.
- **Secure Payments**: Integrated payment flow with multiple methods.
- **Profile Management**: Easy setup for both consumers and service providers.

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Supabase account for backend services

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/plokitch-app.git
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Set up environment variables:
   Create a `.env` file in the root directory and add your Supabase credentials:
   ```env
   VITE_SUPABASE_URL=your_supabase_url
   VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
   VITE_API_URL=your_backend_api_url
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Tech Stack

- **Frontend**: Flutter, Jetpack Compose (for Android specific modules)
- **Backend**: Supabase
- **Maps**: Flutter Map, Leaflet
- **Icons**: Material Design Icons, Google Fonts

## Project Structure

- `lib/screens`: All UI screens for different flows.
- `lib/services`: API, Authentication, and Supabase integration.
- `lib/models`: Data models for vendors, items, and orders.
- `lib/widgets`: Reusable UI components.
- `lib/theme`: Global styling and themes.

---
*Built with ❤️ by the Plokitch Team*
