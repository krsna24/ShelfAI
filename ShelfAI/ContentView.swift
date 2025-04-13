import SwiftUI
import Combine

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

// MARK: - Data Models
struct Book: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let authors: [String]
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let pageCount: Int?
    let categories: [String]
    let averageRating: Double?
    let openLibraryId: String?
    var isRead: Bool = false
    var isInLibrary: Bool = false
    var readingProgress: Double = 0
    var lastReadDate: Date?
    var status: BookStatus = .available
    var dueDate: Date?
    var notes: String = ""
    var userRating: Int?
    var dateAdded: Date = Date()
    
    enum BookStatus: String, Codable, CaseIterable {
        case available, checkedOut, overdue, reserved
        
        var displayName: String {
            switch self {
            case .available: return "Available"
            case .checkedOut: return "Checked Out"
            case .overdue: return "Overdue"
            case .reserved: return "Reserved"
            }
        }
        
        var color: Color {
            switch self {
            case .available: return .green
            case .checkedOut: return .blue
            case .overdue: return .red
            case .reserved: return .orange
            }
        }
    }
    
    var author: String { authors.joined(separator: ", ") }
    var genre: String { categories.first ?? "Unknown" }
    var rating: Double { averageRating ?? 0.0 }
    var userRatingOrAverage: Double { Double(userRating ?? Int(rating * 2)) / 2 }
    
    var coverImageURL: URL? {
        guard let openLibraryId = openLibraryId else { return nil }
        return URL(string: "https://covers.openlibrary.org/b/id/\(openLibraryId)-L.jpg")
    }
    
    var formattedPublishedDate: String {
        guard let publishedDate = publishedDate else { return "Unknown" }
        if let year = Int(publishedDate.prefix(4)) {
            return "\(year)"
        }
        return publishedDate
    }
    
    var daysUntilDue: Int? {
        guard let dueDate = dueDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day
    }
    
    var formattedDueDate: String {
        guard let dueDate = dueDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dueDate)
    }
}

struct ReadingGoal: Codable {
    var target: Int
    var current: Int
    var timeFrame: TimeFrame
    
    enum TimeFrame: String, Codable, CaseIterable {
        case weekly, monthly, yearly
        
        var displayName: String {
            rawValue.capitalized
        }
    }
    
    var progress: Double {
        Double(current) / Double(target)
    }
}

struct AppSettings: Codable {
    var colorScheme: ColorScheme? = .light
    var notificationsEnabled: Bool = true
    var syncWithCloud: Bool = true
    var preferredFontSize: Double = 16.0
    var showReadingProgress: Bool = true
    
    enum ColorScheme: String, Codable {
        case light, dark, system
        
        var systemColorScheme: SwiftUI.ColorScheme? {
            switch self {
            case .light: return .light
            case .dark: return .dark
            case .system: return nil
            }
        }
    }
}

// MARK: - View Model
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

// MARK: - Main Views
struct LibraryView: View {
    @EnvironmentObject var vm: LibraryViewModel
    @State private var showingGenrePicker = false
    @State private var showingSettings = false
    @State private var showingAddBook = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Reading Goal
                    if vm.appSettings.showReadingProgress {
                        ReadingGoalCard()
                            .padding(.horizontal)
                    }
                    
                    // Recommendations Section
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
            .background(Color(.systemGroupedBackground))
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
                SettingsView()
            }
            .sheet(isPresented: $showingAddBook) {
                AddBookView()
            }
        }
    }
}

struct AddBookView: View {
    @EnvironmentObject var vm: LibraryViewModel
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var author = ""
    @State private var pageCount = ""
    @State private var selectedGenre = ""
    @State private var isbn = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("Author", text: $author)
                    TextField("Page Count", text: $pageCount)
                        .keyboardType(.numberPad)
                    TextField("Genre", text: $selectedGenre)
                    TextField("ISBN (optional)", text: $isbn)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button("Add Book") {
                        let newBook = Book(
                            id: UUID().uuidString,
                            title: title,
                            authors: [author],
                            publisher: nil,
                            publishedDate: nil,
                            description: nil,
                            pageCount: Int(pageCount),
                            categories: [selectedGenre],
                            averageRating: nil,
                            openLibraryId: isbn.isEmpty ? nil : isbn,
                            isInLibrary: true
                        )
                        vm.allBooks.append(newBook)
                        dismiss()
                    }
                    .disabled(title.isEmpty || author.isEmpty || pageCount.isEmpty || selectedGenre.isEmpty)
                }
            }
            .navigationTitle("Add New Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

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

struct SectionHeader: View {
    let title: String
    var showSeeAll: Bool = true
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            Spacer()
            
            if showSeeAll {
                NavigationLink("See All") {
                    Text("All \(title) books")
                        .navigationTitle(title)
                }
                .padding(.horizontal)
                .font(.subheadline)
            }
        }
    }
}

