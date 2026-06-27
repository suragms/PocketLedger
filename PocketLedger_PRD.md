HEXASTACK SOLUTIONS

Product Requirements Document

PocketLedger

Income & Expense Tracker — Mobile Application

“Track your daily income and expenses.”


| Prepared By | Surag (Surag Sunil / Surag M S) |
| --- | --- |
| Organization | HexaStack Solutions |
| Document Type | Product Requirements Document (PRD) |
| Platform | Mobile Application (Android & iOS) |
| Technology Stack | Flutter (Dart) |
| Version | 1.0 |
| Date | June 27, 2026 |
| Status | Draft for Development |
| Website | https://www.hexastacksolutions.com |


© Copyright Notice

This document and the product it describes are developed by Surag. All rights reserved. This work may not be copied, redistributed, or used without permission.


# Table of Contents


# 1. Document Control


## 1.1 Revision History


| Version | Date | Author | Description |
| --- | --- | --- | --- |
| 0.1 | June 20, 2026 | Surag | Initial draft — scope and feature list |
| 1.0 | June 27, 2026 | Surag | Full PRD — finalized for development handoff |



## 1.2 Distribution

This document is intended for the founding/development team at HexaStack AI Solutions, freelance collaborators, and any contracted Flutter developers engaged on this build. It serves as the single source of truth for scope, behavior, and acceptance criteria for the application described herein.


## 1.3 Document Purpose

This PRD defines the complete product scope, functional and non-functional requirements, information architecture, data model, and release plan for a mobile-first personal finance tracking application built in Flutter. It is written to be detailed enough to hand directly to a development team (or to an AI coding assistant such as Cursor) with minimal additional clarification.


# 2. Executive Summary


## 2.1 Product Vision

PocketLedger is a cross-platform mobile application that helps everyday users track their daily income and expenses with minimal friction. The product's core promise — “Track your daily income and expenses” — is delivered through a fast entry flow, clear categorization, and an at-a-glance dashboard that turns raw transactions into an understandable financial picture.

The application targets individuals who currently track spending informally (notes apps, spreadsheets, memory) and want a dedicated, lightweight tool that requires under 10 seconds to log a transaction and under 5 seconds to understand their current financial position.


## 2.2 Problem Statement

- Most people do not consistently track day-to-day spending because existing tools are either too complex (full accounting apps) or too inconvenient (manual spreadsheets).
- Without a categorized view of spending, users cannot identify where money leaks each month.
- Generic note-taking is not searchable, not visual, and provides no trend or analysis over time.

## 2.3 Proposed Solution

A single-purpose Flutter mobile app with secure account-based login, a one-tap entry flow for income and expenses (each categorized), a dashboard summarizing balance and spend patterns, a searchable history, and visual reports — all wrapped in a clean, modern interface using an emerald-and-white visual identity consistent with the HexaStack design language used across other HexaStack products.


## 2.4 Goals & Success Metrics


| Goal | Success Metric | Target |
| --- | --- | --- |
| Fast transaction entry | Average time to log a transaction | Under 10 seconds |
| Daily engagement | Daily Active Users (DAU) / Monthly Active Users (MAU) | ≥ 25% DAU/MAU ratio |
| Retention | Users still active at Day 30 | ≥ 35% |
| Data trust | Crash-free transaction-save rate | ≥ 99.5% |
| Adoption of insights | Users who view Reports tab at least weekly | ≥ 40% of active users |



## 2.5 Out of Scope (v1.0)

- Bank account / card linking (Open Banking, Plaid-style aggregation)
- Multi-currency conversion with live FX rates
- Bill splitting or shared household ledgers
- Investment portfolio tracking
- Web or desktop client (mobile-only for v1.0)
These items are logged in Section 12 (Future Roadmap) for consideration in later releases.


# 3. Target Users & Personas


## 3.1 Primary Audience

Individual consumers — students, salaried professionals, freelancers, and small business owners — who want a private, personal tool to record and understand daily cash flow without the overhead of full accounting software.


## 3.2 Persona 1: The Budget-Conscious Professional

- Profile: Age 24–35, salaried, smartphone-first, has tried and abandoned 1–2 finance apps before.
- Need: Wants to know “where did my salary go” by the 20th of the month.
- Behavior: Will log expenses on the go (auto/cab fare, food, groceries) but only if entry takes a few seconds.

## 3.3 Persona 2: The Freelancer / Small Business Owner

- Profile: Irregular income from multiple clients/sources, needs to separate income streams from personal spending.
- Need: Wants category-level breakdowns to understand business vs. personal spend and to estimate monthly net position.
- Behavior: Logs income in lump sums; logs expenses more frequently; checks reports weekly.

## 3.4 Persona 3: The Student

- Profile: Limited, irregular income (allowance, part-time work, scholarship).
- Need: Wants to avoid running out of money before month-end; needs simple visual feedback, not spreadsheets.
- Behavior: Price-sensitive, expects the app to be free or low-cost; cares about a clean, modern UI.

