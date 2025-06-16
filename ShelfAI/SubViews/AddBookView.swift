//
//  AddBookView.swift
//  ShelfAI
//
//  Created by Krsna  on 5/25/25.
//

import Foundation
import SwiftUI
struct AddBookView: View {
    @EnvironmentObject var vm: LibraryViewModel
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var author = ""
    @State private var pageCount = ""
    @State private var selectedGenre = ""
    @State private var isbn = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("Author", text: $author)
                    TextField("Page Count", text: $pageCount)
                        .keyboardType(.numberPad)
                    TextField("Genre", text: $selectedGenre)
                    TextField("ISBN (optional)", text: $isbn)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button("Add Book") {
                        let newBook = Book(
                            id: UUID().uuidString,
                            title: title,
                            authors: [author],
                            publisher: nil,
                            publishedDate: nil,
                            description: nil,
                            pageCount: Int(pageCount),
                            categories: [selectedGenre],
                            averageRating: nil,
                            openLibraryId: isbn.isEmpty ? nil : isbn,
                            isInLibrary: true
                        )
                        vm.allBooks.append(newBook)
                        dismiss()
                    }
                    .disabled(title.isEmpty || author.isEmpty || pageCount.isEmpty || selectedGenre.isEmpty)
                }
            }
            .navigationTitle("Add New Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
