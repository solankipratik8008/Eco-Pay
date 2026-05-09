# Eco-Pay – Modular Wallet App

Eco-Pay is an iOS wallet application prototype built with Swift, Swift Package Manager, Keychain, REST APIs, and async/await. The project demonstrates a modular mobile architecture for digital wallet features such as authentication, secure credential storage, payment workflows, and transaction-related service layers.

This project was created as a portfolio-level iOS application to demonstrate clean architecture, secure mobile development practices, modular code organization, and API-driven feature design.

---

## Overview

Eco-Pay focuses on building a maintainable and scalable wallet architecture by separating major app responsibilities into independent modules. Instead of keeping all business logic inside one large app target, the project uses a modular structure so features like authentication, payments, analytics, and networking can be developed and maintained separately.

The app is designed around real-world mobile wallet concepts such as secure login, API communication, credential protection, and reusable service layers.

---

## Key Features

- Modular wallet architecture using Swift Package Manager
- Authentication module for user login-related logic
- Payment module for payment and wallet transaction workflows
- Networking layer for REST API communication
- Secure credential storage using Keychain
- async/await-based API handling
- Protocol-based service design for maintainability
- Mock API client support for testing logic without a live backend
- MVVM-style separation of UI and business logic
- Clean project structure for easier debugging and future scaling

---

## Tech Stack

### iOS Development
- Swift
- SwiftUI
- MVVM
- Swift Package Manager
- async/await

### Security & Storage
- Keychain
- Secure credential storage
- Passkey authentication concepts

### Networking
- REST APIs
- JSON
- URLSession
- Protocol-based API abstraction

### Tools
- Xcode
- Git
- GitHub

---

## Project Goals

The main goal of Eco-Pay is to demonstrate how a wallet-style iOS application can be structured in a modular and maintainable way.

This project focuses on:

- Separating app features into independent modules
- Improving code readability and maintainability
- Using secure storage for sensitive user data
- Building reusable networking and service layers
- Applying modern Swift concurrency with async/await
- Designing an architecture that can support future wallet features

---

## Suggested Project Structure

```text
EcoPay/
│
├── EcoPayApp/
│   ├── App/
│   ├── Views/
│   ├── ViewModels/
│   └── Resources/
│
├── Packages/
│   ├── AuthModule/
│   │   ├── Models/
│   │   ├── Services/
│   │   └── ViewModels/
│   │
│   ├── PaymentModule/
│   │   ├── Models/
│   │   ├── Services/
│   │   └── ViewModels/
│   │
│   ├── NetworkingModule/
│   │   ├── APIClient.swift
│   │   ├── APIEndpoint.swift
│   │   └── NetworkError.swift
│   │
│   ├── SecurityModule/
│   │   ├── KeychainService.swift
│   │   └── SecureStorage.swift
│   │
│   └── AnalyticsModule/
│       ├── AnalyticsService.swift
│       └── AnalyticsEvent.swift
│
└── README.md