# 4. Scope & Feature Overview


## 4.1 Core Modules (v1.0)


| # | Module | Summary |
| --- | --- | --- |
| 1 | Authentication | Registration and Login (email/password, with optional biometric unlock after first login) |
| 2 | Dashboard | Total balance, income vs. expense overview, and spend analysis at a glance |
| 3 | Add Transaction | Floating action (+) entry point for both Income and Expense, with category selection for expenses |
| 4 | History | Chronological, filterable, searchable list of all transactions |
| 5 | Reports | Visual breakdowns — category-wise pie charts, monthly trend line/bar charts, income vs. expense comparisons |
| 6 | Settings | Profile, currency, categories management, security, notifications, data export, and app preferences |



## 4.2 Feature-to-Requirement Traceability

Each module above is expanded into detailed functional requirements in Section 6. Section 7 maps each screen to its corresponding wireframe-level UI description, and Section 9 defines the data entities that support these modules.


# 5. Assumptions, Constraints & Dependencies


## 5.1 Assumptions

- Users have a smartphone running Android 8.0 (API 26) or higher, or iOS 13 or higher.
- Users have intermittent or no internet connectivity at the moment of transaction entry; the app must function fully offline for core logging.
- A single default currency (e.g., INR) is configured per account, sufficient for v1.0 (multi-currency is future scope).

## 5.2 Constraints

- Single Flutter codebase must serve both Android and iOS from one source tree.
- App must remain lightweight; initial APK/IPA size target is under 35 MB.
- No paid third-party SDKs in v1.0 unless explicitly approved (cost-conscious indie launch).

## 5.3 Dependencies

- Backend/auth provider decision (see Section 8.4) must be finalized before development begins, as it affects the data layer architecture.
- App store developer accounts (Google Play Console, Apple Developer Program) must be active before submission milestones.

# 6. Functional Requirements

Each module is broken into User Stories and Functional Requirements (FR), numbered for traceability (e.g., FR-AUTH-01). Acceptance criteria are stated inline where behavior could otherwise be ambiguous.


## 6.1 Module 1 — Registration & Login


### 6.1.1 User Stories

- As a new user, I want to create an account using my email and a password so that my financial data is private and tied to me.
- As a returning user, I want to log in quickly, ideally with biometrics, so that I don't have to type a password every time.
- As a user, I want to reset my password if I forget it so that I am not permanently locked out.

### 6.1.2 Functional Requirements


| ID | Requirement | Detail |
| --- | --- | --- |
| FR-AUTH-01 | Registration form | Fields: Full Name, Email, Password, Confirm Password. Inline validation on blur. Password strength indicator (Weak/Medium/Strong). |
| FR-AUTH-02 | Email verification | On successful registration, send a verification email (or OTP). Account is created in an unverified state until confirmed; unverified users see a banner prompting verification but can still use the app. |
| FR-AUTH-03 | Login form | Fields: Email, Password. “Remember Me” toggle persists session token. |
| FR-AUTH-04 | Forgot password | “Forgot Password?” link triggers a reset-link/OTP email flow. New password must meet the same strength rules as registration. |
| FR-AUTH-05 | Biometric unlock | After first successful login, prompt user to enable Face ID / Fingerprint unlock for subsequent app opens (device-local, does not replace backend auth token). |
| FR-AUTH-06 | Session persistence | Auth token persisted securely (Flutter Secure Storage). Session remains valid until explicit logout or token expiry (default 30 days). |
| FR-AUTH-07 | Logout | Available from Settings. Clears local session token; local transaction cache remains encrypted on-device unless user selects “Delete local data.” |
| FR-AUTH-08 | Input validation | Email format validation (RFC 5322 pattern). Password minimum 8 characters, at least 1 number and 1 letter. Real-time error messaging below each field. |
| FR-AUTH-09 | Social sign-in (optional, phase 1.1) | Google Sign-In and Apple Sign-In as alternate registration/login paths. Flagged as fast-follow, not blocking v1.0 launch. |



### 6.1.3 Acceptance Criteria

- Given valid registration details, when the user submits the form, then an account is created and the user is navigated to the Dashboard (empty state).
- Given an incorrect password on login, when the user submits, then an inline error “Incorrect email or password” is shown without specifying which field is wrong (security best practice).
- Given biometric unlock is enabled, when the user reopens the app within the session validity window, then biometric prompt appears before Dashboard is shown.

## 6.2 Module 2 — Dashboard


### 6.2.1 User Stories

- As a user, I want to see my total balance the moment I open the app so I instantly know my financial standing.
- As a user, I want a quick visual breakdown of income vs. expense for the current month so I can gauge if I'm overspending.
- As a user, I want to see my top spending categories so I know where to cut back.

### 6.2.2 Functional Requirements


