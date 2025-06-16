//
//  ReadingGoalCard.swift
//  ShelfAI
//
//  Created by Krsna  on 5/25/25.
//

import Foundation
import SwiftUI
struct ReadingGoalCard: View {
    @EnvironmentObject var vm: LibraryViewModel
    
    var progress: Double {
        vm.readingGoal.progress
    }
    
    var progressColor: Color {
        switch progress {
        case 0..<0.3: return .red
        case 0.3..<0.7: return .yellow
        case 0.7...1.0: return .green
        default: return .accentColor
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Reading Goal")
                    .font(.subheadline.bold())
                
                Spacer()
                
                Text("\(vm.readingGoal.current)/\(vm.readingGoal.target)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
            
            HStack {
                Text("\(vm.readingGoal.timeFrame.displayName) goal")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}
