//
//  SeeAllCard.swift
//  ShelfAI
//
//  Created by Krsna  on 5/25/25.
//

import Foundation
import SwiftUI
import SwiftUI

struct SeeAllCard: View {
    let count: Int

    var body: some View {
        NavigationLink(destination: BrowseAllBooksView()) {
            VStack {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 60)

                    Text("+\(count)")
                        .font(.headline)
                }

            }
            .frame(width: 80)
            .foregroundColor(.primary)
        }
    }
}


import SwiftUI

struct BrowseAllBooksView: View {
    @EnvironmentObject var vm: LibraryViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 2), spacing: 20) {
                    ForEach(vm.allBooks) { book in
                        NavigationLink(destination: BookDetailView(book: book)) {
                            LargeBookCard(book: book)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("All Books")
            .background(Color(.systemGroupedBackground))
        }
    }
}