| ID | Requirement | Detail |
| --- | --- | --- |
| FR-DASH-01 | Balance summary card | Prominent card at top showing: Total Balance (Income − Expense, all-time or current period per toggle), with Total Income and Total Expense as sub-values, color-coded (emerald for income, red for expense). |
| FR-DASH-02 | Period selector | Toggle/segmented control: Today / This Week / This Month / Custom Range. Default: This Month. |
| FR-DASH-03 | Spend analysis chart | Donut/pie chart showing expense breakdown by category for the selected period, with a legend listing category, amount, and percentage of total. |
| FR-DASH-04 | Income vs. expense trend | Compact bar or line chart showing daily/weekly net flow across the selected period. |
| FR-DASH-05 | Recent transactions preview | List of the 5 most recent transactions with a “See All” link to History. |
| FR-DASH-06 | Top categories widget | Top 3–5 expense categories ranked by amount spent in the selected period, each with an icon, name, and amount. |
| FR-DASH-07 | Empty state | First-time users with zero transactions see an illustrated empty state with a clear call-to-action: “Add your first transaction.” |
| FR-DASH-08 | Pull-to-refresh | Dashboard supports pull-to-refresh to re-sync data (relevant once cloud sync is enabled). |
| FR-DASH-09 | Budget alert (optional, phase 1.1) | If a monthly budget is set (Settings), display a progress bar showing percentage of budget consumed; turns amber at 80%, red at 100%+. |



## 6.3 Module 3 — Add Income / Add Expense (FAB Entry)


### 6.3.1 User Stories

- As a user, I want a single, obvious (+) button always available so that adding a transaction is never more than two taps away.
- As a user, when I log an expense, I want to pick a category so my reports stay meaningful.
- As a user, I want to optionally attach a note or receipt photo to a transaction for my own reference.

### 6.3.2 Interaction Flow

- User taps the central Floating Action Button (FAB) visible on Dashboard and History screens.
- A bottom sheet (or two-tab modal) presents two clear entry points: “+ Income” and “− Expense,” visually distinguished by color (emerald for income, red/coral for expense).
- Selecting either opens the corresponding entry form.

### 6.3.3 Functional Requirements


| ID | Requirement | Detail |
| --- | --- | --- |
| FR-ADD-01 | FAB visibility | FAB is persistent and accessible from Dashboard and History tabs (per FR-NAV-01 in Section 7). Does not obstruct content; uses standard Material/iOS FAB elevation and shadow. |
| FR-ADD-02 | Income entry fields | Amount (numeric keypad, required), Source/Category (e.g., Salary, Freelance, Gift, Investment, Other — selectable, optional free-text “Other”), Date (defaults to today, editable via date picker), Note (optional, max 140 chars), Account/Wallet (optional, default “Cash”). |
| FR-ADD-03 | Expense entry fields | Amount (numeric keypad, required), Category (required — see FR-ADD-05 for default list), Date (defaults to today, editable), Note (optional, max 140 chars), Payment Method (Cash / Card / UPI / Bank Transfer — optional), Attach Receipt (optional, camera or gallery image). |
| FR-ADD-04 | Mandatory category for expense | Expense cannot be saved without a category selected. Income category is recommended but not strictly mandatory (defaults to “Other Income” if skipped). |
| FR-ADD-05 | Default expense categories | Food & Dining, Groceries, Transport, Shopping, Bills & Utilities, Rent/Housing, Health & Medical, Entertainment, Education, Travel, Personal Care, Other. |
| FR-ADD-06 | Default income categories | Salary, Freelance/Business, Gift, Investment Returns, Refund, Other Income. |
| FR-ADD-07 | Custom categories | User can add a custom category with a name, icon (from an icon picker), and color, managed via Settings → Categories (FR-SET-04). |
| FR-ADD-08 | Amount input validation | Numeric only, supports decimals per locale, max value sanity cap (e.g., 999,999,999), cannot be zero or negative. |
| FR-ADD-09 | Quick-save vs. detailed entry | A prominent “Save” button is available immediately after Amount + Category are filled; all other fields are optional and collapsible/expandable to keep the default flow fast. |
| FR-ADD-10 | Recurring transaction (optional, phase 1.1) | Toggle to mark a transaction as recurring (Daily/Weekly/Monthly) which auto-creates future entries. |
| FR-ADD-11 | Edit & delete | Any transaction can be edited or deleted from History or its detail view; deletions require a confirmation dialog. |
| FR-ADD-12 | Post-save feedback | On save, show a brief success toast/snackbar (“Expense added” / “Income added”) and return to the previous screen with the new transaction visible at the top of relevant lists. |


Design intent: the add-flow target is ‘amount + category + save’ in under 10 seconds for a returning user. All other fields exist for power users but must never block the fast path.


## 6.4 Module 4 — History


### 6.4.1 User Stories

- As a user, I want to see every transaction I've logged, most recent first, so I can review my activity.
- As a user, I want to filter and search transactions by category, type, or date range so I can find specific entries quickly.
- As a user, I want transactions grouped by day with daily subtotals so I can see spending rhythm.

### 6.4.2 Functional Requirements


