//
//  ContentView.swift
//  ShelfAI
//
//  Created by Krsna  on 5/25/25.
//

import SwiftUI
import Combine

struct SectionHeader: View {
    let title: String
    var showSeeAll: Bool = true
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            Spacer()
            
        }
    }
}

struct BookCover: View {
    let book: Book
    var size: CoverSize
    
    enum CoverSize {
        case small, medium, large
        
        var dimensions: CGSize {
            switch self {
            case .small: return CGSize(width: 80, height: 120)
            case .medium: return CGSize(width: 120, height: 180)
            case .large: return CGSize(width: 150, height: 225)
            }
        }
    }
    
    var body: some View {
        Group {
            if let url = book.coverImageURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if phase.error != nil {
                        placeholderCover
                    } else {
                        ProgressView()
                    }
                }
            } else {
                placeholderCover
            }
        }
        .frame(width: size.dimensions.width, height: size.dimensions.height)
        .cornerRadius(8)
        .shadow(radius: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }
    
    private var placeholderCover: some View {
        ZStack {
            Color(.systemGray5)
            Image(systemName: "book.closed.fill")
                .foregroundColor(.secondary)
        }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

