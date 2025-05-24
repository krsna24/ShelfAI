//
//  BookDetailView.swift
//  ShelfAI
//
//  Created by Krsna  on 5/25/25.
//

import Foundation
import SwiftUI
struct BookDetailView: View {
    let book: Book
    @EnvironmentObject var vm: LibraryViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingShareSheet = false
    @State private var showingNotesEditor = false
    @State private var showingRatingDialog = false
    @State private var progress: Double
    @State private var notes: String
    @State private var userRating: Int?
    
    init(book: Book) {
        self.book = book
        self._progress = State(initialValue: book.readingProgress)
        self._notes = State(initialValue: book.notes)
        self._userRating = State(initialValue: book.userRating)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Cover image with floating buttons
                ZStack(alignment: .bottom) {
                    BookCover(book: book, size: .large)
                        .padding(.top)
                    
                    // Floating action buttons
                    HStack {
                        Menu {
                            if book.isInLibrary {
                                if book.readingProgress == 0 {
                                    Button(action: { vm.markAsCurrentlyReading(book) }) {
                                        Label("Start Reading", systemImage: "book.fill")
                                    }
                                }
                                
                                if !book.isRead {
                                    Button(action: {
                                        progress = 1.0
                                        vm.updateReadingProgress(progress, for: book)
                                    }) {
                                        Label("Mark as Read", systemImage: "checkmark")
                                    }
                                }
                                
                                Button(action: { vm.toggleLibraryStatus(for: book) }) {
                                    Label("Remove from Library", systemImage: "trash")
                                }
                            } else {
                                Button(action: { vm.toggleLibraryStatus(for: book) }) {
                                    Label("Add to Library", systemImage: "plus")
                                }
                            }
                            
                            Button(action: { showingRatingDialog = true }) {
                                Label("Rate This Book", systemImage: "star.fill")
                            }
                            
                            if !book.notes.isEmpty {
                                Button(action: { showingNotesEditor = true }) {
                                    Label("Edit Notes", systemImage: "note.text")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .font(.system(size: 28))
                                .foregroundColor(.accentColor)
                                .padding(10)
                                .background(.thickMaterial)
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Button(action: { showingShareSheet = true }) {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .font(.system(size: 28))
                                .foregroundColor(.accentColor)
                                .padding(10)
                                .background(.thickMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .offset(y: 24)
                }
                .padding(.bottom, 30)
                
                // Book info
                VStack(alignment: .leading, spacing: 20) {
                    VStack(spacing: 8) {
                        Text(book.title)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        
                        Text("by \(book.author)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Rating and metadata
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", book.userRatingOrAverage))
                        }
                        
                        if let pageCount = book.pageCount {
                            HStack(spacing: 4) {
                                Image(systemName: "book.pages")
                                Text("\(pageCount)")
                            }
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(book.formattedPublishedDate)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    
                    // Status and actions
                    Group {
                        switch book.status {
                        case .available:
                            Button(action: { vm.borrowBook(book) }) {
                                Text("Borrow")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            
                        case .checkedOut:
                            VStack(spacing: 8) {
                                if let dueDate = book.dueDate, let daysLeft = book.daysUntilDue {
                                    Text(daysLeft > 0 ?
                                         "Due in \(daysLeft) day\(daysLeft == 1 ? "" : "s")" :
                                         "Due today")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text(dueDate.formatted(.dateTime.day().month().year()))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Button(action: { vm.renewBook(book) }) {
                                        Text("Renew")
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 44)
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    Button(action: { vm.returnBook(book) }) {
                                        Text("Return")
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 44)
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                            
                        case .overdue:
                            VStack(spacing: 8) {
                                Text("Overdue - Please Return")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                                
                                if let dueDate = book.dueDate {
                                    Text(dueDate.formatted(.dateTime.day().month().year()))
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                }
                                
                                Button(action: { vm.returnBook(book) }) {
                                    Text("Return Book")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                                .controlSize(.large)
                            }
                            
                        case .reserved:
                            Button(action: { vm.cancelReservation(book) }) {
                                Text("Cancel Reservation")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }
                    }
                    
                    // Reading progress
                    if book.isInLibrary && vm.appSettings.showReadingProgress {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Reading Progress")
                                    .font(.subheadline.bold())
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
                                        .frame(width: 36, height: 36)
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
                                        .frame(width: 36, height: 36)
                                        .background(Color(.systemGray5))
                                        .clipShape(Circle())
                                }
                                .disabled(progress >= 1)
                                
                                Spacer()
                                
                                Button(action: {
                                    progress = 1.0
                                    vm.updateReadingProgress(progress, for: book)
                                }) {
                                    Text("Mark as Read")
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.accentColor.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // User Notes
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(notes.isEmpty ? "Add Notes" : "Your Notes")
                                .font(.subheadline.bold())
                            
                            Spacer()
                            
                            if !notes.isEmpty {
                                Button(action: { showingNotesEditor = true }) {
                                    Text("Edit")
                                        .font(.subheadline)
                                }
                            }
                        }
                        
                        Divider()
                        
                        if notes.isEmpty {
                            Button(action: { showingNotesEditor = true }) {
                                Text("Add notes about this book...")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else {
                            Text(notes)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Description
                    if let description = book.description {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.subheadline.bold())
                            
                            Divider()
                            
                            Text(description)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.subheadline.bold())
                        
                        Divider()
                        
                        DetailRow(label: "Publisher", value: book.publisher ?? "Unknown")
                        DetailRow(label: "Published", value: book.publishedDate ?? "Unknown")
                        DetailRow(label: "Pages", value: book.pageCount != nil ? "\(book.pageCount!)" : "Unknown")
                        DetailRow(label: "Genre", value: book.genre)
                        DetailRow(label: "Status", value: book.status.displayName)
                        
                        if let dueDate = book.dueDate {
                            DetailRow(label: "Due Date", value: dueDate.formatted(.dateTime.day().month().year()))
                        }
                    }
                    
                    // Recommendations
                    if !vm.recommendations.isEmpty && vm.recommendations.first?.id != book.id {
                        BookSection(
                            title: "You Might Also Like",
                            books: vm.recommendations,
                            style: .small
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ActivityView(activityItems: [book.title, book.coverImageURL as Any].compactMap { $0 })
        }
        .sheet(isPresented: $showingNotesEditor) {
            NavigationStack {
                TextEditor(text: $notes)
                    .padding()
                    .navigationTitle("Your Notes")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingNotesEditor = false
                                notes = book.notes // Revert changes
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                vm.updateNotes(notes, for: book)
                                showingNotesEditor = false
                            }
                        }
                    }
            }
        }
        .confirmationDialog("Rate This Book", isPresented: $showingRatingDialog) {
            ForEach(1...5, id: \.self) { rating in
                Button("\(rating) star\(rating == 1 ? "" : "s")") {
                    userRating = rating
                    vm.updateUserRating(userRating, for: book)
                }
            }
            if userRating != nil {
                Button("Remove Rating", role: .destructive) {
                    userRating = nil
                    vm.updateUserRating(nil, for: book)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("How would you rate this book?")
        }
        .onAppear {
            vm.generateRecommendations(for: book)
            vm.updateOverdueStatuses()
            vm.addToRecent(book: book)
        }
    }
}
