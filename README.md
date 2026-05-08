# Kof - A Self-Contained, Offline First, Coffee Shop Ordering Platform

**The README below was made with the assistance of AI.**

**Kof** is a self-contained ordering platform for independent coffee shops. A customer walks into a café, scans the QR code on their table (or on the counter), browses the live menu on their phone, and places an order. The order appears instantly on the shop's dashboard, and the customer gets real-time updates as their drink moves from "new" → "making" → "ready".

The project has two parts that work together:

- **A mobile app** that customers install (or browse as a guest). 
- **A backend server** that each coffee shop runs locally - no third-party platform, no monthly fees, no commission per order
**Both are available in English, Finnish and Portuguese languages**

This is a purely personal portfolio project. It is not a real commercial product, but it is built end-to-end as if it were one.

---

## A normal day with Kof, from the customer's side

Imagine you walk into a café called **Helsinki's Finest**. Here is how Kof works for you:

1. **You sit at a table.** There is a small printed card with a QR code. You scan it with your phone's camera.
2. **The Kof app opens** to the café's live menu. You can browse Espresso, Hot Drinks, Cold Drinks, Pastries, and Food. Items that are out of stock are clearly marked. Items running low say "Low stock". Each drink shows its photo, description, and price.
3. **You tap a Latte.** Pick a size (Small / Medium / Large), tweak the milk type, add an extra shot if you want. Tap **Add**.
4. **You also pick a Chocolate Muffin.** A green badge on the discount icon tells you the shop has 1 active deal. You tap it. The deal: *"100% off 1 drink when buying any pastry."* It even shows you the code: `MUFFIN`.
5. **You open your cart.** You see your two items, a notes field ("no sugar, please"), and a coupon-code box. You type `MUFFIN` and tap **Apply**. The total drops from €5.70 to €2.50 - the muffin's price. The breakdown is shown clearly: Subtotal, Discount, Total.
6. **You place the order.** It is sent to the shop's dashboard the second you tap. You go to the order status screen. A pulsing radar shows your order is "New".
7. **A minute later** your phone vibrates: the status changes to "Making". A bit later: "Ready". The barista calls your name. You collect your drink and pastry.
8. **You like the place.** You tap the heart on the shop's page to **follow** it. From now on, when this shop runs a Friday morning special, you get a push notification.
9. **A week later**, the same shop sends a notification: *"Half-price croissants today!"*. You tap it. The app opens straight to that shop's page so you can plan a visit.

That is the core loop. Around it sit a number of smaller details that exist because real people use real apps in messy ways.

---

## What you can and cannot do

**As a guest** (no account, just opened the app):
- ✅ Scan a QR code, browse the menu, place orders.
- ✅ Follow shops you like - these are saved on your device.
- ✅ See your past orders - these are also saved on your device.
- ✅ Switch the app to English, Portuguese, or Finnish.
- ❌ Sync your followed shops or order history across devices (because there is no account yet).
- ❌ Edit a profile name, photo, or phone number.

**As a signed-in user** (email + password, or Google, or Apple if available):
- ✅ Everything a guest can do, plus:
- ✅ Edit your display name, profile picture, phone number, and e-mail address.
- ✅ Verify your e-mail before the account is activated.
- ✅ Reset your password.
- ✅ Followed shops sync to the cloud - visible from any device you log in on.
- ✅ Receive push notifications from shops you follow.
- ✅ Pick the country dial-code for your phone with a flag picker (Portugal-first, but auto-detects if you paste a +44 number, etc.).

**The "guest → account" handoff** *(this is the small detail that took the most care)*:
If you started as a guest and accumulated orders or followed shops, then later decided to register, the app will detect your guest data and offer to **move it to your new account**. One tap → it is migrated. This works even if you logged out as guest first and only later signed in with Google. You can also decline, in which case the guest data is cleared so the prompt does not nag you.