| ID | Requirement | Detail |
| --- | --- | --- |
| FR-HIST-01 | Chronological list | Transactions grouped under date headers (Today, Yesterday, then full dates), sorted newest first by default. |
| FR-HIST-02 | Daily subtotal | Each date group header displays the net total (income − expense) for that day. |
| FR-HIST-03 | Transaction row content | Icon (category icon), category name, optional note preview, amount (color-coded: emerald + sign for income, red − sign for expense), payment method icon if set. |
| FR-HIST-04 | Search | Search bar filters by note text and category name in real time (debounced). |
| FR-HIST-05 | Filter panel | Filter by: Type (All/Income/Expense), Category (multi-select), Date Range (preset: 7/30/90 days, This Month, Custom), Amount Range (optional). |
| FR-HIST-06 | Tap-to-detail | Tapping a row opens a detail view with full transaction info and Edit/Delete actions. |
| FR-HIST-07 | Swipe actions | Swipe-left reveals Edit and Delete shortcuts (standard mobile list pattern) as an alternative to opening detail view. |
| FR-HIST-08 | Infinite scroll / pagination | List loads incrementally (e.g., 30 transactions per page) to maintain performance for users with large histories. |
| FR-HIST-09 | Empty filtered state | If filters return zero results, show “No transactions match your filters” with a “Clear filters” action. |



## 6.5 Module 5 — Reports


### 6.5.1 User Stories

- As a user, I want monthly and yearly summaries so I can understand my financial trends over time.
- As a user, I want to compare income vs. expense over several months to see if I'm improving.
- As a user, I want to export my data so I can back it up or analyze it elsewhere.

### 6.5.2 Functional Requirements


| ID | Requirement | Detail |
| --- | --- | --- |
| FR-REP-01 | Period selector | Weekly / Monthly / Yearly / Custom range tabs at the top of the Reports screen. |
| FR-REP-02 | Category breakdown chart | Donut chart of expense-by-category for the selected period with tap-to-drill-down into a filtered History view for that category. |
| FR-REP-03 | Income vs. expense trend chart | Multi-series bar or line chart comparing income and expense across consecutive periods (e.g., last 6 months). |
| FR-REP-04 | Top spending categories list | Ranked list with amount and percentage share, beyond what's shown on Dashboard (full list, not capped at 3–5). |
| FR-REP-05 | Net savings indicator | Net savings (income − expense) for the period with a comparison delta vs. the previous period (e.g., “+12% vs. last month”). |
| FR-REP-06 | Export data | Export filtered or full transaction data as CSV and/or PDF summary report, shareable via the device's native share sheet. |
| FR-REP-07 | Category-vs-budget comparison (optional, phase 1.1) | If budgets are configured per category, show actual vs. budgeted spend per category. |



## 6.6 Module 6 — Settings


### 6.6.1 User Stories

- As a user, I want to manage my profile, currency, and categories so the app fits how I actually track money.
- As a user, I want to secure the app with biometrics/PIN so my financial data stays private even if someone picks up my phone.
- As a user, I want to back up or export my data so I don't lose it if I change phones.

### 6.6.2 Functional Requirements


| ID | Requirement | Detail |
| --- | --- | --- |
| FR-SET-01 | Profile management | Edit Name, Email (with re-verification if changed), Profile Photo (optional), Change Password. |
| FR-SET-02 | Currency selection | Select default currency from a standard list (INR, USD, AED, EUR, GBP, etc.) with correct symbol and formatting applied app-wide. |
| FR-SET-03 | Theme | Light / Dark / System default toggle, using the emerald-and-white brand palette in both modes (dark mode uses deep slate background with emerald accents). |
| FR-SET-04 | Category management | View, add, edit, reorder, and (soft) delete custom categories; default categories can be hidden but not hard-deleted to preserve historical transaction integrity. |
| FR-SET-05 | Budget settings (optional, phase 1.1) | Set an overall monthly budget and/or per-category monthly budgets, feeding FR-DASH-09 and FR-REP-07. |
| FR-SET-06 | App lock / security | Enable/disable biometric unlock; optional 4–6 digit PIN fallback; auto-lock after configurable inactivity period (Immediately / 1 min / 5 min / Never). |
| FR-SET-07 | Notifications | Toggle daily reminder to log expenses (configurable time), toggle weekly/monthly summary notification, toggle budget-threshold alerts. |
| FR-SET-08 | Data export & backup | Export all data (CSV/PDF, per FR-REP-06) and, if cloud sync is enabled, manual “Back up now” / “Restore” actions. |
| FR-SET-09 | Account deletion | Permanently delete account and all associated data, gated behind a confirmation step and password re-entry, in compliance with data protection norms. |
| FR-SET-10 | About / Legal | App version, Terms of Service, Privacy Policy, and attribution screen displaying “Developed by Surag — HexaStack Solutions” with links to the website and portfolio. |
| FR-SET-11 | Logout | Per FR-AUTH-07, accessible from the bottom of the Settings list. |



# 7. Information Architecture & Navigation


## 7.1 App Structure

