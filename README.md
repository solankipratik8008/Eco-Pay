# Eco-Pay

Eco-Pay is a modular iOS wallet demo app built with SwiftUI, Firebase Auth, Firestore, MVVM, Keychain, and Swift Package Manager.

The app demonstrates a real Firebase-backed wallet flow, including user registration/login, Firestore user profiles, wallet balances, user-to-user demo transfers, transaction history, and stacked demo wallet cards.

▶️ Demo Video: https://youtube.com/shorts/fqnY74EwOg0

[![Watch the Eco-Pay demo](https://img.youtube.com/vi/fqnY74EwOg0/hqdefault.jpg)](https://youtube.com/shorts/fqnY74EwOg0)

---

## Features

- Firebase email/password registration and login
- Firestore user profile creation
- Firestore wallet creation with starter balance
- Dashboard balance loaded from Firestore
- Send demo money to another registered Eco-Pay user
- Prevent transfers to non-existing users
- Prevent sending money to yourself
- Sender balance deduction and receiver balance credit
- Firestore transaction records for sender and receiver
- Recent transactions on the home dashboard
- Full transaction history screen
- Search and filter transaction history
- Transaction detail screen
- Add demo cards
- Store demo card metadata in Firestore
- Stacked wallet card UI
- Tap a background card to bring it forward
- MVVM architecture
- Modular Swift Package Manager structure

---

## Tech Stack

- Swift
- SwiftUI
- Firebase Auth
- Firestore
- FirebaseCore
- Keychain
- MVVM
- Swift Package Manager
- Xcode

---

## Demo Flow

1. Open Eco-Pay
2. Register or log in with Firebase Auth
3. View Firestore-backed wallet balance
4. Send money to an existing Eco-Pay user
5. Prevent transfer to non-existing users
6. Update sender and receiver wallet balances
7. View recent transactions on the home dashboard
8. Open full transaction history
9. Add demo cards to Firestore
10. View stacked wallet cards on the home screen
11. Tap a background card to bring it forward

---

## Project Structure

```text
Eco-Pay
├── EcoPay
│   ├── Components
│   ├── Services
│   ├── Utilities
│   ├── ViewModels
│   ├── Views
│   ├── Assets
│   └── ContentView.swift
│
├── Packages
│   ├── EcoPayAnalytics
│   ├── EcoPayAuthKit
│   ├── EcoPayNetworking
│   └── EcoPayPayments
│
├── README.md
└── .gitignore

# Eco-Pay

Eco-Pay is a modular iOS wallet demo app built with SwiftUI, Firebase Auth, Firestore, MVVM, Keychain, and Swift Package Manager.

The app demonstrates a real Firebase-backed wallet flow, including user registration/login, Firestore user profiles, wallet balances, user-to-user demo transfers, transaction history, and stacked demo wallet cards.

▶️ Demo Video: https://youtube.com/shorts/fqnY74EwOg0

[![Watch the Eco-Pay demo](https://img.youtube.com/vi/fqnY74EwOg0/hqdefault.jpg)](https://youtube.com/shorts/fqnY74EwOg0)

---

## Features

- Firebase email/password registration and login
- Firestore user profile creation
- Firestore wallet creation with starter balance
- Dashboard balance loaded from Firestore
- Send demo money to another registered Eco-Pay user
- Prevent transfers to non-existing users
- Prevent sending money to yourself
- Sender balance deduction and receiver balance credit
- Firestore transaction records for sender and receiver
- Recent transactions on the home dashboard
- Full transaction history screen
- Search and filter transaction history
- Transaction detail screen
- Add demo cards
- Store demo card metadata in Firestore
- Stacked wallet card UI
- Tap a background card to bring it forward
- MVVM architecture
- Modular Swift Package Manager structure

---

## Tech Stack

- Swift
- SwiftUI
- Firebase Auth
- Firestore
- FirebaseCore
- Keychain
- MVVM
- Swift Package Manager
- Xcode

---

## Demo Flow

1. Open Eco-Pay
2. Register or log in with Firebase Auth
3. View Firestore-backed wallet balance
4. Send money to an existing Eco-Pay user
5. Prevent transfer to non-existing users
6. Update sender and receiver wallet balances
7. View recent transactions on the home dashboard
8. Open full transaction history
9. Add demo cards to Firestore
10. View stacked wallet cards on the home screen
11. Tap a background card to bring it forward

---

## Project Structure

```text
Eco-Pay
├── EcoPay
│   ├── Components
│   ├── Services
│   ├── Utilities
│   ├── ViewModels
│   ├── Views
│   ├── Assets
│   └── ContentView.swift
│
├── Packages
│   ├── EcoPayAnalytics
│   ├── EcoPayAuthKit
│   ├── EcoPayNetworking
│   └── EcoPayPayments
│
├── README.md
└── .gitignore