struct SmallBookCard: View {
    let book: Book
    @EnvironmentObject var vm: LibraryViewModel
    
    var body: some View {
        NavigationLink(destination: BookDetailView(book: book)) {
            VStack(alignment: .leading) {
                BookCover(book: book, size: .small)
                
                Text(book.title)
                    .font(.caption)
                    .lineLimit(2)
                    .frame(width: 100)
                    .multilineTextAlignment(.leading)
            }
            .frame(width: 100)
        }
        .buttonStyle(.plain)
    }
}

struct LargeBookCard: View {
    let book: Book
    @EnvironmentObject var vm: LibraryViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            NavigationLink(destination: BookDetailView(book: book)) {
                BookCover(book: book, size: .medium)
            }
            .buttonStyle(.plain)
            
            Text(book.title)
                .font(.subheadline)
                .lineLimit(2)
                .frame(width: 120)
            
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption2)
                Text(String(format: "%.1f", book.userRatingOrAverage))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Button(action: { vm.toggleLibraryStatus(for: book) }) {
                Text(book.isInLibrary ? "In Library" : "Add")
                    .font(.caption)
                    .foregroundColor(book.isInLibrary ? .green : .accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(4)
                    .background(book.isInLibrary ? Color.green.opacity(0.1) : Color.accentColor.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .frame(width: 120)
    }
}

struct ProgressBookCard: View {
    let book: Book
    @EnvironmentObject var vm: LibraryViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .bottom) {
                BookCover(book: book, size: .small)
                
                ProgressView(value: book.readingProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                    .padding(.horizontal, 4)
                    .offset(y: -4)
            }
            
            Text(book.title)
                .font(.caption)
                .lineLimit(2)
                .frame(width: 100)
            
            Text("\(Int(book.readingProgress * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 100)
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

struct ReadingNowView: View {
    @EnvironmentObject var vm: LibraryViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let currentBook = vm.currentlyReading.first {
                        CurrentlyReadingCard(book: currentBook)
                            .padding(.horizontal)
                    }
                    
                    if !vm.wantToRead.isEmpty {
                        BookSection(
                            title: "Want to Read",
                            books: vm.wantToRead,
                            style: .small
                        )
                    }
                    
                    if !vm.finishedBooks.isEmpty {
                        BookSection(
                            title: "Finished",
                            books: vm.finishedBooks,
                            style: .small
                        )
                    }
                    
                    if !vm.checkedOutBooks.isEmpty {
                        BookSection(
                            title: "Checked Out",
                            books: vm.checkedOutBooks,
                            style: .small
                        )
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Reading Now")
        }
    }
}

struct CurrentlyReadingCard: View {
    let book: Book
    @EnvironmentObject var vm: LibraryViewModel
    @State private var progress: Double
    
    init(book: Book) {
        self.book = book
        self._progress = State(initialValue: book.readingProgress)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Currently Reading")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            HStack(alignment: .top, spacing: 16) {
                BookCover(book: book, size: .medium)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(book.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Progress")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(progress * 100))%")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                        
                        HStack {
                            Button(action: {
                                progress = max(0, progress - 0.1)
                                vm.updateReadingProgress(progress, for: book)
                            }) {
                                Image(systemName: "minus")
                                    .frame(width: 30, height: 30)
                                    .background(Color(.systemGray5))
                                    .clipShape(Circle())
                            }
                            .disabled(progress <= 0)
                            
                            Spacer()
                            
                            Button(action: {
                                progress = min(1, progress + 0.1)
                                vm.updateReadingProgress(progress, for: book)
                            }) {
                                Image(systemName: "plus")
                                    .frame(width: 30, height: 30)
                                    .background(Color(.systemGray5))
                                    .clipShape(Circle())
                            }
                            .disabled(progress >= 1)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}

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

struct BookRow: View {
    let book: Book
    @EnvironmentObject var vm: LibraryViewModel
    
    var body: some View {
        NavigationLink(destination: BookDetailView(book: book)) {
            HStack(spacing: 12) {
                BookCover(book: book, size: .small)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.subheadline)
                        .lineLimit(1)
                    
                    Text(book.author)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption2)
                        Text(String(format: "%.1f", book.userRatingOrAverage))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if book.isInLibrary {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
                
                if book.status == .checkedOut || book.status == .overdue {
                    Image(systemName: "book.closed.fill")
                        .foregroundColor(book.status.color)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

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

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Text(value)
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Book Detail View
struct BookDetailView: View {
    let book: Book
    @EnvironmentObject var vm: LibraryViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingShareSheet = false
    @State private var showingNotesEditor = false
    @State private var showingRatingDialog = false
    @State private var progress: Double
    @State private var notes: String
    @State private var userRating: Int?
    
    init(book: Book) {
        self.book = book
        self._progress = State(initialValue: book.readingProgress)
        self._notes = State(initialValue: book.notes)
        self._userRating = State(initialValue: book.userRating)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Cover image with floating buttons
                ZStack(alignment: .bottom) {
                    BookCover(book: book, size: .large)
                        .padding(.top)
                    
                    // Floating action buttons
                    HStack {
                        Menu {
                            if book.isInLibrary {
                                if book.readingProgress == 0 {
                                    Button(action: { vm.markAsCurrentlyReading(book) }) {
                                        Label("Start Reading", systemImage: "book.fill")
                                    }
                                }
                                
                                if !book.isRead {
                                    Button(action: {
                                        progress = 1.0
                                        vm.updateReadingProgress(progress, for: book)
                                    }) {
                                        Label("Mark as Read", systemImage: "checkmark")
                                    }
                                }
                                
                                Button(action: { vm.toggleLibraryStatus(for: book) }) {
                                    Label("Remove from Library", systemImage: "trash")
                                }
                            } else {
                                Button(action: { vm.toggleLibraryStatus(for: book) }) {
                                    Label("Add to Library", systemImage: "plus")
                                }
                            }
                            
                            Button(action: { showingRatingDialog = true }) {
                                Label("Rate This Book", systemImage: "star.fill")
                            }
                            
                            if !book.notes.isEmpty {
                                Button(action: { showingNotesEditor = true }) {
                                    Label("Edit Notes", systemImage: "note.text")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .font(.system(size: 28))
                                .foregroundColor(.accentColor)
                                .padding(10)
                                .background(.thickMaterial)
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Button(action: { showingShareSheet = true }) {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .font(.system(size: 28))
                                .foregroundColor(.accentColor)
                                .padding(10)
                                .background(.thickMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .offset(y: 24)
                }
                .padding(.bottom, 30)
                
                // Book info
                VStack(alignment: .leading, spacing: 20) {
                    VStack(spacing: 8) {
                        Text(book.title)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        
                        Text("by \(book.author)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Rating and metadata
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", book.userRatingOrAverage))
                        }
                        
                        if let pageCount = book.pageCount {
                            HStack(spacing: 4) {
                                Image(systemName: "book.pages")
                                Text("\(pageCount)")
                            }
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(book.formattedPublishedDate)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    
                    // Status and actions
                    Group {
                        switch book.status {
                        case .available:
                            Button(action: { vm.borrowBook(book) }) {
                                Text("Borrow")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            
                        case .checkedOut:
                            VStack(spacing: 8) {
                                if let dueDate = book.dueDate, let daysLeft = book.daysUntilDue {
                                    Text(daysLeft > 0 ?
                                         "Due in \(daysLeft) day\(daysLeft == 1 ? "" : "s")" :
                                         "Due today")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text(dueDate.formatted(.dateTime.day().month().year()))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Button(action: { vm.renewBook(book) }) {
                                        Text("Renew")
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 44)
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    Button(action: { vm.returnBook(book) }) {
                                        Text("Return")
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 44)
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                            
                        case .overdue:
                            VStack(spacing: 8) {
                                Text("Overdue - Please Return")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                                
                                if let dueDate = book.dueDate {
                                    Text(dueDate.formatted(.dateTime.day().month().year()))
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                }
                                
                                Button(action: { vm.returnBook(book) }) {
                                    Text("Return Book")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                                .controlSize(.large)
                            }
                            
                        case .reserved:
                            Button(action: { vm.cancelReservation(book) }) {
                                Text("Cancel Reservation")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }
                    }
                    
                    // Reading progress
                    if book.isInLibrary && vm.appSettings.showReadingProgress {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Reading Progress")
                                    .font(.subheadline.bold())
                                Spacer()
                                Text("\(Int(progress * 100))%")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            ProgressView(value: progress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                            
                            HStack {
                                Button(action: {
                                    progress = max(0, progress - 0.1)
                                    vm.updateReadingProgress(progress, for: book)
                                }) {
                                    Image(systemName: "minus")
                                        .frame(width: 36, height: 36)
                                        .background(Color(.systemGray5))
                                        .clipShape(Circle())
                                }
                                .disabled(progress <= 0)
                                
                                Spacer()
                                
                                Button(action: {
                                    progress = min(1, progress + 0.1)
                                    vm.updateReadingProgress(progress, for: book)
                                }) {
                                    Image(systemName: "plus")
                                        .frame(width: 36, height: 36)
                                        .background(Color(.systemGray5))
                                        .clipShape(Circle())
                                }
                                .disabled(progress >= 1)
                                
                                Spacer()
                                
                                Button(action: {
                                    progress = 1.0
                                    vm.updateReadingProgress(progress, for: book)
                                }) {
                                    Text("Mark as Read")
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.accentColor.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // User Notes
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(notes.isEmpty ? "Add Notes" : "Your Notes")
                                .font(.subheadline.bold())
                            
                            Spacer()
                            
                            if !notes.isEmpty {
                                Button(action: { showingNotesEditor = true }) {
                                    Text("Edit")
                                        .font(.subheadline)
                                }
                            }
                        }
                        
                        Divider()
                        
                        if notes.isEmpty {
                            Button(action: { showingNotesEditor = true }) {
                                Text("Add notes about this book...")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else {
                            Text(notes)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Description
                    if let description = book.description {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.subheadline.bold())
                            
                            Divider()
                            
                            Text(description)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.subheadline.bold())
                        
                        Divider()
                        
                        DetailRow(label: "Publisher", value: book.publisher ?? "Unknown")
                        DetailRow(label: "Published", value: book.publishedDate ?? "Unknown")
                        DetailRow(label: "Pages", value: book.pageCount != nil ? "\(book.pageCount!)" : "Unknown")
                        DetailRow(label: "Genre", value: book.genre)
                        DetailRow(label: "Status", value: book.status.displayName)
                        
                        if let dueDate = book.dueDate {
                            DetailRow(label: "Due Date", value: dueDate.formatted(.dateTime.day().month().year()))
                        }
                    }
                    
                    // Recommendations
                    if !vm.recommendations.isEmpty && vm.recommendations.first?.id != book.id {
                        BookSection(
                            title: "You Might Also Like",
                            books: vm.recommendations,
                            style: .small
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ActivityView(activityItems: [book.title, book.coverImageURL as Any].compactMap { $0 })
        }
        .sheet(isPresented: $showingNotesEditor) {
            NavigationStack {
                TextEditor(text: $notes)
                    .padding()
                    .navigationTitle("Your Notes")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingNotesEditor = false
                                notes = book.notes // Revert changes
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                vm.updateNotes(notes, for: book)
                                showingNotesEditor = false
                            }
                        }
                    }
            }
        }
        .confirmationDialog("Rate This Book", isPresented: $showingRatingDialog) {
            ForEach(1...5, id: \.self) { rating in
                Button("\(rating) star\(rating == 1 ? "" : "s")") {
                    userRating = rating
                    vm.updateUserRating(userRating, for: book)
                }
            }
            if userRating != nil {
                Button("Remove Rating", role: .destructive) {
                    userRating = nil
                    vm.updateUserRating(nil, for: book)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("How would you rate this book?")
        }
        .onAppear {
            vm.generateRecommendations(for: book)
            vm.updateOverdueStatuses()
            vm.addToRecent(book: book)
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var vm: LibraryViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Color Scheme", selection: $vm.appSettings.colorScheme) {
                        Text("Light").tag(AppSettings.ColorScheme.light)
                        Text("Dark").tag(AppSettings.ColorScheme.dark)
                        Text("System").tag(AppSettings.ColorScheme.system)
                    }
                    
                    Stepper("Font Size: \(Int(vm.appSettings.preferredFontSize))",
                           value: $vm.appSettings.preferredFontSize,
                           in: 14...24)
                    
                    Toggle("Show Reading Progress", isOn: $vm.appSettings.showReadingProgress)
                }
                
                Section("Reading Goals") {
                    Picker("Time Frame", selection: $vm.readingGoal.timeFrame) {
                        ForEach(ReadingGoal.TimeFrame.allCases, id: \.self) { timeFrame in
                            Text(timeFrame.displayName).tag(timeFrame)
                        }
                    }
                    
                    Stepper("Target: \(vm.readingGoal.target) books",
                           value: $vm.readingGoal.target,
                           in: 1...100)
                }
                
                Section("Account") {
                    Toggle("Enable Notifications", isOn: $vm.appSettings.notificationsEnabled)
                    Toggle("Sync with iCloud", isOn: $vm.appSettings.syncWithCloud)
                }
                
                Section {
                    Button("Export Library Data") {
                        // Export functionality would go here
                    }
                    
                    Button("Reset Reading Goal", role: .destructive) {
                        vm.resetReadingGoal()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Helper Views
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.subheadline)
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