The app uses a bottom navigation bar with four primary destinations and a centrally docked Floating Action Button (FAB) for transaction entry, following the requirements: Dashboard, History, (FAB for Add), Reports, Settings.


## 7.2 Bottom Navigation Map


| Position | Tab | Icon | Purpose |
| --- | --- | --- | --- |
| 1 | Dashboard | Home / grid icon | Default landing screen post-login. Balance overview and spend analysis. |
| 2 | History | Clock / list icon | Full transaction log with search and filters. |
| 3 | (FAB) | + icon, docked center, elevated | Opens Add Income / Add Expense bottom sheet. |
| 4 | Reports | Bar-chart icon | Visual analysis and trends. |
| 5 | Settings | Gear icon | Profile, preferences, security, data. |



## 7.3 Screen Inventory


| Screen | Entry Point | Key Components |
| --- | --- | --- |
| Splash | App launch | Logo, brand color background, auto-navigates to Login/Dashboard based on session |
| Onboarding (3 slides) | First app open only | Illustrated intro to core value prop, skippable |
| Registration | From Login / Splash | Form per FR-AUTH-01 |
| Login | From Splash / Logout | Form per FR-AUTH-03, biometric prompt per FR-AUTH-05 |
| Forgot Password | From Login | Email/OTP flow per FR-AUTH-04 |
| Dashboard | Bottom nav (default tab) | Balance card, period selector, charts, recent transactions |
| Add Income / Add Expense | FAB (any tab) | Bottom sheet → full-screen form per Section 6.3 |
| History | Bottom nav | Grouped list, search bar, filter sheet |
| Transaction Detail | Tap a row in History/Dashboard | Full fields, Edit/Delete actions |
| Reports | Bottom nav | Period tabs, charts, export action |
| Settings | Bottom nav | Sectioned list per Section 6.6 |
| Profile Edit | Settings → Profile | Name, email, photo, password change |
| Category Manager | Settings → Categories | Add/edit/reorder categories |
| About / Legal | Settings → About | Version, ToS, Privacy, attribution |



## 7.4 Navigation Rules

- The FAB is visually distinct (filled emerald circle, white + icon, drop shadow) and remains in a fixed position across Dashboard, History, and Reports.
- Back navigation from any add/edit/detail screen returns to the screen the user came from, preserving scroll position and active filters.
- Deep-linking (e.g., from a notification) into a specific transaction or the Add flow is supported in phase 1.1.

# 8. UX & Visual Design Guidelines


## 8.1 Design Principles

- Speed over completeness: the default path for any action favors the fewest taps; advanced options are progressively disclosed.
- Color carries meaning: emerald green is reserved for income/positive values and primary actions; red/coral is reserved for expenses/destructive actions. Color is never used decoratively in a way that conflicts with this convention.
- Legible at a glance: numbers are the hero of every screen — large, high-contrast, tabular-aligned figures so totals can be read in under a second.

## 8.2 Visual Identity


| Token | Value | Usage |
| --- | --- | --- |
| Primary (Emerald) | #0E9F6E | Primary buttons, FAB, income values, active nav state, links |
| Primary Dark | #065F46 | Headers, emphasis text on light backgrounds, pressed states |
| Primary Light | #D1FAE5 | Card backgrounds, chips, success banners |
| Expense / Alert | #DC2626 | Expense values, delete actions, over-budget warnings |
| Ink (Text) | #1F2937 | Primary text |
| Slate (Secondary Text) | #4B5563 | Secondary/help text, captions |
| Surface | #FFFFFF | Card and screen backgrounds (light mode) |
| Background Grey | #F3F4F6 | App background behind cards (light mode) |



## 8.3 Typography

- Primary typeface: Inter or Poppins (geometric, highly legible at small sizes on mobile).
- Numeric figures use tabular/monospaced figure variants where the font supports it, so amounts align cleanly in lists.
- Type scale: Display 32/28 (balance figures), Heading 20/18, Body 15/14, Caption 12.

## 8.4 Component Patterns

- Cards: 16px corner radius, subtle elevation (2dp), 16px internal padding, used for the balance summary, chart containers, and grouped settings sections.
- FAB: 56dp diameter, emerald fill, white plus icon, elevated 6dp, expands into a two-option bottom sheet (Income / Expense) on tap.
- Charts: donut charts for category composition; bar/line charts for trends over time; consistent color mapping per category persists across Dashboard, History, and Reports.
- Empty states: friendly illustration + one-line message + single clear call-to-action button.

## 8.5 Accessibility

- Minimum touch target size of 44x44dp for all interactive elements.
- Color is never the only signal — income/expense also use +/− prefixes and distinct icons, supporting color-blind users.
- Text contrast meets WCAG AA (4.5:1 minimum) in both light and dark themes.
- All interactive elements expose semantic labels for screen readers (TalkBack / VoiceOver).

# 9. Data Model

The schema below is designed to work both as a local-first (on-device) store and, when backend sync is enabled, as the canonical cloud schema. Field names are illustrative and may be adapted to the final ORM/backend choice.


