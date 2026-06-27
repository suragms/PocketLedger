# PocketLedger 📱💼

A premium, cross-platform personal finance and transaction tracking application built with Flutter. Designed with an offline-first architecture, beautiful glassmorphism-inspired themes, interactive visual analytics, and bank-grade secure database locking.

---

## 🚀 Project Overview

**PocketLedger** is a high-performance offline ledger application that enables users to track daily expenditures, income, and budgets in under 10 seconds. It utilizes a local SQL engine that runs seamlessly across Mobile (Android/iOS) and Web platforms.

### Key Features
* ⚡ **Fast Log Entry**: Record transactions rapidly with category, payment methods, notes, and receipt images.
* 📊 **Interactive Analytics**: Elegant visual breakdowns using comparative bar charts and transaction distribution pie charts.
* 🔒 **Secure Auth & Biometrics**: Local secure storage authentication with native biometric (FaceID/Fingerprint) and PIN locks.
* 📦 **Data Portability**: Export complete ledgers to raw CSV files or formatted PDF reports, integrated with native system shares.
* 🔔 **Smart Reminders**: Scheduled notifications for daily log warnings, weekly summaries, and custom budget overrun alerts.

---

## 🛠️ Technical Stack

* **Frontend Framework**: [Flutter (Dart SDK 3.12+)](https://flutter.dev/)
* **State Management**: [Riverpod 2.x](https://riverpod.dev/) (with code generation)
* **Local Database**: [Drift (SQLite)](https://drift.simonbinder.eu/) (using custom FFI for Native and local WebAssembly/IndexedDB files for Web)
* **Routing**: [GoRouter 14.x](https://pub.dev/packages/go_router)
* **Local Security**: [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage) & [Local Auth (Biometrics)](https://pub.dev/packages/local_auth)
* **Visualization Charts**: [FL Chart](https://pub.dev/packages/fl_chart)
* **Alert Notifications**: [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications) & [Timezone](https://pub.dev/packages/timezone)

---

## 🏛️ Architecture & Folder Structure

The project implements **Clean Architecture** patterns separated by feature layers (Auth, Transactions, Dashboard, Reports, Settings) to ensure SOLID principles and complete testability:

```text
lib/
├── core/
│   ├── config/       # App configurations (themes, constants)
│   ├── database/     # Drift DB schemas and platform connection setups
│   ├── router/       # Router providers and redirection flow guards
│   ├── services/     # Cross-platform core services (biometrics, secure storage, sync, notifications)
│   ├── theme/        # CSS style tokens and Tailwind/Material color palettes
│   ├── utils/        # Common formatters and fields validators
│   └── widgets/      # Shell frameworks and global layouts
└── features/
    ├── auth/         # User auth domain, data, and login/registration screens
    ├── dashboard/    # Metrics widgets and visual data representation
    ├── history/      # Filterable transaction listings and list tiles
    ├── reports/      # PDF/CSV exporters and native platform shares
    └── settings/     # Categories management, biometrics toggles, and data backup
```

---

## 🏁 Getting Started & Setup Instructions

### Prerequisites
* Flutter SDK (version `3.12.2` or higher)
* Dart SDK (version `3.x` or higher)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/suragms/PocketLedger.git
   cd PocketLedger
   ```

2. **Restore dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate code (Drift databases & models)**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run tests**:
   ```bash
   flutter test
   ```

5. **Run the application**:
   * Mobile (iOS/Android):
     ```bash
     flutter run
     ```
   * Web (Local host):
     ```bash
     flutter run -d chrome
     ```

---

## ⚠️ Proprietary Notice & Copyright

This is a **paid, proprietary project** developed exclusively by **Surag**. 

* **Copyright © 2026 HexaStack Solutions / Surag Sunil / Surag M S. All Rights Reserved.**
* **Usage Restrictions**: You are **not** permitted to copy, modify, distribute, publish, sublicense, or use this application code in any capacity without the express written permission of the developer. Any unauthorized usage will be subject to appropriate legal actions.

---

## 🤝 Collaboration & Inquiries

### DM for Enquiries
I am available for **freelance projects, architectural consultations, and full-stack mobile/web development collaborations**. Feel free to reach out through any of the channels below:

* 🌐 **Linktree**: [linktr.ee/suragdevstudio](https://linktr.ee/suragdevstudio)
* 💼 **Portfolio**: [surag-portfolio.web.app](https://surag-portfolio.web.app)
* 📧 **Email**: [officialsurag@gmail.com](mailto:officialsurag@gmail.com)
* 💼 **LinkedIn**: [linkedin.com/in/suragsunil](https://linkedin.com/in/suragsunil)
* 📸 **Instagram**: [instagram.com/surag_sunil](https://instagram.com/surag_sunil)
* 💻 **GitHub**: [github.com/suragms](https://github.com/suragms)
* 📺 **YouTube**: [youtube.com/@suragdevstudio](https://youtube.com/@suragdevstudio)
