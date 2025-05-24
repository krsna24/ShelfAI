//
//  SeeAllCard.swift
//  ShelfAI
//
//  Created by Krsna  on 5/25/25.
//

import Foundation
import SwiftUI
struct SeeAllCard: View {
    let count: Int
    
    var body: some View {
        NavigationLink(destination: Text("All Books")) {
            VStack {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 60)
                    
                    Text("+\(count)")
                        .font(.headline)
                }
                
                Text("See All")
                    .font(.caption)
            }
            .frame(width: 80)
            .foregroundColor(.primary)
        }
    }
}
