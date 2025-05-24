//
//  DataModels.swift
//  ShelfAI
//
//  Created by Krsna  on 5/25/25.
//

import Foundation
import SwiftUI

struct Book: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let authors: [String]
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let pageCount: Int?
    let categories: [String]
    let averageRating: Double?
    let openLibraryId: String?
    var isRead: Bool = false
    var isInLibrary: Bool = false
    var readingProgress: Double = 0
    var lastReadDate: Date?
    var status: BookStatus = .available
    var dueDate: Date?
    var notes: String = ""
    var userRating: Int?
    var dateAdded: Date = Date()
    
    enum BookStatus: String, Codable, CaseIterable {
        case available, checkedOut, overdue, reserved
        
        var displayName: String {
            switch self {
            case .available: return "Available"
            case .checkedOut: return "Checked Out"
            case .overdue: return "Overdue"
            case .reserved: return "Reserved"
            }
        }
        
        var color: Color {
            switch self {
            case .available: return .green
            case .checkedOut: return .blue
            case .overdue: return .red
            case .reserved: return .orange
            }
        }
    }
    
    var author: String { authors.joined(separator: ", ") }
    var genre: String { categories.first ?? "Unknown" }
    var rating: Double { averageRating ?? 0.0 }
    var userRatingOrAverage: Double { Double(userRating ?? Int(rating * 2)) / 2 }
    
    var coverImageURL: URL? {
        guard let openLibraryId = openLibraryId else { return nil }
        return URL(string: "https://covers.openlibrary.org/b/id/\(openLibraryId)-L.jpg")
    }
    
    var formattedPublishedDate: String {
        guard let publishedDate = publishedDate else { return "Unknown" }
        if let year = Int(publishedDate.prefix(4)) {
            return "\(year)"
        }
        return publishedDate
    }
    
    var daysUntilDue: Int? {
        guard let dueDate = dueDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day
    }
    
    var formattedDueDate: String {
        guard let dueDate = dueDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dueDate)
    }
}

struct ReadingGoal: Codable {
    var target: Int
    var current: Int
    var timeFrame: TimeFrame
    
    enum TimeFrame: String, Codable, CaseIterable {
        case weekly, monthly, yearly
        
        var displayName: String {
            rawValue.capitalized
        }
    }
    
    var progress: Double {
        Double(current) / Double(target)
    }
}

struct AppSettings: Codable {
    var colorScheme: ColorScheme? = .light
    var notificationsEnabled: Bool = true
    var syncWithCloud: Bool = true
    var preferredFontSize: Double = 16.0
    var showReadingProgress: Bool = true
    
    enum ColorScheme: String, Codable {
        case light, dark, system
        
        var systemColorScheme: SwiftUI.ColorScheme? {
            switch self {
            case .light: return .light
            case .dark: return .dark
            case .system: return nil
            }
        }
    }
}
