# ISSA — Sales Tracker App Build Prompt

## App overview
Build **ISSA**, a Flutter (cross-platform, Android target) sales tracker app for a small retail/reselling business run by the user's mother. The app must be **fully offline** — all data lives on the device only, no cloud sync, no backend, no login required.

## Core features

1. **Product inventory**
   - List every product owned: name, quantity, and cost price (capital).
   - Quantity is stored as a `double` in kilograms, so it naturally supports whole kg and half-kg (0.5) increments. No separate "unit type" field needed — just allow decimal input in steps of 0.5.

2. **Cost price (capital) tracking**
   - Each product has a cost price per unit (per kg).
   - Capital value of a product = `quantity * costPrice`.

3. **Cost price table**
   - A dedicated screen showing a sortable table of every product and its current cost price, for quick reference.

4. **Sell flow**
   - User selects a product, enters quantity sold (kg / half-kg stepper), and a sell price (auto-filled from cost price but editable).
   - On confirm: this is a single atomic DB transaction that (a) decrements the product's quantity, and (b) inserts a new `Sale` row recording quantity sold, sell price, **and the product's cost price at the time of sale** (so later cost-price edits don't retroactively change past profit calculations).

5. **Dashboard / stats view**
   - **Total Capital**: sum of `quantity * costPrice` across all current inventory.
   - **Total Sold**: sum of `sellPrice * quantitySold` across all sales.
   - **Profit**: sum of `(sellPrice - costPriceAtSale) * quantitySold` across all sales.
   - Optional: simple chart (e.g. profit over time) using `fl_chart`.

6. **Receipt scanning (OCR) for restocking capital**
   - User photographs or picks a receipt image.
   - On-device OCR (no internet call) extracts candidate line items: product name, quantity, price.
   - **Double-check step (required, non-negotiable UX rule)**: OCR output populates an editable review list. Nothing is written to the database until the user explicitly confirms each line (or "confirm all"). Each line is editable before confirming, so misreads can be corrected.
   - Confirmed lines are added as new capital entries (increase product quantity, optionally update cost price if changed).

7. **Visual design**
   - Light mode only, light lavender color palette:
     - Background: `#F7F4FC`
     - Primary: `#B79CED` (or `#9B87C4` as a slightly deeper alternative)
     - Accent: `#D8CCF0`
     - Text: `#3A2E52` (dark plum — chosen for contrast/accessibility against the lavender background; do not use pale lavender for body text)
   - Clean, simple UI appropriate for a non-technical user (the client is the developer's mother) — large tap targets, clear labels, minimal jargon.

## Tech stack (decided)
- **Framework**: Flutter (Dart), targeting Android.
- **Local database**: `drift` (SQLite wrapper) — chosen over plain `sqflite` for its support of relational queries/joins/aggregates needed for the dashboard sums.
- **State management**: `riverpod`.
- **OCR**: `google_mlkit_text_recognition` — on-device, free, works offline.
- **Charts (optional)**: `fl_chart`.
- **No backend, no Firebase, no cloud storage** — everything persists locally via drift/SQLite.

## Data model (batch/lot tracking)

Capital is tracked per **batch** (each restock is its own lot with its own cost price), not as a single flattened quantity + cost price on the product. This lets the user edit a wrong quantity entry or update a new restock's price without altering past sales' recorded profit.

```dart
// Product
- id
- name
// totalQuantity and latestCostPrice are DERIVED, not stored:
//   totalQuantity   = sum(remainingQuantity) across all batches with remainingQuantity > 0
//   latestCostPrice = costPrice of the batch with the most recent timestamp

// CapitalBatch
- id
- productId (FK -> Product)
- quantityAdded       // original amount added, for history
- remainingQuantity   // mutable: decreases as sales consume it (FIFO); 
                       // also directly editable to fix a wrong entry
- costPrice           // editable — fixing this only affects this batch going forward
- source (enum: manual | scannedReceipt)
- timestamp

// Sale
- id
- productId (FK -> Product)
- quantitySold (double)
- sellPrice (double, per kg)
- timestamp

// SaleAllocation
- id
- saleId (FK -> Sale)
- batchId (FK -> CapitalBatch)
- quantityConsumed
- costPriceAtConsumption  // snapshot at time of sale — batch price edits never touch this
```

**FIFO consumption**: when a sale is recorded, it draws from the oldest batch(es) with remaining quantity first (e.g. selling 3kg draws 2kg from an older ₱150 batch and 1kg from a newer ₱160 batch), creating one `SaleAllocation` row per batch drawn from.

## Suggested folder structure

```
lib/
  models/          Product, Sale, CapitalEntry
  db/              drift database + DAOs
  providers/       riverpod providers (inventory, sales, dashboard stats)
  screens/
    inventory/
    sell/
    dashboard/
    cost_table/
    receipt_scan/
  widgets/         shared UI components (product card, stat tile, etc.)
  theme/           lavender color scheme + typography
```

## Screens to build
1. **Inventory** — list of products, each row collapsed showing total quantity and latest cost price (e.g. "3kg — ₱160 latest"). Tapping a row expands a dropdown listing each capital batch individually (e.g. "2kg @ ₱150 — Aug 12", "1kg @ ₱160 — Sep 3"), each with an edit (pencil) affordance to correct that batch's `remainingQuantity` or `costPrice`. Editing a batch only affects that batch and any future sales drawing from it — it never rewrites `costPriceAtConsumption` on already-recorded sales.
2. **Sell** — pick product → enter quantity → auto-filled (editable) sell price → confirm → decrements stock + logs sale.
3. **Dashboard** — Total Capital, Total Sold, Profit, optional chart.
4. **Cost Price Table** — sortable table of all products' cost prices.
5. **Receipt Scan** — camera/gallery picker → OCR → editable review/confirm screen → commits to capital only after confirmation.

## Key implementation rules
- All quantity changes (sell, restock) must be wrapped in DB transactions — never allow a half-completed update (e.g., stock decremented but sale not logged).
- Never auto-commit OCR results directly to the database — always route through the manual confirm/edit review screen.
- Profit must use the cost price *snapshotted at time of sale* (`costPriceAtConsumption` on `SaleAllocation`), not the current live cost price of a batch or product.
- Editing a `CapitalBatch`'s `remainingQuantity` or `costPrice` must never modify existing `Sale` or `SaleAllocation` rows — those are historical and immutable.
- No network calls required anywhere in the app; it must function with the device offline at all times.
