//
//  ShelfAIApp.swift
//  ShelfAI
//
//  Created by Krsna  on 3/24/25.
//

import SwiftUI

@main
struct BookshelfApp: App {
    @StateObject private var library = LibraryViewModel()
    @State private var selectedTab: Tab = .library
    
    enum Tab: String, CaseIterable {
        case library, readingNow, search, profile
        
        var title: String {
            switch self {
            case .library: return "Library"
            case .readingNow: return "Reading Now"
            case .search: return "Search"
            case .profile: return "Profile"
            }
        }
        
        var icon: String {
            switch self {
            case .library: return "books.vertical.fill"
            case .readingNow: return "book.fill"
            case .search: return "magnifyingglass"
            case .profile: return "person.fill"
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    NavigationStack {
                        switch tab {
                        case .library:
                            LibraryView()
                        case .readingNow:
                            ReadingNowView()
                        case .search:
                            SearchView()
                        case .profile:
                            ProfileView()
                        }
                    }
                    .tag(tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.icon)
                    }
                }
            }
            .tint(.accentColor)
            .environmentObject(library)
//            .preferredColorScheme(library.appSettings.colorScheme)
            .preferredColorScheme(library.appSettings.colorScheme?.systemColorScheme) // Apply color scheme
            .environment(\.sizeCategory, library.appSettings.sizeCategory) // For adjusting font size
            .onAppear {
                setupAppearance()
            }
        }
    }
    
    private func setupAppearance() {
        UITabBar.appearance().scrollEdgeAppearance = UITabBarAppearance()
        UINavigationBar.appearance().largeTitleTextAttributes = [.font: UIFont.systemFont(ofSize: 34, weight: .bold)]
    }
}