## 9.1 Entity: User


| Field | Type | Notes |
| --- | --- | --- |
| id | UUID | Primary key |
| full_name | String | Required |
| email | String | Required, unique, used for login |
| password_hash | String | Never stored or transmitted in plaintext; hashed server-side |
| currency_code | String (ISO 4217) | Default account currency, e.g., “INR” |
| theme_preference | Enum | light / dark / system |
| biometric_enabled | Boolean | Device-local flag |
| email_verified | Boolean | Defaults to false until verification flow completes |
| created_at / updated_at | Timestamp | Audit fields |



## 9.2 Entity: Transaction


| Field | Type | Notes |
| --- | --- | --- |
| id | UUID | Primary key |
| user_id | UUID (FK) | References User |
| type | Enum | income / expense |
| amount | Decimal | Stored as minor units (e.g., paise) to avoid floating-point errors |
| category_id | UUID (FK) | References Category; required for type = expense |
| account_id | UUID (FK), nullable | References Account/Wallet; defaults to “Cash” |
| payment_method | Enum, nullable | cash / card / upi / bank_transfer |
| note | String, nullable | Max 140 characters |
| receipt_url | String, nullable | Local file path or cloud storage URL for attached receipt image |
| transaction_date | Date | Defaults to entry date; user-editable |
| is_recurring | Boolean | Phase 1.1 |
| recurrence_rule | String, nullable | Phase 1.1 (e.g., RRULE-style string) |
| created_at / updated_at | Timestamp | Audit fields |



## 9.3 Entity: Category


| Field | Type | Notes |
| --- | --- | --- |
| id | UUID | Primary key |
| user_id | UUID (FK), nullable | Null for system default categories; set for user-created custom categories |
| name | String | Required, unique per user |
| type | Enum | income / expense |
| icon | String | Icon identifier from the in-app icon set |
| color_hex | String | Used consistently across Dashboard, History, Reports charts |
| is_default | Boolean | True for the 12 system expense + 6 system income categories |
| is_archived | Boolean | Soft-delete flag; archived categories are hidden from picker but preserved on historical transactions |
| sort_order | Integer | User-defined display order |



## 9.4 Entity: Account / Wallet (optional grouping)


| Field | Type | Notes |
| --- | --- | --- |
| id | UUID | Primary key |
| user_id | UUID (FK) | References User |
| name | String | e.g., “Cash,” “Bank — HDFC,” “Wallet — Paytm” |
| initial_balance | Decimal | Optional starting balance set at account creation |



## 9.5 Entity: Budget (phase 1.1)


| Field | Type | Notes |
| --- | --- | --- |
| id | UUID | Primary key |
| user_id | UUID (FK) | References User |
| category_id | UUID (FK), nullable | Null = overall monthly budget; set = per-category budget |
| amount | Decimal | Monthly budget ceiling |
| period | Enum | monthly (initial scope; weekly/yearly future) |



## 9.6 Relationships Summary

- User 1—N Transaction
- User 1—N Category (custom categories only; default categories are global/system-owned)
- Category 1—N Transaction
- User 1—N Account; Account 1—N Transaction (optional FK)
- User 1—N Budget; Budget N—1 Category (optional FK)

# 10. Technical Architecture


## 10.1 Technology Stack


