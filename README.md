# Eco-Pay

Eco-Pay is a modular iOS wallet demo app built with SwiftUI, Firebase Auth, Firestore, MVVM, Keychain, and Swift Package Manager.

The app demonstrates a real Firebase-backed wallet flow, including user registration/login, Firestore user profiles, wallet balances, user-to-user demo transfers, transaction history, and stacked demo wallet cards.

▶️ **Demo Video:** [Watch Eco-Pay Demo](https://youtube.com/shorts/fqnY74EwOg0)

[![Watch the Eco-Pay demo](https://img.youtube.com/vi/fqnY74EwOg0/hqdefault.jpg)](https://youtube.com/shorts/fqnY74EwOg0)

---

## Table of Contents

- [Overview](#overview)
- [Demo Video](#demo-video)
- [Key Features](#key-features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Main App Flow](#main-app-flow)
- [Firebase Features](#firebase-features)
- [Firestore Data Structure](#firestore-data-structure)
- [Authentication Flow](#authentication-flow)
- [Wallet Flow](#wallet-flow)
- [Money Transfer Flow](#money-transfer-flow)
- [Transaction History](#transaction-history)
- [Demo Card Management](#demo-card-management)
- [Security and Privacy Notes](#security-and-privacy-notes)
- [How to Run the Project](#how-to-run-the-project)
- [Firebase Setup](#firebase-setup)
- [Required Firebase Packages](#required-firebase-packages)
- [Known Limitations](#known-limitations)
- [Future Improvements](#future-improvements)
- [Resume Highlight](#resume-highlight)
- [Author](#author)
- [Disclaimer](#disclaimer)

---

## Overview

Eco-Pay is a portfolio-level iOS wallet demo app designed to showcase practical mobile development skills with SwiftUI and Firebase.

The app started as a modular wallet concept and was upgraded with real Firebase-backed functionality. Users can register and log in with Firebase Authentication, receive a Firestore wallet with a starter balance, send demo money to another registered Eco-Pay user, view transaction history, and add safe demo card metadata.

The project focuses on:

- Clean SwiftUI interface
- MVVM architecture
- Modular Swift Package Manager structure
- Firebase Auth integration
- Firestore database integration
- Real user-to-user demo transfer logic
- Transaction history
- Safe demo card management
- Portfolio-ready GitHub presentation

---

## Demo Video

A short YouTube demo is available showing the main Eco-Pay workflow.

▶️ **Watch Demo on YouTube:** [Eco-Pay iOS Wallet App Demo](https://youtube.com/shorts/fqnY74EwOg0)

Demo flow:

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

## Key Features

### Authentication

- Firebase email/password registration
- Firebase email/password login
- Firebase logout
- Firebase session handling
- Firestore user profile creation
- Login/register UI with validation

### Wallet

- Firestore wallet creation for each registered user
- Starter demo wallet balance
- Dashboard balance loaded from Firestore
- Pull-to-refresh support
- Error handling for missing wallet/session issues

### Money Transfer

- Send demo money to another registered Eco-Pay user
- Prevent transfers to non-existing users
- Prevent sending money to yourself
- Check sender balance before transfer
- Deduct sender wallet balance
- Credit receiver wallet balance
- Create Firestore transaction records for both sender and receiver

### Transaction History

- Recent transactions shown on home dashboard
- Full History screen connected to Firestore
- Search transactions
- Filter transactions by type/status
- Grouped transaction history by date
- Transaction detail screen
- Pull-to-refresh support

### Demo Card Management

- Add demo wallet cards
- Store card metadata in Firestore
- Show stacked wallet cards on Home dashboard
- Tap a background card to bring it forward
- First card can be treated as default
- Stores only safe card metadata:
  - Card brand
  - Last four digits
  - Cardholder name
  - Expiry month/year
  - Default card flag

### Architecture

- MVVM architecture
- Service-based Firebase/Firestore logic
- Modular Swift Package Manager setup
- Reusable SwiftUI components
- Clean separation between views, view models, services, and package modules

---

## Tech Stack

| Technology | Purpose |
|---|---|
| Swift | Main programming language |
| SwiftUI | User interface |
| Firebase Auth | Email/password registration and login |
| Firestore | User profiles, wallets, transactions, and demo cards |
| FirebaseCore | Firebase app initialization |
| Keychain | Secure/session-related architecture support |
| Swift Package Manager | Modular local packages |
| MVVM | App architecture |
| Xcode | iOS development environment |

---

## Architecture

Eco-Pay follows an MVVM-style architecture with additional service layers for Firebase and Firestore operations.

```text
Eco-Pay
├── EcoPay
│   ├── App
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
