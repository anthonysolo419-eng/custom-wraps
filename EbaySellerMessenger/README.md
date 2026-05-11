# eBay Seller Messenger

A professional iOS messaging app for eBay sellers, built with SwiftUI. Provides a Facebook Messenger-style chat interface for managing buyer communications directly from your iPhone.

## Features

- **Threaded Conversations** — per-order chat threads with each buyer, messenger-style bubbles
- **Orders Dashboard** — all active orders with status, buyer info, item details, and pricing
- **Bulk Messaging** — select multiple orders and send one message to all buyers at once
- **Coupon Insertion** — create and insert discount coupons/deals directly into messages
- **Real-time Notifications** — push alerts for new buyer messages
- **Swipe Actions** — swipe to reply or archive conversations
- **eBay OAuth** — secure authentication via eBay Developer API credentials

## Requirements

- Xcode 15+ / iOS 17+
- eBay Developer Account (free at [developer.ebay.com](https://developer.ebay.com))
- eBay Seller Account

## Setup

### 1. eBay Developer Credentials

1. Create an account at [developer.ebay.com](https://developer.ebay.com)
2. Create a new application
3. Enable these API scopes:
   - `https://api.ebay.com/oauth/api_scope`
   - `https://api.ebay.com/oauth/api_scope/sell.fulfillment.readonly`
   - `https://api.ebay.com/oauth/api_scope/sell.message`
   - `https://api.ebay.com/oauth/api_scope/sell.message.readonly`
4. Add `ebaymessenger://oauth/callback` as a **RuName** (redirect URI)
5. Copy your **App ID (Client ID)** and **Cert ID (Client Secret)**

### 2. Open in Xcode

```bash
open EbaySellerMessenger.xcodeproj
```

### 3. Configure Signing

In Xcode → Target → Signing & Capabilities:
- Set your **Team**
- Change **Bundle Identifier** if needed (default: `com.ebaymessenger.app`)

### 4. Build & Run

Select your device or simulator and press **⌘R**.

On first launch, tap **Setup API Credentials** and enter your Client ID and Client Secret.

## Architecture

```
EbaySellerMessenger/
├── Models/          # Order, Message, Conversation, Coupon, EbayAuth
├── Services/        # EbayAuthService, EbayAPIService, OrdersService,
│                    # MessagingService, NotificationService
├── ViewModels/      # AuthViewModel, OrdersViewModel, ConversationViewModel
├── Views/
│   ├── Auth/        # LoginView, CredentialsSetupView
│   ├── Orders/      # OrdersListView, OrderRowView, OrderDetailView
│   ├── Messaging/   # ConversationsListView, ConversationView,
│   │                # MessageBubbleView, MessageInputView,
│   │                # CouponPickerView, BulkMessageView
│   └── Common/      # MainTabView, LoadingView, EmptyStateView
└── Utilities/       # KeychainHelper, Extensions
```

**Pattern:** MVVM + SwiftUI, async/await throughout, Keychain for credential storage.

## eBay APIs Used

| API | Purpose |
|-----|---------|
| `POST /identity/v1/oauth2/token` | OAuth 2.0 token exchange |
| `GET /sell/fulfillment/v1/order` | List active orders |
| `GET /sell/fulfillment/v1/order/{id}` | Order details |
| `GET /sell/message/v1/topic/{id}/message` | Fetch message thread |
| `POST /sell/message/v1/topic/{id}/message` | Send a message |

## Coupon System

Coupons are created and managed locally. When inserted into a message, they format as:

```
🎁 SPECIAL OFFER FOR YOU
Use code: SAVE10
10% OFF
Min. purchase: $20.00
Expires Jun 1, 2026
```

Three discount types supported: **Percentage Off**, **Dollar Amount Off**, **Free Shipping**.
