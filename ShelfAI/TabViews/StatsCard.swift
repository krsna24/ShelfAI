//
//  StatsCard.swift
//  ShelfAI
//
//  Created by Krsna  on 5/25/25.
//

import Foundation
import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Text(value)
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}
import Foundation

struct UserStats: Codable {
    var totalBooksRead: Int = 0      // Total number of books the user has read
    var pagesRead: Int = 0            // Total number of pages the user has read
    var favoriteGenre: String = ""     // User's most frequently read genre
    var readingStreak: Int = 0         // Current reading streak (consecutive days reading)
    var lastReadingDate: Date?         // Date of the user's last reading session

    mutating func updateStats(for book: Book) {
        // Increment the total books read if the book is marked as read
        if book.isRead {
            totalBooksRead += 1
            pagesRead += book.pageCount ?? 0
            lastReadingDate = Date() // Update the last reading date
        }
        
        // Update favorite genre if the book is read, assuming the first category is the main genre
        if let genre = book.categories.first {
            favoriteGenre = genre // Here, you may want to implement logic to track the most read genre
        }
    }
    
    mutating func resetStreak() {
        readingStreak = 0 // Reset the reading streak
    }
    
    mutating func incrementStreak() {
        readingStreak += 1 // Increment the reading streak
    }
}
