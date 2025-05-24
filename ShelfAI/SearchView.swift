//
//  SearchView.swift
//  ShelfAI
//
//  Created by Krsna  on 5/25/25.
//

import SwiftUICore
import UIKit
import CloudKit
import CoreLocation
import SwiftUI

struct SearchView: View {
    @EnvironmentObject var vm: LibraryViewModel
    @State private var searchQuery = ""
    @State private var searchScope = SearchScope.all
    
    enum SearchScope: String, CaseIterable {
        case all = "All"
        case available = "Available"
        case checkedOut = "Checked Out"
        
        var icon: String {
            switch self {
            case .all: return "book"
            case .available: return "book.fill"
            case .checkedOut: return "book.closed.fill"
            }
        }
    }
    
    var filteredBooks: [Book] {
        let books = vm.filteredBooks
        
        switch searchScope {
        case .all: return books
        case .available: return books.filter { $0.status == .available }
        case .checkedOut: return books.filter { $0.status == .checkedOut || $0.status == .overdue }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if searchQuery.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("Search for books by title, author or publisher")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredBooks) { book in
                            BookRow(book: book)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchQuery, prompt: "Search books")
            .searchScopes($searchScope) {
                ForEach(SearchScope.allCases, id: \.self) { scope in
                    Label(scope.rawValue, systemImage: scope.icon)
                        .tag(scope)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}
