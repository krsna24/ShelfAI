//
//  LibraryViewModel.swift
//  ShelfAI
//
//  Created by Krsna  on 5/25/25.
//

import Foundation
import Combine
class LibraryViewModel: ObservableObject {
    @Published var allBooks: [Book] = []
    @Published var recentlyViewed: [Book] = []
    @Published var recommendations: [Book] = []
    @Published var searchText = ""
    @Published var selectedGenre: String = "All"
    @Published var readingGoal = ReadingGoal(target: 10, current: 0, timeFrame: .monthly)
    @Published var appSettings = AppSettings()
    @Published var userStats = UserStats()
    
    private var cancellables = Set<AnyCancellable>()
    
    struct UserStats: Codable {
        var totalBooksRead: Int = 0
        var pagesRead: Int = 0
        var favoriteGenre: String = ""
        var readingStreak: Int = 0
        var lastReadingDate: Date?
    }
    
    init() {
        loadInitialData()
        generateHomeRecommendations()
        setupBindings()
        checkReadingStreak()
    }
    
    private func setupBindings() {
        $allBooks
            .sink { [weak self] books in
                self?.updateUserStats(with: books)
            }
            .store(in: &cancellables)
        
        $appSettings
            .dropFirst()
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveSettings()
            }
            .store(in: &cancellables)
    }
    
    private func updateUserStats(with books: [Book]) {
        userStats.totalBooksRead = books.filter { $0.isRead }.count
        userStats.pagesRead = books.filter { $0.isRead }.compactMap { $0.pageCount }.reduce(0, +)
        
        let genreCounts = Dictionary(grouping: books.filter { $0.isRead }, by: { $0.genre })
        userStats.favoriteGenre = genreCounts.max(by: { $0.value.count < $1.value.count })?.key ?? "None"
    }
    
    private func checkReadingStreak() {
        guard let lastDate = userStats.lastReadingDate else {
            userStats.readingStreak = 0
            return
        }
        
        if Calendar.current.isDateInToday(lastDate) {
            return
        }
        
        if Calendar.current.isDateInYesterday(lastDate) {
            userStats.readingStreak += 1
        } else {
            userStats.readingStreak = 0
        }
        
        userStats.lastReadingDate = Date()
    }
    
    private func saveSettings() {
        // In a real app, save to UserDefaults or CloudKit
    }
    
    func loadInitialData() {
        // This would load from persistent storage in a real app
        let books = [
            Book(
                id: "1", title: "The Great Gatsby", authors: ["F. Scott Fitzgerald"],
                publisher: "Scribner", publishedDate: "1925",
                description: "A story of wealth, love, and the American Dream in the 1920s.",
                pageCount: 180, categories: ["Classic", "Literary Fiction"], averageRating: 4.2,
                openLibraryId: "823857", isInLibrary: true, userRating: 4
            ),
            Book(
                id: "2", title: "To Kill a Mockingbird", authors: ["Harper Lee"],
                publisher: "J. B. Lippincott & Co.", publishedDate: "1960",
                description: "A powerful story of racial injustice and moral growth.",
                pageCount: 281, categories: ["Classic", "Literary Fiction"], averageRating: 4.7,
                openLibraryId: "823856", status: .checkedOut,
                dueDate: Date().addingTimeInterval(86400 * 7)
            ),
            Book(
                id: "3", title: "1984", authors: ["George Orwell"],
                publisher: "Secker & Warburg", publishedDate: "1949",
                description: "A dystopian novel about totalitarianism and surveillance.",
                pageCount: 328, categories: ["Dystopian", "Science Fiction"], averageRating: 4.5,
                openLibraryId: "823855", readingProgress: 0.3,
                lastReadDate: Date().addingTimeInterval(-86400)
            ),
            Book(
                id: "4", title: "Pride and Prejudice", authors: ["Jane Austen"],
                publisher: "T. Egerton, Whitehall", publishedDate: "1813",
                description: "A romantic novel about the Bennet family.",
                pageCount: 279, categories: ["Romance", "Classic"], averageRating: 4.6,
                openLibraryId: "823853", isRead: true
            ),
            Book(
                id: "5", title: "The Hobbit", authors: ["J.R.R. Tolkien"],
                publisher: "Allen & Unwin", publishedDate: "1937",
                description: "A fantasy novel and prelude to The Lord of the Rings.",
                pageCount: 310, categories: ["Fantasy", "Adventure"], averageRating: 4.7,
                openLibraryId: "823821", isInLibrary: true
            ),
            Book(
                id: "6", title: "Dune", authors: ["Frank Herbert"],
                publisher: "Chilton Books", publishedDate: "1965",
                description: "A science fiction epic about politics and ecology.",
                pageCount: 412, categories: ["Science Fiction"], averageRating: 4.8,
                openLibraryId: "823840", status: .checkedOut,
                dueDate: Date().addingTimeInterval(86400 * 3)
            ),
            Book(
                id: "7", title: "The Hunger Games", authors: ["Suzanne Collins"],
                publisher: "Scholastic", publishedDate: "2008",
                description: "A dystopian novel about a televised fight to the death.",
                pageCount: 374, categories: ["Young Adult", "Dystopian"], averageRating: 4.3,
                openLibraryId: "823765", isInLibrary: true
            ),
            Book(
                id: "8", title: "The Shining", authors: ["Stephen King"],
                publisher: "Doubleday", publishedDate: "1977",
                description: "A psychological horror novel about a haunted hotel.",
                pageCount: 447, categories: ["Horror"], averageRating: 4.3,
                openLibraryId: "823785", isRead: true
            ),
            Book(
                id: "9", title: "The Silent Patient", authors: ["Alex Michaelides"],
                publisher: "Celadon Books", publishedDate: "2019",
                description: "A psychological thriller about a woman who shoots her husband.",
                pageCount: 323, categories: ["Thriller", "Mystery"], averageRating: 4.2,
                openLibraryId: "823808"
            ),
            Book(
                id: "10", title: "Where the Crawdads Sing", authors: ["Delia Owens"],
                publisher: "G.P. Putnam's Sons", publishedDate: "2018",
                description: "A novel about an abandoned girl who raises herself in the marshes.",
                pageCount: 368, categories: ["Literary Fiction", "Mystery"], averageRating: 4.8,
                openLibraryId: "823807"
            )
        ]
        
        allBooks = books
    }
    
    var genres: [String] {
        var allGenres = ["All"]
        let bookGenres = Set(allBooks.flatMap { $0.categories })
        allGenres.append(contentsOf: bookGenres.sorted())
        return allGenres
    }
    
    var filteredBooks: [Book] {
        if searchText.isEmpty {
            return allBooks
        } else {
            return allBooks.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.author.localizedCaseInsensitiveContains(searchText) ||
                $0.publisher?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    var currentlyReading: [Book] {
        allBooks.filter { $0.readingProgress > 0 && $0.readingProgress < 1 }
            .sorted { $0.lastReadDate ?? Date.distantPast > $1.lastReadDate ?? Date.distantPast }
    }
    
    var wantToRead: [Book] {
        allBooks.filter { $0.isInLibrary && $0.readingProgress == 0 }
    }
    
    var finishedBooks: [Book] {
        allBooks.filter { $0.isRead }
    }
    
    var checkedOutBooks: [Book] {
        allBooks.filter { $0.status == .checkedOut || $0.status == .overdue }
    }
    
    var overdueBooks: [Book] {
        allBooks.filter { $0.status == .overdue }
    }
    
    func generateHomeRecommendations() {
        recommendations = allBooks
            .filter { !$0.isInLibrary && $0.rating >= 4.0 }
            .sorted { $0.rating > $1.rating }
            .prefix(5)
            .map { $0 }
    }
    
    func generateRecommendations(for book: Book) {
        recommendations = allBooks
            .filter {
                $0.id != book.id &&
                $0.categories.contains(book.genre) &&
                !$0.isInLibrary
            }
            .sorted { $0.rating > $1.rating }
            .prefix(3)
            .map { $0 }
    }
    
    func addToRecent(book: Book) {
        if !recentlyViewed.contains(where: { $0.id == book.id }) {
            recentlyViewed.insert(book, at: 0)
            if recentlyViewed.count > 5 {
                recentlyViewed.removeLast()
            }
        }
        generateRecommendations(for: book)
    }
    
    func toggleReadStatus(for book: Book) {
        if let index = allBooks.firstIndex(where: { $0.id == book.id }) {
            allBooks[index].isRead.toggle()
            if allBooks[index].isRead {
                allBooks[index].lastReadDate = Date()
                allBooks[index].readingProgress = 1.0
                readingGoal.current += 1
                userStats.lastReadingDate = Date()
                generateRecommendations(for: book)
            }
        }
    }
    
    func toggleLibraryStatus(for book: Book) {
        if let index = allBooks.firstIndex(where: { $0.id == book.id }) {
            allBooks[index].isInLibrary.toggle()
            if allBooks[index].isInLibrary {
                allBooks[index].dateAdded = Date()
            }
            generateRecommendations(for: book)
            generateHomeRecommendations()
        }
    }
    
    func updateReadingProgress(_ progress: Double, for book: Book) {
        if let index = allBooks.firstIndex(where: { $0.id == book.id }) {
            allBooks[index].readingProgress = progress
            allBooks[index].lastReadDate = Date()
            userStats.lastReadingDate = Date()
            if progress >= 1 {
                allBooks[index].isRead = true
                readingGoal.current += 1
            }
        }
    }
    
    func borrowBook(_ book: Book) {
        if let index = allBooks.firstIndex(where: { $0.id == book.id }) {
            allBooks[index].status = .checkedOut
            allBooks[index].dueDate = Date().addingTimeInterval(86400 * 14)
            allBooks[index].isInLibrary = true
            generateRecommendations(for: book)
            generateHomeRecommendations()
        }
    }
    
    func returnBook(_ book: Book) {
        if let index = allBooks.firstIndex(where: { $0.id == book.id }) {
            allBooks[index].status = .available
            allBooks[index].dueDate = nil
        }
    }
    
    func renewBook(_ book: Book) {
        if let index = allBooks.firstIndex(where: { $0.id == book.id }), book.status == .checkedOut {
            allBooks[index].dueDate = Date().addingTimeInterval(86400 * 14)
        }
    }
    
    func updateOverdueStatuses() {
        for index in allBooks.indices {
            if let dueDate = allBooks[index].dueDate, dueDate < Date(), allBooks[index].status == .checkedOut {
                allBooks[index].status = .overdue
            }
        }
    }
    
    func updateNotes(_ notes: String, for book: Book) {
        if let index = allBooks.firstIndex(where: { $0.id == book.id }) {
            allBooks[index].notes = notes
        }
    }
    
    func updateUserRating(_ rating: Int?, for book: Book) {
        if let index = allBooks.firstIndex(where: { $0.id == book.id }) {
            allBooks[index].userRating = rating
        }
    }
    
    func reserveBook(_ book: Book) {
        if let index = allBooks.firstIndex(where: { $0.id == book.id }) {
            allBooks[index].status = .reserved
        }
    }
    
    func cancelReservation(_ book: Book) {
        if let index = allBooks.firstIndex(where: { $0.id == book.id }), allBooks[index].status == .reserved {
            allBooks[index].status = .available
        }
    }
    
    func markAsCurrentlyReading(_ book: Book) {
        if let index = allBooks.firstIndex(where: { $0.id == book.id }) {
            allBooks[index].readingProgress = 0.1
            allBooks[index].lastReadDate = Date()
            userStats.lastReadingDate = Date()
        }
    }
    
    func resetReadingGoal() {
        readingGoal.current = 0
    }
}
