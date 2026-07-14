# Solvix Go Logistics Integration

## Overview

Solvix Go is our logistics service provider that handles all delivery operations for the Plokitch platform. This documentation outlines how to integrate and work with Solvix Go's API endpoints, authentication, webhook systems, and delivery workflows.

## Table of Contents

1. [Authentication](#authentication)
2. [Create Delivery Request](#create-delivery-request)
3. [Track Delivery Status](#track-delivery-status)
4. [Cancel Delivery Request](#cancel-delivery-request)
5. [Webhook System & Signing](#webhook-system--signing)
6. [Full Procedure Workflow](#full-procedure-workflow)
7. [Error Handling](#error-handling)
8. [Best Practices](#best-practices)

---

## Authentication

All requests to Solvix Go API must include HTTPS and the following headers for authorization:

### Required Headers

```
X-Solvix-Public-Key: SOLVIX_PUBLIC_your_public_key_here
X-Solvix-Secret-Key: SOLVIX_SECRET_your_secret_key_here
```

**Setup Instructions:**
1. Obtain your public and secret keys from your Solvix Go dashboard
2. Store these securely in your environment variables (`.env` file)
3. Include them in every API request to Solvix Go
4. Never commit these keys to version control

---

## Create Delivery Request

### Endpoint

```
POST /api/v1/developer/order
```

### Request Payload

```json
{
  "pickupName": "Solvix Store",
  "pickupAddress": "24 Allen Avenue, Ikeja, Lagos",
  "receiverName": "Jane Doe",
  "receiverPhone": "08123456789",
  "deliveryAddress": "12 Toyin Street, Ikeja, Lagos",
  "packageDescription": "Assorted cupcakes box",
  "paymentType": "Cash"
}
```

### Request Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `pickupName` | String | Name of the pickup location/vendor |
| `pickupAddress` | String | Complete address for pickup |
| `receiverName` | String | Name of the recipient |
| `receiverPhone` | String | Phone number of the recipient |
| `deliveryAddress` | String | Complete delivery address |
| `packageDescription` | String | Description of the package/order |
| `paymentType` | String | Payment method (e.g., "Cash", "Card") |

### Response Format (201 Created)

```json
{
  "success": true,
  "data": {
    "deliveryId": "65b902e4822...",
    "status": "Pending",
    "pickupName": "Solvix Store",
    "pickupAddress": "24 Allen Avenue, Ikeja, Lagos",
    "receiverName": "Jane Doe",
    "receiverPhone": "08123456789",
    "deliveryAddress": "12 Toyin Street, Ikeja, Lagos",
    "packageDescription": "Assorted cupcakes box",
    "createdAt": "2026-06-28T00:00:00.000Z"
  }
}
```

### Implementation Example

```dart
Future<void> createDeliveryRequest({
  required String pickupName,
  required String pickupAddress,
  required String receiverName,
  required String receiverPhone,
  required String deliveryAddress,
  required String packageDescription,
  required String paymentType,
}) async {
  final headers = {
    'X-Solvix-Public-Key': 'SOLVIX_PUBLIC_your_public_key_here',
    'X-Solvix-Secret-Key': 'SOLVIX_SECRET_your_secret_key_here',
    'Content-Type': 'application/json',
  };

  final payload = {
    'pickupName': pickupName,
    'pickupAddress': pickupAddress,
    'receiverName': receiverName,
    'receiverPhone': receiverPhone,
    'deliveryAddress': deliveryAddress,
    'packageDescription': packageDescription,
    'paymentType': paymentType,
  };

  final response = await http.post(
    Uri.parse('https://solvix-api.com/api/v1/developer/order'),
    headers: headers,
    body: jsonEncode(payload),
  );

  if (response.statusCode == 201) {
    final data = jsonDecode(response.body);
    print('Delivery created: ${data['data']['deliveryId']}');
  } else {
    print('Error: ${response.body}');
  }
}
```

---

## Track Delivery Status

### Endpoint

```
GET /api/v1/developer/order/:id
```

### Path Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | String | The delivery ID returned from creation |

### Response Format (200 OK)

```json
{
  "success": true,
  "data": {
    "deliveryId": "65b902e4822...",
    "status": "In Transit",
    "riderName": "Emeka Rider",
    "pickupAddress": "24 Allen Avenue, Ikeja, Lagos",
    "deliveryAddress": "12 Toyin Street, Ikeja, Lagos",
    "createdAt": "2026-06-28T00:00:00.000Z"
  }
}
```

### Status Values

| Status | Description |
|--------|-------------|
| `Pending` | Delivery request created, awaiting rider assignment |
| `Assigned` | Rider has been assigned to the delivery |
| `Picked Up` | Package has been picked up from the sender |
| `In Transit` | Package is on the way to the recipient |
| `Delivered` | Package has been successfully delivered |
| `Cancelled` | Delivery has been cancelled |

### Implementation Example

```dart
Future<DeliveryStatus> trackDelivery(String deliveryId) async {
  final headers = {
    'X-Solvix-Public-Key': 'SOLVIX_PUBLIC_your_public_key_here',
    'X-Solvix-Secret-Key': 'SOLVIX_SECRET_your_secret_key_here',
  };

  final response = await http.get(
    Uri.parse('https://solvix-api.com/api/v1/developer/order/$deliveryId'),
    headers: headers,
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return DeliveryStatus.fromJson(data['data']);
  } else {
    throw Exception('Failed to track delivery');
  }
}
```

---

## Cancel Delivery Request

### Endpoint

```
POST /api/v1/developer/order/:id/cancel
```

### Path Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | String | The delivery ID to cancel |

### Response Format (200 OK)

```json
{
  "success": true,
  "message": "Order cancelled successfully",
  "data": {
    "deliveryId": "65b902e4822...",
    "status": "Cancelled"
  }
}
```

### Implementation Example

```dart
Future<void> cancelDelivery(String deliveryId) async {
  final headers = {
    'X-Solvix-Public-Key': 'SOLVIX_PUBLIC_your_public_key_here',
    'X-Solvix-Secret-Key': 'SOLVIX_SECRET_your_secret_key_here',
    'Content-Type': 'application/json',
  };

  final response = await http.post(
    Uri.parse('https://solvix-api.com/api/v1/developer/order/$deliveryId/cancel'),
    headers: headers,
  );

  if (response.statusCode == 200) {
    print('Delivery cancelled successfully');
  } else {
    throw Exception('Failed to cancel delivery');
  }
}
```

---

## Webhook System & Signing

### Overview

Solvix Go uses webhooks to notify your platform of delivery status changes in real-time. When a delivery status changes, Solvix Go sends a POST request to your configured webhook URL.

### Webhook Events

Webhooks are triggered when the delivery status changes to:

- `assigned` - Rider has been assigned
- `picked_up` - Package picked up from sender
- `in_transit` - Package in transit to recipient
- `delivered` - Package successfully delivered
- `cancelled` - Delivery cancelled

### Webhook Payload

```json
{
  "deliveryId": "65b902e4822...",
  "status": "in_transit",
  "riderName": "Emeka Rider",
  "timestamp": "2026-06-28T00:05:00.000Z"
}
```

### Webhook Security: Signature Verification

To verify that webhook requests originate from Solvix Go, check the `X-Solvix-Signature` header:

**Header:** `X-Solvix-Signature`
**Algorithm:** HMAC-SHA256 of the raw body payload using your Webhook Signing Secret

#### Implementation Example

```dart
import 'package:crypto/crypto.dart';

bool verifyWebhookSignature(String rawBody, String signature, String signingSecret) {
  // Calculate HMAC-SHA256 of the raw body using your signing secret
  final expectedSignature = Hmac(sha256, utf8.encode(signingSecret))
      .convert(utf8.encode(rawBody))
      .toString();

  // Compare with the received signature (timing-safe comparison recommended)
  return signature == expectedSignature;
}

// In your webhook endpoint handler:
Future<void> handleSolvixWebhook(String rawBody, String signature) async {
  if (!verifyWebhookSignature(rawBody, signature, 'YOUR_WEBHOOK_SIGNING_SECRET')) {
    throw UnauthorizedException('Invalid webhook signature');
  }

  final data = jsonDecode(rawBody);
  final deliveryId = data['deliveryId'];
  final status = data['status'];
  final timestamp = data['timestamp'];

  // Update your database with the new delivery status
  await updateDeliveryStatus(deliveryId, status);
}
```

---

## Full Procedure Workflow

### Step-by-Step Delivery Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                     CUSTOMER PLACES ORDER                           │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│         1. CREATE DELIVERY REQUEST (POST /api/v1/developer/order)   │
│                                                                      │
│  Input: Pickup details, receiver info, delivery address             │
│  Output: deliveryId, status = "Pending"                             │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
        ┌────────────────────────────────────────┐
        │  WAIT FOR WEBHOOK: status = "assigned" │
        │  Rider has been assigned to delivery   │
        └────────────────────────────────────────┘
                                    │
                                    ▼
        ┌────────────────────────────────────────┐
        │  WAIT FOR WEBHOOK: status = "picked_up"│
        │  Rider picked up package from sender   │
        └────────────────────────────────────────┘
                                    │
                                    ▼
        ┌────────────────────────────────────────┐
        │ WAIT FOR WEBHOOK: status = "in_transit"│
        │ Package is on the way to recipient     │
        └────────────────────────────────────────┘
                                    │
                                    ▼
        ┌────────────────────────────────────────┐
        │ WAIT FOR WEBHOOK: status = "delivered" │
        │ Package delivered successfully         │
        └────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   2. OPTIONAL: TRACK STATUS                         │
│              (GET /api/v1/developer/order/:id)                      │
│                                                                      │
│  Use this endpoint to manually check delivery status at any time    │
│  Useful for displaying real-time status to customers               │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│            3. OPTIONAL: CANCEL DELIVERY (IF NEEDED)                 │
│          (POST /api/v1/developer/order/:id/cancel)                  │
│                                                                      │
│  Cancel delivery if customer requests or issues arise               │
│  Status will change to "Cancelled"                                  │
└─────────────────────────────────────────────────────────────────────┘
```

### Integration Points in Plokitch

1. **Order Checkout**: When customer completes checkout, create delivery request
2. **Order Confirmation**: Store the returned `deliveryId` in order record
3. **Customer Dashboard**: Display delivery status from tracking endpoint
4. **Webhook Handler**: Listen for status updates and update order status in real-time
5. **Admin Dashboard**: Allow cancellation for pending/unassigned deliveries

---

## Error Handling

### Common HTTP Status Codes

| Status Code | Meaning | Action |
|------------|---------|--------|
| `201` | Created | Delivery request successful |
| `200` | OK | Request successful |
| `400` | Bad Request | Invalid payload or parameters |
| `401` | Unauthorized | Invalid or missing API keys |
| `404` | Not Found | Delivery ID not found |
| `429` | Too Many Requests | Rate limit exceeded; retry after delay |
| `500` | Server Error | Solvix Go server error; retry later |

### Error Response Format

```json
{
  "success": false,
  "message": "Error description",
  "code": "ERROR_CODE"
}
```

### Retry Strategy

```dart
Future<T> retryRequest<T>(
  Future<T> Function() request, {
  int maxRetries = 3,
  Duration delay = const Duration(seconds: 2),
}) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      return await request();
    } catch (e) {
      if (i < maxRetries - 1) {
        await Future.delayed(delay * (i + 1)); // Exponential backoff
      } else {
        rethrow;
      }
    }
  }
  throw Exception('Max retries exceeded');
}
```

---

## Best Practices

### 1. API Key Management
- Store keys in environment variables, never hardcode
- Use separate keys for development and production
- Rotate keys regularly for security
- Never commit keys to version control

### 2. Webhook Security
- Always verify webhook signatures before processing
- Use timing-safe comparison to prevent timing attacks
- Log all webhook events for debugging
- Implement idempotency to handle duplicate webhooks

### 3. Error Handling
- Implement exponential backoff for retries
- Log all API errors with timestamps
- Alert admins on critical failures
- Set up monitoring for failed deliveries

### 4. Performance
- Cache delivery statuses to reduce API calls
- Use webhooks instead of polling when possible
- Implement request timeouts (e.g., 30 seconds)
- Rate limit your requests to stay within Solvix Go limits

### 5. User Experience
- Show real-time delivery status to customers
- Send notifications on status changes
- Provide estimated delivery times (if available from Solvix)
- Allow customers to contact rider through Solvix platform

### 6. Testing
- Use sandbox/test credentials for development
- Mock webhook events for integration testing
- Test error scenarios and edge cases
- Verify signature verification with test payloads

---

## Additional Resources

- **Solvix Go Dashboard**: https://console.solvix-go.com
- **API Documentation**: Refer to plokitch-api repository for additional examples
- **Support**: Contact Solvix Go support team for API issues

---

**Last Updated:** 2026-07-14
**Version:** 1.0