| Layer | Choice | Rationale |
| --- | --- | --- |
| Framework | Flutter (Dart), single codebase | Cross-platform Android + iOS delivery from one codebase; matches the specified stack requirement |
| State Management | Riverpod (or Bloc, team preference) | Predictable, testable state management; Riverpod aligns with prior HexaStack Flutter work (MoneyFlow AI) |
| Local Database | Drift (SQLite) or Hive | Enables full offline-first transaction logging and fast local queries for charts; Drift preferred for relational queries (joins between Transaction and Category) |
| Charts | fl_chart or syncfusion_flutter_charts | Donut and bar/line chart support for Dashboard and Reports |
| Secure Storage | flutter_secure_storage | Auth token and biometric flag storage |
| Biometrics | local_auth | Face ID / Fingerprint integration |
| Backend (recommended) | Firebase (Auth + Firestore) or a custom REST API (Node.js/NestJS or ASP.NET Core, per HexaStack's existing backend stack) | Firebase accelerates v1.0 timeline; a custom backend gives long-term control consistent with HexaTrack's ASP.NET Core precedent. Final choice recorded in Section 10.4. |
| Notifications | firebase_messaging or flutter_local_notifications | Daily reminders, summary alerts, budget threshold alerts |
| CI/CD | GitHub Actions → Fastlane (or Codemagic) | Automated build, test, and store deployment pipeline, consistent with HexaStack's existing GitHub Actions usage |



## 10.2 High-Level Architecture

The application follows a layered, offline-first architecture:

- Presentation Layer: Flutter widgets organized by feature module (auth, dashboard, transactions, history, reports, settings), following a feature-first folder structure.
- State/Domain Layer: Riverpod providers (or Bloc) expose use-case-level operations (e.g., addTransaction, getMonthlySummary) and hold UI state, decoupled from data source details.
- Data Layer: Repository pattern abstracts local (SQLite/Hive) and remote (REST/Firestore) data sources. All writes go to local storage first (instant UI feedback), then queue for background sync to remote storage when connectivity is available.
- Sync Layer: A lightweight sync queue tracks pending local changes (created/updated/deleted records) and reconciles with the backend using a last-write-wins or timestamp-based conflict resolution strategy for v1.0.

## 10.3 Offline-First Behavior

- All core actions (add/edit/delete transaction, view dashboard, view history, view reports) function fully without network connectivity, reading and writing to local SQLite.
- A subtle sync status indicator (e.g., a small cloud icon with check/pending/error states) is shown in Settings or the app bar to communicate sync health without being intrusive.
- Conflict resolution for v1.0: last-write-wins based on updated_at timestamp; flagged for revisit if multi-device usage proves significant.

## 10.4 Backend Decision Record

To be finalized before development sprint 1 begins. Two viable paths are recorded here for decision: (A) Firebase Auth + Firestore for fastest time-to-market with built-in scaling and minimal backend code; or (B) a custom REST API (ASP.NET Core or NestJS) paired with PostgreSQL, consistent with the backend stack already used in HexaTrack, giving HexaStack full schema and infrastructure control. The recommendation is to default to Option A for the v1.0 launch timeline in Section 11, with a migration path to Option B if/when the user base and feature set (e.g., bank-linking, multi-tenant business accounts) justify the investment.


## 10.5 Security Requirements

- All network traffic over HTTPS/TLS 1.2+.
- Passwords hashed using bcrypt or Argon2 server-side; never logged or stored in plaintext anywhere in the stack.
- Auth tokens stored only in flutter_secure_storage (Keychain on iOS, Keystore-backed encrypted storage on Android), never in plain SharedPreferences.
- Local database encrypted at rest where supported (e.g., SQLCipher) given the sensitivity of financial data.
- Rate limiting on login and password-reset endpoints to mitigate brute-force attempts (backend responsibility).

# 11. Non-Functional Requirements


| Category | Requirement |
| --- | --- |
| Performance | App cold start under 2.5 seconds on a mid-range device (e.g., 4GB RAM, 2020-era chipset). Transaction save completes and reflects in UI in under 300ms (local-first write). |
| Scalability | Local database performs smoothly with 50,000+ transaction records without UI jank (target: <16ms frame budget maintained during scrolling). |
| Reliability | Crash-free session rate ≥ 99.5% post-launch, monitored via crash reporting (e.g., Firebase Crashlytics). |
| Availability | Core logging functionality (add/edit/view transactions) has 100% availability regardless of backend uptime, by design of the offline-first architecture. |
| Usability | A first-time user can complete registration and log their first transaction within 90 seconds without external guidance (validated via usability testing pre-launch). |
| Compatibility | Android 8.0+ (API 26+) and iOS 13+. Responsive layout for phone screen sizes from 5.0″ to 6.9″ and basic tablet support (no tablet-optimized layout required for v1.0). |
| Localization | All user-facing strings externalized via Flutter's intl/ARB files from day one, even if only English (and optionally Malayalam/Hindi) ship in v1.0, to ease future localization. |
| Maintainability | Codebase follows a feature-first folder structure with documented architecture decisions (per Section 10) to support handoff between developers. |
| Privacy & Compliance | Privacy Policy and Terms of Service published and linked in-app (Settings → About) prior to public store submission; data collection limited to what is functionally necessary. |



# 12. Release Plan & Milestones


## 12.1 Phased Delivery


| Phase | Scope | Indicative Duration |
| --- | --- | --- |
| Phase 0 — Foundation | Project setup, design system in Flutter (theme, components), backend decision finalized (Section 10.4), data model implemented locally | 1–2 weeks |
| Phase 1 — Core MVP | Auth (Module 1), Add Transaction (Module 3), History (Module 4), basic Dashboard (Module 2) — offline-first, single currency | 3–4 weeks |
| Phase 2 — Insights | Full Dashboard charts, Reports module (Module 5), CSV/PDF export | 2–3 weeks |
| Phase 3 — Polish & Settings | Full Settings module (Module 6), notifications, biometric lock, dark mode, empty/error states polish | 2 weeks |
| Phase 4 — QA & Store Readiness | Cross-device testing, performance profiling, store listing assets, privacy policy, beta rollout (TestFlight / Play Internal Testing) | 1–2 weeks |
| Phase 5 — Launch | Public release on Google Play and Apple App Store | — |



## 12.2 Definition of Done (per feature)

- Matches the functional requirement and acceptance criteria defined in Section 6.
- Works correctly offline and syncs correctly once connectivity is restored (where applicable).
- Passes manual QA on at least one Android and one iOS physical device or high-fidelity simulator.
- No critical or high-severity accessibility violations (per Section 8.5).
- Analytics events (where defined) fire correctly for the feature.

# 13. Analytics & Measurement

To validate the goals defined in Section 2.4, the following events should be instrumented (tooling choice — e.g., Firebase Analytics — to be confirmed with the backend decision in Section 10.4):


| Event | Trigger | Maps to Goal |
| --- | --- | --- |
| sign_up_completed | Registration success | Adoption baseline |
| login_success | Successful login | Engagement baseline |
| transaction_added | Income or expense saved | Fast entry / core usage |
| dashboard_viewed | Dashboard screen opened | DAU/MAU |
| reports_viewed | Reports screen opened | Insight adoption (Goal: ≥ 40% weekly) |
| export_data | CSV/PDF export triggered | Data trust / power-user behavior |
| budget_set | Budget created/edited (phase 1.1) | Feature adoption |



# 14. Risks & Open Questions


## 14.1 Risks


| Risk | Impact | Mitigation |
| --- | --- | --- |
| Users abandon entry habit after a few days (common in finance-tracking apps) | High — directly threatens retention goal (Section 2.4) | Keep the add-flow under 10 seconds (FR-ADD-09); add gentle daily reminder notifications (FR-SET-07); make Dashboard rewarding to revisit |
| Offline-to-online sync conflicts corrupt data | Medium — trust-breaking if it occurs | Last-write-wins strategy for v1.0 (Section 10.3) with clear sync-status UI; revisit with operational transforms if multi-device usage grows |
| Backend choice (Firebase vs. custom) delays Phase 0 | Medium — blocks downstream development | Default recommendation given in Section 10.4 with a clear migration path to avoid analysis paralysis |
| Scope creep from phase-1.1 features (budgets, recurring transactions, social login) bleeding into v1.0 | Medium — delays launch | All phase-1.1 items explicitly tagged throughout this document and excluded from the Phase 1–4 release plan (Section 12.1) |



## 14.2 Open Questions

- Should the app support multiple accounts/wallets (e.g., Cash, Bank, UPI) in v1.0, or is a single default account sufficient for launch? (Section 9.4 models this as optional/nullable to allow either path without a schema rework.)
- Is multi-language support (Malayalam/Hindi, given HexaStack's regional presence in Kerala) a launch requirement or a fast-follow?
- Will monetization (e.g., a premium tier with advanced reports/export, or ad-supported free tier) be introduced at launch, or is v1.0 entirely free while the user base is validated?

# 15. Future Roadmap (Post v1.0)

- Bank/card account linking via Open Banking-style aggregators for automatic transaction import.
- Multi-currency support with live exchange rate conversion for users who transact across currencies.
- Shared/household ledgers allowing multiple users to log against a shared budget.
- Recurring transactions and bill reminders (elevated from phase-1.1 fast-follow to a full feature).
- Budgeting v2: rollover budgets, envelope-style budgeting, and category-level alerts.
- Investment and savings-goal tracking modules.
- Web companion dashboard for users who prefer reviewing reports on a larger screen.
- AI-assisted insights (e.g., “You spent 20% more on dining out this month”), leveraging HexaStack's existing AI engineering capability.

# 16. Appendix


## 16.1 Glossary


| Term | Definition |
| --- | --- |
| FAB | Floating Action Button — the persistent (+) button used to initiate adding a transaction. |
| DAU / MAU | Daily Active Users / Monthly Active Users — engagement ratio used as a retention proxy. |
| Offline-first | An architecture pattern where the app is fully functional without network connectivity, syncing to the backend opportunistically. |
| Category | A user- or system-defined classification applied to a transaction (e.g., “Groceries,” “Salary”) used for filtering and reporting. |
| Net Savings | Total income minus total expense for a given period. |



## 16.2 Reference Requirements (As Provided)

This PRD was developed from the following source requirements, expanded into the full specification above:

- Registration and login page
- Dashboard with total amount and spend analysis overview
- A plus (+) icon for adding income and expense
- Category selection when adding an expense
- History
- Reports
- Settings
- Technology stack: Flutter
- Platform: Mobile application
- Tagline: “Track your daily income and expenses”

# 17. Authorship, Copyright & Contact


## 17.1 Document Authorship

This Product Requirements Document was prepared by Surag on behalf of HexaStack AI Solutions.


## 17.2 Copyright Notice

© Developed by Surag. All rights to this document and the product concept described herein are reserved. This material may not be reproduced, distributed, or used to develop a competing or derivative product without explicit written permission from the author.


## 17.3 Company

HexaStack Solutions

Website:  www.hexastacksolutions.com


## 17.4 Enquiries & Collaboration

Surag is available for freelance projects, architectural consultations, and full-stack development collaborations.

Links:  linktr.ee/suragdevstudio

Portfolio:  surag-portfolio.web.app

Email:  officialsurag@gmail.com

Phone: Available on request via Instagram or LinkedIn

LinkedIn:  linkedin.com/in/suragsunil

Instagram:  instagram.com/surag_sunil

GitHub:  github.com/suragms

YouTube:  youtube.com/@suragdevstudio