**As a coffee shop manager** (using the staff dashboard):
- ✅ See every incoming order on a live board, split by status (New / Making / Ready / Completed / Cancelled).
- ✅ Hear a "ding" when a new order comes in. Adjust the volume. Test the sound.
- ✅ Mark orders paid / unpaid, change their status, print a receipt.
- ✅ Manage the menu (add items, prices, descriptions, sizes, categories, ingredients).
- ✅ Manage stock and watch low-stock alerts.
- ✅ Generate Wi-Fi QR codes for customers and printable table QR codes.
- ✅ Register the shop on the public **Kof Platform** (a Firebase-backed shop registry visible inside the customer app).
- ✅ Create discount codes with cart-aware conditions ("100% off 1 drink when buying a muffin", "10% off everything for code SUMMER25", etc.).
- ✅ Send a push notification to every customer who follows the shop.
- ✅ See order history with totals and applied discounts.
- ✅ Use the dashboard in English, Portuguese, or Finnish, in light or dark mode.

---

## Every feature in detail

A long list - but the user explicitly asked for it. Each item is implemented and reachable from the UI.

### Customer-facing - Browsing & Ordering
- QR code scanner with a custom corner-frame overlay
- Manual entry fallback for emulators / when a camera is unavailable
- Live menu with category filter pills
- Per-item availability (available / low stock / unavailable) - driven by the shop's recipe + ingredient stock
- Sizes, modifiers (milk type, extra shot)
- Cart with quantity steppers, item notes, order-level notes
- Coupon-code input with live validation, error hints ("Add a Pastries item to use this coupon"), and a Subtotal / Discount / Total breakdown
- Walk-in flow without a table (counter pickup) - type your name, get an order number, the staff calls you when it's ready
- Real-time order status tracking via WebSocket - "New / Making / Ready / Completed / Cancelled"
- Floating "active orders" bubble overlaid on every screen with a soft radar pulse
- Tap an active order from anywhere → opens the order status screen
- Receipt screen for paid orders, with a one-tap **Share** action that captures the receipt as a PNG and opens the system share sheet (save to gallery, send by message, print)
- "Order Again" - re-place a previous order in one tap (skips items that are no longer available, with a notice)

### Customer-facing - Account & Personal Data
- Sign up / sign in with e-mail + password
- Sign in with Google
- Sign in as a guest (no account, full app access except cross-device sync)
- Apple Sign-In button is wired in (currently shows a "not available yet" message - the actual Apple flow needs a paid Apple Developer account)
- E-mail verification before account activation
- Forgot-password flow (sends a reset e-mail)
- Account Settings: edit name, profile picture (camera or gallery → uploads to Firebase Storage), phone, e-mail, country
- Phone-number field with a country-flag picker - auto-detects country from a typed `+351...` prefix
- Verified-then-update e-mail change (re-auth with current password first)
- Persistent session across app restarts
- **Guest → registered-account migration** prompt described above
- Multi-language: English, Português, Suomi - every single user-facing string is localized; even error messages
- Light / Dark / System theme

### Customer-facing - Discovery
- Home screen with greeting, "Scan QR" card, and a map of nearby shops
- Shop detail screen: name, address, photo, rating, follow button, opening hours, tags
- **Followed Shops** screen
- Reviews screen (with sample data) - score is synced back to Firestore
- Shop's discounts screen - shows percentage / amount, validity dates, conditions ("Requires Pastries", "On 1× Hot Drinks"), and either a copy-able promo code or a "Claim at the counter when paying" hint when no code is set
- Active-discount count badge over the discount icon

### Customer-facing - Notifications
- Push notifications via Firebase Cloud Messaging
- Tapping a notification opens the originating shop's detail screen - even from a cold start (the app holds the message until auth is ready, then drains it)
- In-app notifications screen entries are tappable and route to the shop
- Bell icon on the home screen with an unread-count badge
- Apple-only items (iOS push, Live Activities, Dynamic Island) are designed but blocked on a paid Apple Developer account

### Side drawer
- Profile header (tappable for signed-in users - opens Account Settings)
- My Orders, Followed Shops, Settings, Logout
- Privacy Policy and Terms screens (placeholder content marked as a personal project)
- Contact Us - opens the user's mail app to `customersupport@kof.example.com`
- Build version pinned at the bottom

### Shop-facing - Staff dashboard (web)
- Live order board - five columns, websocket-driven, no manual refresh needed
- New-order ding sound with adjustable volume saved per staff user
- Each order card shows order number, customer or table, items with modifiers, note, total, and (when applicable) a Subtotal / Discount (Coupon CODE) / Total breakdown
- One-click status changes, mark paid/unpaid, "back to new" undo
- One-click receipt link for paid orders
- Inventory page: ingredients with stock and low-stock thresholds, drink availability matrix, recent stock adjustments at the top
- History page: completed/cancelled orders from previous days with filters
- Toolbar buttons: Staff / Inventory / History / Manager / Admin / Settings - each visible based on the user's role
- Login from the web - Enter key submits the form
- Dark mode + English / Português / Suomi

