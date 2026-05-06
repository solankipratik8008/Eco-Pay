//
//  Extensions.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//

// Extensions.swift
// EcoPayApp/Utilities/Extensions.swift
//
// Utility extensions used throughout the Eco-Pay app.
// Covers currency formatting, date formatting, string validation,
// and common view modifiers. Keeps repetitive logic out of
// ViewModels and Views.

import SwiftUI

// MARK: - Decimal + Currency Formatting

extension Decimal {
    
    /// Formats a Decimal value as currency string.
    /// Example: Decimal(1234.56) → "$1,234.56"
    func asCurrency(
        code: String = AppConstants.Currency.defaultCode,
        locale: Locale = AppConstants.Currency.defaultLocale
    ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.locale = locale
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: self as NSDecimalNumber) ?? "$0.00"
    }
    
    /// Formats with a sign prefix for transaction display.
    /// Positive: "+$50.00", Negative: "-$50.00"
    func asSignedCurrency(
        code: String = AppConstants.Currency.defaultCode,
        locale: Locale = AppConstants.Currency.defaultLocale
    ) -> String {
        let formatted = abs(self).asCurrency(code: code, locale: locale)
        if self > 0 {
            return "+\(formatted)"
        } else if self < 0 {
            return "-\(formatted)"
        }
        return formatted
    }
    
    /// Returns the absolute value of a Decimal
    private func abs(_ value: Decimal) -> Decimal {
        return value < 0 ? -value : value
    }
}

// MARK: - Double + Currency Convenience

extension Double {
    
    /// Convenience to format Double as currency.
    /// Converts to Decimal first for precision.
    func asCurrency() -> String {
        return Decimal(self).asCurrency()
    }
}

// MARK: - Date + Formatting

extension Date {
    
    /// Formats date for transaction list display.
    /// Example: "Jan 15, 2025"
    func asTransactionDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = AppConstants.DateFormat.transactionDisplay
        return formatter.string(from: self)
    }
    
    /// Formats date for transaction detail screen.
    /// Example: "January 15, 2025 at 2:30 PM"
    func asTransactionDetail() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = AppConstants.DateFormat.transactionDetailDisplay
        return formatter.string(from: self)
    }
    
    /// Returns a relative description like "Today", "Yesterday", "3 days ago".
    /// Falls back to standard format for older dates.
    func asRelativeDate() -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else {
            let components = calendar.dateComponents([.day], from: self, to: Date())
            if let days = components.day, days < 7 {
                return "\(days) days ago"
            }
            return self.asTransactionDate()
        }
    }
    
    /// Creates a date offset from today by a given number of days.
    /// Useful for generating mock transaction dates.
    /// Negative values go into the past.
    static func daysAgo(_ days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }
}

// MARK: - String + Validation

extension String {
    
    /// Basic email format validation.
    /// Checks for something@something.something pattern.
    var isValidEmail: Bool {
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return self.range(of: pattern, options: .regularExpression) != nil
    }
    
    /// Checks password meets minimum requirements.
    /// At least 8 characters, 1 uppercase, 1 lowercase, 1 digit.
    var isValidPassword: Bool {
        guard self.count >= AppConstants.Validation.minPasswordLength else { return false }
        let hasUppercase = self.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = self.range(of: "[a-z]", options: .regularExpression) != nil
        let hasDigit = self.range(of: "[0-9]", options: .regularExpression) != nil
        return hasUppercase && hasLowercase && hasDigit
    }
    
    /// Masks a string showing only the last N characters.
    /// Example: "4242424242424242".masked(showLast: 4) → "•••• 4242"
    func masked(showLast count: Int = 4) -> String {
        guard self.count > count else { return self }
        let visible = String(self.suffix(count))
        return "\u{2022}\u{2022}\u{2022}\u{2022} \(visible)"
    }
    
    /// Trims whitespace and newlines from both ends.
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Returns nil if the string is empty after trimming.
    /// Useful for optional text fields.
    var nilIfEmpty: String? {
        let cleaned = self.trimmed
        return cleaned.isEmpty ? nil : cleaned
    }
}

// MARK: - Card Expiry Formatting

extension String {
    
    /// Formats raw digits into MM/YY card expiry format.
    /// Example: "1226" → "12/26"
    var asCardExpiry: String {
        let cleaned = self.filter { $0.isNumber }
        guard cleaned.count >= 4 else { return cleaned }
        let month = String(cleaned.prefix(2))
        let year = String(cleaned.dropFirst(2).prefix(2))
        return "\(month)/\(year)"
    }
}

// MARK: - View + Conditional Modifier

extension View {
    
    /// Applies a modifier only when a condition is true.
    /// Avoids wrapping views in if/else blocks.
    ///
    /// Usage:
    /// Text("Hello")
    ///     .if(isHighlighted) { $0.foregroundColor(.yellow) }
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - View + Keyboard Dismissal

extension View {
    
    /// Adds a tap gesture that dismisses the keyboard.
    /// Useful for forms and input screens.
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }
}

// MARK: - Color + Hex Initialization

extension Color {
    
    /// Creates a Color from a hex string.
    /// Supports formats: "#RRGGBB" and "RRGGBB"
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        
        var rgbValue: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgbValue)
        
        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}
