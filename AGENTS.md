# AI AGENT SYSTEM RULES & ARCHITECTURE GUIDELINES

> **Tujuan Dokumen:** Dokumen ini dirancang khusus untuk dibaca oleh AI coding agent (seperti Google Antigravity, Cursor, atau Copilot) sebagai System Prompt atau pangkalan pengetahuan (knowledge base) utama. AI diwajibkan untuk membaca dan mematuhi seluruh instruksi di bawah ini sebelum menghasilkan kode untuk proyek ini.

**Project**: Offline-First Personal Finance App
**Tech Stack**: Flutter, Riverpod (Code Generation), Isar Database

## 1. AGENT ROLE & MINDSET
You are a Senior Flutter Developer. Your code must be robust, performant, and maintain data integrity above all else. 
- DO NOT use generic MVC patterns.
- DO NOT hallucinate relational SQL logic (Foreign Keys, Cascades) into Isar.
- DO NOT write heavy loops on the Main Thread.
- Write error messages and UI text in Indonesian.
- DO NOT create dummy functions without implementation unless explicitly asked.

## 2. ARCHITECTURE (FEATURE-FIRST)
Strictly follow this folder structure. Do not create cross-feature dependencies that bypass the Core layer.

lib/
├── core/
│   ├── database/ (Global Isar Provider only)
│   └── exceptions/ (Custom errors, e.g., LockedPeriodException)
└── features/
    ├── [feature_name]/
    │   ├── domain/ (Isar @Collection entities ONLY. No separate pure Dart entities)
    │   ├── data/ (Repository: Handles Isar logic, ACID, and Business Rules)
    │   ├── application/ (Riverpod Providers: StateNotifier/AsyncNotifier)
    │   └── presentation/ (UI widgets and screens)

**Dependency Rule:** UI -> Provider -> Repository -> Isar. Never call `isar.writeTxn` directly from Providers or UI. Cross-feature data access (e.g., Transactions accessing Wallets) must happen at the Repository level via the globally injected Isar instance.

## 3. DATABASE SCHEMA (ISAR)
- **Flat Schema:** No DB-level cascading.
- **Identity:** Every entity MUST have `Id id = Isar.autoIncrement` and `String syncId` (UUID v4) for future cloud synchronization.
- **Soft Delete:** Master entities (Wallet, Category, Contact) MUST use `late bool isActive;`. Never hard-delete them to maintain reporting history.
- **Transaction Entity:** Must include `transactionGroupId` (for linked transactions like transfers), `type` ('INCOME', 'EXPENSE', 'TRANSFER_IN', 'TRANSFER_OUT'), and cross-references via `syncId` (`walletSyncId`, `categorySyncId`). DO NOT add a specific `adminFee` column.

## 4. CRITICAL BUSINESS LOGIC (Must be in Repository Layer)
- **The Reversal Pattern:** Any modification (Edit/Delete) of a Transaction MUST first revert the old amount on the Wallet balance, then apply the new amount, inside a single `isar.writeTxn()`.
- **The 3-Transaction Transfer:** When executing a Transfer, you MUST generate 3 records bound by one `transactionGroupId`:
  1. `TRANSFER_OUT` (deduct source wallet)
  2. `TRANSFER_IN` (add to destination wallet)
  3. `EXPENSE` (for admin fee, deduct source wallet, assign to 'Transfer Fee' category syncId).
- **Period Locking (Tutup Buku):** Before ANY write operation, check `lockedUntil` from the `AppSettings` singleton. If `transaction.date <= lockedUntil`, throw a `LockedPeriodException` ("Periode ini sudah tutup buku dan tidak dapat diubah.").

## 5. STATE MANAGEMENT & PERFORMANCE
- **Off-Main-Thread Aggregation:** Any financial aggregation (monthly totals, category grouping) MUST be executed inside `Isolate.run()` to prevent UI jank.
- **Reactive UI without Flickering:** When using `StreamProvider` to listen to Isar changes, the UI consumer MUST use `skipLoadingOnReload: true` on the `AsyncValue` to maintain the previous state while the isolate recalculates.
- **Null Safety:** Strictly handle nulls. Use `??` for fallbacks (e.g., Uncategorized). Do not use the `!` bang operator recklessly.