### Shop-facing - Manager page (web)
A dedicated manager-only page with three tabs:
- **Kof Platform** - register the shop on the public registry. Filling this in makes the shop appear on the customer app's map. Detects when the server has no internet and lets the manager save the form locally to publish later.
- **Discounts** - full CRUD over discount codes. Each discount has: title, description, percentage off OR flat amount, optional code, validity window, and **cart-aware conditions** (required category and target category, both supporting comma-separated lists like "Hot Drinks, Espresso, Cold Drinks", plus a target quantity for "1 free drink"-style offers).
- **Customer Notifications** - write a title and body, hit send, every follower of the shop gets a push notification on their phone. Recent broadcasts are listed.

### Shop-facing - Admin page (web)
- PIN security (change own PIN, manager can reset other staff PINs, hide/show)
- Staff user management - create, disable, set role (manager / barista)
- Menu management - add/edit/disable items, set prices, sizes, categories, recipes (which ingredients, how much per item)
- Wi-Fi QR generator - print one for the entrance so customers can connect before ordering
- Table QR generator - generate signed table tokens, print them as QR codes
- Audit log of admin actions

### Backend resilience & operations
- SQLite with WAL journaling
- Foreign keys enforced; cascading deletes for orders → items + status history; soft-link (SET NULL) for inventory adjustments so deleting an order doesn't lose the stock-deduction record
- Daily-resetting per-shop order numbers (#1, #2, #3...)
- Atomic inventory deduction on "completed" - concurrent calls cannot double-deduct
- Server-computed discount cents (the client cannot fake the discount amount, even though it can preview it)
- Capacity gate (`max_concurrent_orders` shop setting) returns 503 when at capacity
- IP-based rate limit on order creation (10/minute) to prevent spam
- WebSocket broadcasts: `order_created` (staff-only), `order_status_changed`, `order_payment_changed`, `low_stock`
- Backwards-safe schema migrations on startup (`ALTER TABLE … ADD COLUMN IF NOT EXISTS` style)
- Maintenance scripts: nightly database backup with N-day retention; cleanup that prunes old orders, audit log entries, and stale inventory adjustments - all configurable via env vars

---

## Tech stack, briefly

**Mobile app** - Flutter (Dart), Provider for state, Firebase Auth + Firestore + Cloud Messaging + Storage, Google Sign-In, Google Maps, image_picker, share_plus, intl_phone_field, mobile_scanner, web_socket_channel.

**Backend** - Node.js + Express, better-sqlite3 (SQLite), `ws` for WebSockets, JWT for staff auth, Firebase Admin SDK (for the public Kof Platform registry and FCM broadcasts), Cloud Functions for the broadcast-to-followers fan-out.

**Languages** - UI fully localized in English, Português, Suomi.

---

## Project layout

```
Kof/
├── kof_app/      Flutter app (iOS + Android)
└── kof_server/   Node.js backend + staff web dashboard
```

---

## Running it locally

> Both halves are required for the full experience. The backend serves the staff dashboard at `http://localhost:3000` and exposes the API the mobile app talks to.

**Backend:**
```bash
cd kof_server
npm install
cp .env.example .env   # fill in Firebase + JWT secrets
node src/index.js
```

**Mobile app:**
```bash
cd kof_app
flutter pub get
flutter gen-l10n
flutter run
```
**Mobile app (DEMO VERSION):**
```bash
cd kof_app
flutter pub get
flutter gen-l10n
flutter run --dart-define=DEMO_MODE=true
```


For Firebase features you'll need:
- `kof_app/android/app/google-services.json`
- `kof_app/ios/Runner/GoogleService-Info.plist`
- `kof_server/firebase-service-account.json`

These come from your own Firebase project (free tier is enough for development).

A Google Maps API key goes in `kof_app/android/app/src/main/AndroidManifest.xml` and `ios/Runner/AppDelegate.swift`.

For deployment on a Raspberry Pi inside a coffee shop, see `kof_server/DEPLOYMENT.md`.

---

## License

MIT - see [LICENSE](LICENSE).
