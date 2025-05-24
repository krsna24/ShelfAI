//
//  ReadingViews.swift
//  ShelfAI
//
//  Created by Krsna  on 5/25/25.
//

import Foundation
import SwiftUI
struct ReadingNowView: View {
    @EnvironmentObject var vm: LibraryViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let currentBook = vm.currentlyReading.first {
                        CurrentlyReadingCard(book: currentBook)
                            .padding(.horizontal)
                    }
                    
                    if !vm.wantToRead.isEmpty {
                        BookSection(
                            title: "Want to Read",
                            books: vm.wantToRead,
                            style: .small
                        )
                    }
                    
                    if !vm.finishedBooks.isEmpty {
                        BookSection(
                            title: "Finished",
                            books: vm.finishedBooks,
                            style: .small
                        )
                    }
                    
                    if !vm.checkedOutBooks.isEmpty {
                        BookSection(
                            title: "Checked Out",
                            books: vm.checkedOutBooks,
                            style: .small
                        )
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Reading Now")
        }
    }
}

struct CurrentlyReadingCard: View {
    let book: Book
    @EnvironmentObject var vm: LibraryViewModel
    @State private var progress: Double
    
    init(book: Book) {
        self.book = book
        self._progress = State(initialValue: book.readingProgress)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Currently Reading")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            HStack(alignment: .top, spacing: 16) {
                BookCover(book: book, size: .medium)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(book.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Progress")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(progress * 100))%")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                        
                        HStack {
                            Button(action: {
                                progress = max(0, progress - 0.1)
                                vm.updateReadingProgress(progress, for: book)
                            }) {
                                Image(systemName: "minus")
                                    .frame(width: 30, height: 30)
                                    .background(Color(.systemGray5))
                                    .clipShape(Circle())
                            }
                            .disabled(progress <= 0)
                            
                            Spacer()
                            
                            Button(action: {
                                progress = min(1, progress + 0.1)
                                vm.updateReadingProgress(progress, for: book)
                            }) {
                                Image(systemName: "plus")
                                    .frame(width: 30, height: 30)
                                    .background(Color(.systemGray5))
                                    .clipShape(Circle())
                            }
                            .disabled(progress >= 1)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}
