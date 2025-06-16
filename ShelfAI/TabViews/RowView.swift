
//
//  RowViews.swift
//  ShelfAI
//
//  Created by Krsna  on 5/25/25.
//

import Foundation
import SwiftUI
struct BookRow: View {
    let book: Book
    @EnvironmentObject var vm: LibraryViewModel
    
    var body: some View {
        NavigationLink(destination: BookDetailView(book: book)) {
            HStack(spacing: 12) {
                BookCover(book: book, size: .small)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.subheadline)
                        .lineLimit(1)
                    
                    Text(book.author)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption2)
                        Text(String(format: "%.1f", book.userRatingOrAverage))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if book.isInLibrary {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
                
                if book.status == .checkedOut || book.status == .overdue {
                    Image(systemName: "book.closed.fill")
                        .foregroundColor(book.status.color)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.subheadline)
    }
}
