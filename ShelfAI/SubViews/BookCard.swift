//
//  BookCard.swift
//  ShelfAI
//
//  Created by Krsna  on 5/25/25.
//

import Foundation
import SwiftUI

struct SmallBookCard: View {
    let book: Book
    @EnvironmentObject var vm: LibraryViewModel
    
    var body: some View {
        NavigationLink(destination: BookDetailView(book: book)) {
            VStack(alignment: .leading) {
                BookCover(book: book, size: .small)
                
                Text(book.title)
                    .font(.caption)
                    .lineLimit(2)
                    .frame(width: 100)
                    .multilineTextAlignment(.leading)
            }
            .frame(width: 100)
        }
        .buttonStyle(.plain)
    }
}

struct LargeBookCard: View {
    let book: Book
    @EnvironmentObject var vm: LibraryViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            NavigationLink(destination: BookDetailView(book: book)) {
                BookCover(book: book, size: .medium)
            }
            .buttonStyle(.plain)
            
            Text(book.title)
                .font(.subheadline)
                .lineLimit(2)
                .frame(width: 120)
            
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption2)
                Text(String(format: "%.1f", book.userRatingOrAverage))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Button(action: { vm.toggleLibraryStatus(for: book) }) {
                Text(book.isInLibrary ? "In Library" : "Add")
                    .font(.caption)
                    .foregroundColor(book.isInLibrary ? .green : .accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(4)
                    .background(book.isInLibrary ? Color.green.opacity(0.1) : Color.accentColor.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .frame(width: 120)
    }
}

struct ProgressBookCard: View {
    let book: Book
    @EnvironmentObject var vm: LibraryViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .bottom) {
                BookCover(book: book, size: .small)
                
                ProgressView(value: book.readingProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                    .padding(.horizontal, 4)
                    .offset(y: -4)
            }
            
            Text(book.title)
                .font(.caption)
                .lineLimit(2)
                .frame(width: 100)
            
            Text("\(Int(book.readingProgress * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 100)
    }
}
