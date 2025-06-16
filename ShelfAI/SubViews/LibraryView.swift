//
//  LibraryView.swift
//  ShelfAI
//
//  Created by Krsna  on 5/25/25.
//

import Foundation
import SwiftUI
struct LibraryView: View {
    @EnvironmentObject var vm: LibraryViewModel
    @State private var showingGenrePicker = false
    @State private var showingSettings = false
    @State private var showingAddBook = false
    
    var body: some View {
        NavigationStack {
            ZStack {
//                GradientBackground() // Use the gradient background
                
                BlobShape()
                    .fill(Color.purple.opacity(0.05)) // Blob effect with slight transparency
                    .blur(radius: 10) // Apply a blur effect to the blob
                    .offset(x: 50, y: 150) // Position the blob shape,
                BlobShape()
                                    .fill(Color.blue.opacity(0.12)) // Blob effect with slight transparency
                                    .blur(radius: 1) // Apply a blur effect to the blob
                                    .offset(x: 350, y: 550) // Position the blob shape
                
                ScrollView {
                    VStack(spacing: 24) {
                        if !vm.recommendations.isEmpty {
                            BookSection(
                                title: "Recommended For You",
                                books: vm.recommendations,
                                style: .large
                            )
                        }
                        
                        // Continue Reading
                        if !vm.currentlyReading.isEmpty {
                            BookSection(
                                title: "Continue Reading",
                                books: vm.currentlyReading,
                                style: .withProgress
                            )
                        }
                        
                        // Your Library
                        if !vm.allBooks.filter({ $0.isInLibrary }).isEmpty {
                            BookSection(
                                title: "Your Library",
                                books: vm.allBooks.filter { $0.isInLibrary },
                                style: .small
                            )
                        }
                        
                        // All Books
                        BookSection(
                            title: "Browse All Books",
                            books: vm.filteredBooks,
                            style: .small
                        )
                    }
                    .padding(.vertical)
                }
                .background(Color(.clear))
                .navigationTitle("Library")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button(action: { showingGenrePicker = true }) {
                                Label("Filter by Genre", systemImage: "line.3.horizontal.decrease.circle")
                            }
                            
                            Button(action: { showingAddBook = true }) {
                                Label("Add New Book", systemImage: "plus")
                            }
                            
                            Button(action: { showingSettings = true }) {
                                Label("Settings", systemImage: "gearshape")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                .confirmationDialog("Select Genre", isPresented: $showingGenrePicker) {
                    ForEach(vm.genres, id: \.self) { genre in
                        Button(genre) {
                            vm.selectedGenre = genre
                            vm.allBooks = vm.allBooks.filter {
                                genre == "All" || $0.categories.contains(genre)
                            }
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView(settings: $vm.appSettings,
                                 readingGoal: $vm.readingGoal)
                }
                .sheet(isPresented: $showingAddBook) {
                    AddBookView()
                }
            }
        }
    }
}
