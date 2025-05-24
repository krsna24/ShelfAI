//
//  ProfileView.swift
//  ShelfAI
//
//  Created by Krsna  on 5/25/25.
//

import Foundation
import SwiftUI
struct ProfileView: View {
    @EnvironmentObject var vm: LibraryViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // User Stats
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.accentColor)
                        
                        VStack(spacing: 4) {
                            Text("Reading Stats")
                                .font(.title3.bold())
                            
                            Text("\(vm.userStats.readingStreak) day streak")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top)
                    
                    // Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(title: "Books Read", value: "\(vm.userStats.totalBooksRead)", icon: "book.fill")
                        StatCard(title: "Pages Read", value: "\(vm.userStats.pagesRead)", icon: "book.pages.fill")
                        StatCard(title: "Favorite Genre", value: vm.userStats.favoriteGenre, icon: "tag.fill")
                        StatCard(title: "In Library", value: "\(vm.allBooks.filter { $0.isInLibrary }.count)", icon: "books.vertical.fill")
                    }
                    .padding(.horizontal)
                    
                    // Reading Goal Progress
                    VStack(spacing: 12) {
                        HStack {
                            Text("Reading Goal Progress")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(vm.readingGoal.current)/\(vm.readingGoal.target)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: vm.readingGoal.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Recently Added
                    if !vm.allBooks.filter({ $0.isInLibrary }).isEmpty {
                        BookSection(
                            title: "Recently Added",
                            books: Array(vm.allBooks.filter { $0.isInLibrary }.sorted { $0.dateAdded > $1.dateAdded }.prefix(5)),
                            style: .small,
                            showSeeAll: false
                        )
                    }
                    
                    // Recently Viewed
                    if !vm.recentlyViewed.isEmpty {
                        BookSection(
                            title: "Recently Viewed",
                            books: vm.recentlyViewed,
                            style: .small,
                            showSeeAll: false
                        )
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
        }
    }
}

