//
//  BookSection.swift
//  ShelfAI
//
//  Created by Krsna  on 5/25/25.
//

import Foundation
import SwiftUI

struct BookSection: View {
    let title: String
    let books: [Book]
    var style: BookStyle
    var showSeeAll: Bool = true
    
    enum BookStyle {
        case small, large, withProgress
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            SectionHeader(title: title, showSeeAll: showSeeAll && books.count > 5)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(books.prefix(showSeeAll ? 5 : books.count)) { book in
                        switch style {
                        case .small:
                            SmallBookCard(book: book)
                        case .large:
                            LargeBookCard(book: book)
                        case .withProgress:
                            ProgressBookCard(book: book)
                        }
                    }
                    
                    if showSeeAll && books.count > 5 {
                        SeeAllCard(count: books.count - 5)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
