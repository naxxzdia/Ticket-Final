<div align="center">
 
## Event Tickets Demo App

Modern ticket purchasing & e‑ticket experience (Flutter) featuring a 3‑step checkout flow, dynamic palette E‑Ticket, local ticket persistence, Active / Passed segmentation and shareable QR / Barcode.

</div>

---

## ✨ Core Features

- 3‑Step Checkout Flow (Checkout → Payment → Success → E‑Ticket)
- Dynamic zone pricing (VVIP / VIP / Regular; derived if not provided by backend)
- Local persistence of purchased tickets (`SharedPreferences`) with auto “Passed” status
- Tickets tab with segmented control: Active / Passed
- Swipe‑to‑delete individual ticket + Clear All action
- E‑Ticket: dynamic color palette from poster, glassmorphism card, QR ↔ Barcode toggle, share as image (RepaintBoundary capture)
- Order ID generation utility (stable pseudo id from event id)
- Safe seat label mock + total price breakdown

---

## 🧭 User Flow Overview

1. Open an event → tap “Buy Tickets” → opens 3‑step checkout
2. Step 1 – Checkout
	- Choose zone & quantity
	- See live order summary (subtotal, mock wallet, discount, total)
	- Continue to payment
3. Step 2 – Payment
	- Pick payment method (Credit Card, PayPal, Apple Pay, Google Pay – mock) 
	- Press Pay → simulated processing → success state
4. Step 3 – Success
	- “Payment Successful” screen → View Ticket
5. E‑Ticket Screen
	- Shows full digital ticket (palette, seat, QR/Barcode, share)
6. Tickets Tab
	- Newly purchased ticket appears under “Active”
	- After event date passes (local clock) ticket auto moves to “Passed”

---

## 🗂 Architecture Snapshot

| Layer | Purpose | Key Files |
|-------|---------|-----------|
| Models | Domain objects (Event, PurchasedTicket) | `lib/models/event.dart`, `lib/models/purchased_ticket.dart` |
| Services | Persistence & helpers | `lib/services/ticket_storage.dart`, `lib/util/id_utils.dart` |
| Screens | UI pages & flow | `lib/screens/checkout/checkout_flow_screen.dart`, `lib/screens/ticket_eticket_screen.dart`, `lib/screens/tickets_tab.dart`, `lib/screens/event_detail_screen.dart` |
| Widgets (inline) | Local composition pieces | inside corresponding screens |

### Ticket Persistence
`TicketStorage` (singleton) stores a list of `PurchasedTicket` serialized as JSON in `SharedPreferences` under key `purchased_tickets`.

On load:
1. Read & decode list
2. Refresh `passed` flag where `eventDate < now`

On add:
1. Construct ticket with runtime `uuid` for unique `id`
2. Derive `orderId` (via `generateOrderId(event.id)`) 
3. Append & persist

Deletion:
- Swipe (Dismissible) → confirm dialog → `TicketStorage.remove(id)`
- Clear All → header trash icon → confirm → `TicketStorage.clearAll()`

### Order ID Strategy
Deterministic pseudo id: mask `eventId.hashCode & 0xFFFFFF` → 6 hex uppercase; prefixed with `EVT`. Provides stable visual reference while avoiding full randomness. (If a truly unique per purchase id is needed, you can switch to UUID v4.)

---

## 🖼 E‑Ticket Design Highlights

- Poster → palette extraction (dominant / vibrant) for radial background + glowing glass card stroke
- Glass / blur card with clipped notches (`CustomClipper`)
- Toggle QR / mock barcode (`AnimatedSwitcher`)
- Share button → RepaintBoundary capture → share_plus
- Responsive seat label & code string

---

## 🧾 Tickets Tab UX

| Action | Result |
|--------|--------|
| Pull to refresh | Reload + recalc Passed state |
| Tap ticket | Opens E‑Ticket (reusing stored data) |
| Swipe left | Delete (with confirm) |
| Trash icon | Clear all stored tickets |
| Segment switch | Filter Active vs Passed |

Passed logic uses local device time only (no network clock sync yet).

---

## 🔌 Extensibility Ideas

- Real payment integration (Stripe, PayPal SDK) replacing mock delay
- Real seat mapping & specific seat codes instead of range mock
- Promo codes & dynamic discount rows
- Cloud sync of purchased tickets (Firestore) with device restore
- In-app wallet / credits & partial payment logic
- PDF / Apple Wallet pass export
- Push reminder before event start

---

## 🛠 Tech Stack

- Flutter (Dart 3)
- Shared Preferences (local persistence)
- uuid (ticket instance id)
- palette_generator (color extraction)
- qr_flutter (QR rendering)
- share_plus (image sharing)
- Firebase Core/Auth (initialized boilerplate – auth not yet wired to ticket ownership)

---

## ▶️ Running Locally

Prerequisites: Flutter SDK installed & device/emulator running.

1. Fetch packages
	```bash
	flutter pub get
	```
2. (Optional) Run mock API (if using `json-server` for events)
	```bash
	json-server --watch db.json --port 3000
	```
3. Launch app
	```bash
	flutter run
	```

If build fails due to stale artifacts, try:
```bash
flutter clean && flutter pub get && flutter run
```

---

## 🔍 Key File Map

| Feature | File |
|---------|------|
| Checkout flow | `lib/screens/checkout/checkout_flow_screen.dart` |
| E‑Ticket + Share | `lib/screens/ticket_eticket_screen.dart` |
| Tickets list | `lib/screens/tickets_tab.dart` |
| Ticket storage | `lib/services/ticket_storage.dart` |
| Models | `lib/models/` |
| OrderId util | `lib/util/id_utils.dart` |

---

## 🧪 Basic Test Ideas (Not yet implemented)

- Storage add/remove round trip
- OrderId generation deterministic
- Ticket moves to Passed after mocked time shift
- Checkout to success path integration

---

## ⚠️ Notes & Limitations

- No real payment or authentication binding to tickets yet
- Passed calculation is non-reactive to timezone changes mid-session
- Palette extraction is best-effort; failures fall back to neutral colors silently
- Barcode is a visual mock (not a scannable standard format)

---

## 📄 License
Internal demo / educational usage. Add a proper license if distributing.

---

Enjoy building on top of this foundation! 🚀
