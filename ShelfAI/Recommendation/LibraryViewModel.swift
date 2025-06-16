//
//  LibraryViewModel.swift
//  ShelfAI
//
//  Created by Krsna  on 5/25/25.
//

import Foundation
import Combine
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
    private var hmm: HiddenMarkovModel?
    
    
    // Generates home recommendations based on high-rated books not already in the user's library.
    func generateHomeRecommendations() {
        // Step 1: Filter out books already in the library
        let availableBooks = allBooks.filter { !$0.isInLibrary }
        
        // Step 2: Filter for books with an average rating of 4.0 or higher
        let highlyRatedBooks = availableBooks.filter { $0.averageRating ?? 0 >= 4.0 }
        
        // Step 3: Sort the books by rating in descending order
        let sortedBooks = highlyRatedBooks.sorted { ($0.averageRating ?? 0) > ($1.averageRating ?? 0) }
        
        // Step 4: Get the top 5 recommendations
        recommendations = Array(sortedBooks.prefix(5))
    }
    
    init() {
        loadInitialData()
        hmm = HiddenMarkovModel(states: ["Fantasy", "Science Fiction", "Mystery", "Romance"])
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
        let books = [
            Book(id: "1", title: "The Great Gatsby", authors: ["F. Scott Fitzgerald"], publisher: "Scribner", publishedDate: "1925", description: "A story of wealth, love, and the American Dream in the 1920s.", pageCount: 180, categories: ["Classic", "Literary Fiction"], averageRating: 4.2, openLibraryId: "823857", isInLibrary: true, userRating: 4),
            Book(id: "2", title: "To Kill a Mockingbird", authors: ["Harper Lee"], publisher: "J. B. Lippincott & Co.", publishedDate: "1960", description: "A powerful story of racial injustice and moral growth.", pageCount: 281, categories: ["Classic", "Literary Fiction"], averageRating: 4.7, openLibraryId: "823856", status: .checkedOut, dueDate: Date().addingTimeInterval(86400 * 7)),
            Book(id: "3", title: "1984", authors: ["George Orwell"], publisher: "Secker & Warburg", publishedDate: "1949", description: "A dystopian novel about totalitarianism and surveillance.", pageCount: 328, categories: ["Dystopian", "Science Fiction"], averageRating: 4.5, openLibraryId: "823855", readingProgress: 0.3, lastReadDate: Date().addingTimeInterval(-86400)),
            Book(id: "4", title: "Pride and Prejudice", authors: ["Jane Austen"], publisher: "T. Egerton, Whitehall", publishedDate: "1813", description: "A romantic novel about the Bennet family.", pageCount: 279, categories: ["Romance", "Classic"], averageRating: 4.6, openLibraryId: "823853", isRead: true),
            Book(id: "5", title: "The Hobbit", authors: ["J.R.R. Tolkien"], publisher: "Allen & Unwin", publishedDate: "1937", description: "A fantasy novel and prelude to The Lord of the Rings.", pageCount: 310, categories: ["Fantasy", "Adventure"], averageRating: 4.7, openLibraryId: "823821", isInLibrary: true),
            Book(id: "6", title: "Dune", authors: ["Frank Herbert"], publisher: "Chilton Books", publishedDate: "1965", description: "A science fiction epic about politics and ecology.", pageCount: 412, categories: ["Science Fiction"], averageRating: 4.8, openLibraryId: "823840", status: .checkedOut, dueDate: Date().addingTimeInterval(86400 * 3)),
            Book(id: "7", title: "The Hunger Games", authors: ["Suzanne Collins"], publisher: "Scholastic", publishedDate: "2008", description: "A dystopian novel about a televised fight to the death.", pageCount: 374, categories: ["Young Adult", "Dystopian"], averageRating: 4.3, openLibraryId: "823765", isInLibrary: true),
            Book(id: "8", title: "The Shining", authors: ["Stephen King"], publisher: "Doubleday", publishedDate: "1977", description: "A psychological horror novel about a haunted hotel.", pageCount: 447, categories: ["Horror"], averageRating: 4.3, openLibraryId: "823785", isRead: true),
            Book(id: "9", title: "The Silent Patient", authors: ["Alex Michaelides"], publisher: "Celadon Books", publishedDate: "2019", description: "A psychological thriller about a woman who shoots her husband.", pageCount: 323, categories: ["Thriller", "Mystery"], averageRating: 4.2, openLibraryId: "823808"),
            Book(id: "10", title: "Where the Crawdads Sing", authors: ["Delia Owens"], publisher: "G.P. Putnam's Sons", publishedDate: "2018", description: "A novel about an abandoned girl who raises herself in the marshes.", pageCount: 368, categories: ["Literary Fiction", "Mystery"], averageRating: 4.8, openLibraryId: "823807"),
            Book(id: "11", title: "The Name of the Wind", authors: ["Patrick Rothfuss"], publisher: "DAW Books", publishedDate: "2007", description: "The first book in the Kingkiller Chronicle series.", pageCount: 662, categories: ["Fantasy"], averageRating: 4.5, openLibraryId: "823800"),
            Book(id: "12", title: "Neuromancer", authors: ["William Gibson"], publisher: "Ace", publishedDate: "1984", description: "A seminal cyberpunk novel.", pageCount: 271, categories: ["Science Fiction"], averageRating: 4.0, openLibraryId: "823801"),
            Book(id: "13", title: "The Girl with the Dragon Tattoo", authors: ["Stieg Larsson"], publisher: "Norstedts Förlag", publishedDate: "2005", description: "A mystery thriller featuring a journalist and a hacker.", pageCount: 465, categories: ["Mystery", "Thriller"], averageRating: 4.1, openLibraryId: "823802"),
            Book(id: "14", title: "Outlander", authors: ["Diana Gabaldon"], publisher: "Delacorte Press", publishedDate: "1991", description: "A historical romance involving time travel.", pageCount: 642, categories: ["Romance", "Historical Fiction"], averageRating: 4.6, openLibraryId: "823803"),
            Book(id: "15", title: "The Night Circus", authors: ["Erin Morgenstern"], publisher: "Doubleday", publishedDate: "2011", description: "A fantasy novel about a magical competition.", pageCount: 387, categories: ["Fantasy"], averageRating: 4.3, openLibraryId: "823804"),
            Book(id: "16", title: "Fahrenheit 451", authors: ["Ray Bradbury"], publisher: "Ballantine Books", publishedDate: "1953", description: "A dystopian novel about a future where books are banned.", pageCount: 158, categories: ["Science Fiction"], averageRating: 4.4, openLibraryId: "823805"),
            Book(id: "17", title: "The Da Vinci Code", authors: ["Dan Brown"], publisher: "Doubleday", publishedDate: "2003", description: "A mystery thriller involving a symbologist and a murder.", pageCount: 489, categories: ["Mystery", "Thriller"], averageRating: 3.9, openLibraryId: "823806"),
            Book(id: "18", title: "Me Before You", authors: ["Jojo Moyes"], publisher: "Penguin Books", publishedDate: "2012", description: "A romantic story about an unexpected relationship.", pageCount: 369, categories: ["Romance"], averageRating: 4.3, openLibraryId: "823807"),
            Book(id: "19", title: "Good Omens", authors: ["Neil Gaiman", "Terry Pratchett"], publisher: "Gollancz", publishedDate: "1990", description: "A comedic tale about the apocalypse.", pageCount: 288, categories: ["Fantasy", "Humor"], averageRating: 4.5, openLibraryId: "823808"),
            Book(id: "20", title: "The Hitchhiker's Guide to the Galaxy", authors: ["Douglas Adams"], publisher: "Pan Books", publishedDate: "1979", description: "A comedic science fiction series starter.", pageCount: 224, categories: ["Science Fiction", "Comedy"], averageRating: 4.2, openLibraryId: "823809"),
            // Continue adding more books until reaching 100
            Book(id: "21", title: "The Fault in Our Stars", authors: ["John Green"], publisher: "Dutton Books", publishedDate: "2012", description: "A poignant romance about two teens with cancer.", pageCount: 313, categories: ["Romance", "Young Adult"], averageRating: 4.2, openLibraryId: "823810"),
            Book(id: "22", title: "The Ocean at the End of the Lane", authors: ["Neil Gaiman"], publisher: "William Morrow", publishedDate: "2013", description: "A blend of fantasy and horror.", pageCount: 181, categories: ["Fantasy", "Horror"], averageRating: 4.0, openLibraryId: "823811"),
            Book(id: "23", title: "The Secret History", authors: ["Donna Tartt"], publisher: "Knopf", publishedDate: "1992", description: "A psychological thriller about a group of students.", pageCount: 559, categories: ["Mystery", "Thriller"], averageRating: 4.2, openLibraryId: "823812"),
            Book(id: "24", title: "The Time Traveler's Wife", authors: ["Audrey Niffenegger"], publisher: "MacAdam Cage", publishedDate: "2003", description: "A love story that transcends time.", pageCount: 546, categories: ["Romance", "Science Fiction"], averageRating: 4.0, openLibraryId: "823813"),
            Book(id: "25", title: "American Gods", authors: ["Neil Gaiman"], publisher: "William Morrow", publishedDate: "2001", description: "A modern fantasy exploring myth and belief.", pageCount: 465, categories: ["Fantasy"], averageRating: 4.2, openLibraryId: "823814"),
            Book(id: "26", title: "Brave New World", authors: ["Aldous Huxley"], publisher: "Chatto & Windus", publishedDate: "1932", description: "A dystopian novel about a technologically advanced future.", pageCount: 311, categories: ["Science Fiction"], averageRating: 4.0, openLibraryId: "823815"),
            Book(id: "27", title: "Big Little Lies", authors: ["Liane Moriarty"], publisher: "Penguin Books", publishedDate: "2014", description: "A mystery revolving around a murder at a school.", pageCount: 460, categories: ["Mystery", "Fiction"], averageRating: 4.2, openLibraryId: "823816"),
            Book(id: "28", title: "The Rosie Project", authors: ["Graeme Simsion"], publisher: "Text Publishing", publishedDate: "2013", description: "A romantic comedy about an unusual professor.", pageCount: 295, categories: ["Romance", "Comedy"], averageRating: 4.1, openLibraryId: "823817"),
            Book(id: "29", title: "The Night Circus", authors: ["Erin Morgenstern"], publisher: "Doubleday", publishedDate: "2011", description: "A fantasy novel about a magical competition.", pageCount: 387, categories: ["Fantasy"], averageRating: 4.3, openLibraryId: "823818"),
            Book(id: "30", title: "The Martian", authors: ["Andy Weir"], publisher: "Crown Publishing Group", publishedDate: "2011", description: "A science fiction novel about an astronaut stranded on Mars.", pageCount: 369, categories: ["Science Fiction"], averageRating: 4.6, openLibraryId: "823819"),
            Book(id: "31", title: "The Woman in the Window", authors: ["A.J. Finn"], publisher: "William Morrow", publishedDate: "2018", description: "A psychological thriller about an agoraphobic woman.", pageCount: 427, categories: ["Mystery", "Thriller"], averageRating: 4.1, openLibraryId: "823820"),
            Book(id: "32", title: "A Court of Thorns and Roses", authors: ["Sarah J. Maas"], publisher: "Bloomsbury Publishing", publishedDate: "2015", description: "A fantasy romance inspired by Beauty and the Beast.", pageCount: 432, categories: ["Fantasy", "Romance"], averageRating: 4.2, openLibraryId: "823821"),
            Book(id: "33", title: "The Couple Next Door", authors: ["Shari Lapena"], publisher: "Pamela Dorman Books", publishedDate: "2016", description: "A domestic thriller about a missing child.", pageCount: 320, categories: ["Mystery", "Thriller"], averageRating: 4.0, openLibraryId: "823822"),
            Book(id: "34", title: "Beach Read", authors: ["Emily Henry"], publisher: "Berkley", publishedDate: "2020", description: "A romance between two writers with different styles.", pageCount: 368, categories: ["Romance"], averageRating: 4.3, openLibraryId: "823823"),
            Book(id: "35", title: "Circe", authors: ["Madeline Miller"], publisher: "Little, Brown and Company", publishedDate: "2018", description: "A retelling of the story of Circe, a figure from Greek mythology.", pageCount: 400, categories: ["Fantasy"], averageRating: 4.4, openLibraryId: "823824"),
            Book(id: "36", title: "The Invisible Man", authors: ["H.G. Wells"], publisher: "C. Arthur Pearson", publishedDate: "1897", description: "A science fiction novel about a scientist who becomes invisible.", pageCount: 125, categories: ["Science Fiction"], averageRating: 4.0, openLibraryId: "823825"),
            Book(id: "37", title: "The Guest List", authors: ["Lucy Foley"], publisher: "William Morrow", publishedDate: "2020", description: "A mystery thriller set at a wedding on a remote island.", pageCount: 368, categories: ["Mystery", "Thriller"], averageRating: 4.1, openLibraryId: "823826"),
            Book(id: "38", title: "Red, White & Royal Blue", authors: ["Casey McQuiston"], publisher: "St. Martin's Griffin", publishedDate: "2019", description: "A romantic comedy about the son of the U.S. President.", pageCount: 421, categories: ["Romance", "LGBTQ+"], averageRating: 4.4, openLibraryId: "823827"),
            Book(id: "39", title: "The Priory of the Orange Tree", authors: ["Samantha Shannon"], publisher: "Bloomsbury Publishing", publishedDate: "2019", description: "A high fantasy novel featuring dragons and political intrigue.", pageCount: 848, categories: ["Fantasy"], averageRating: 4.4, openLibraryId: "823828"),
            Book(id: "40", title: "Foundation", authors: ["Isaac Asimov"], publisher: "Gnome Press", publishedDate: "1951", description: "A science fiction series about the fall and rise of a galactic empire.", pageCount: 255, categories: ["Science Fiction"], averageRating: 4.3, openLibraryId: "823829"),
            Book(id: "41", title: "The Woman in Cabin 10", authors: ["Ruth Ware"], publisher: "Scout Press", publishedDate: "2016", description: "A psychological thriller about a cruise ship murder.", pageCount: 384, categories: ["Mystery", "Thriller"], averageRating: 4.1, openLibraryId: "823830"),
            Book(id: "42", title: "It Ends with Us", authors: ["Colleen Hoover"], publisher: "Atria Books", publishedDate: "2016", description: "A romance that tackles complex themes of love and relationships.", pageCount: 384, categories: ["Romance"], averageRating: 4.4, openLibraryId: "823831"),
            Book(id: "43", title: "The Bone Season", authors: ["Samantha Shannon"], publisher: "Bloomsbury Publishing", publishedDate: "2013", description: "A fantasy novel set in a dystopian future.", pageCount: 480, categories: ["Fantasy", "Dystopian"], averageRating: 4.2, openLibraryId: "823832"),
            Book(id: "44", title: "Altered Carbon", authors: ["Richard K. Morgan"], publisher: "Gollancz", publishedDate: "2002", description: "A science fiction novel about consciousness and identity.", pageCount: 544, categories: ["Science Fiction"], averageRating: 4.0, openLibraryId: "823833"),
            Book(id: "45", title: "The Cuckoo's Calling", authors: ["Robert Galbraith"], publisher: "Mulholland Books", publishedDate: "2013", description: "A mystery novel featuring a private detective.", pageCount: 464, categories: ["Mystery", "Thriller"], averageRating: 4.2, openLibraryId: "823834"),
            Book(id: "46", title: "The Kiss Quotient", authors: ["Helen Hoang"], publisher: "Berkley", publishedDate: "2018", description: "A romance featuring an autistic woman and a male escort.", pageCount: 336, categories: ["Romance"], averageRating: 4.3, openLibraryId: "823835"),
            Book(id: "47", title: "The City We Became", authors: ["N.K. Jemisin"], publisher: "Orbit", publishedDate: "2020", description: "A fantasy novel about the personification of New York City.", pageCount: 448, categories: ["Fantasy"], averageRating: 4.2, openLibraryId: "823836"),
            Book(id: "48", title: "The Time Machine", authors: ["H.G. Wells"], publisher: "William Heinemann", publishedDate: "1895", description: "A science fiction novel about time travel.", pageCount: 118, categories: ["Science Fiction"], averageRating: 4.1, openLibraryId: "823837"),
            Book(id: "49", title: "The Lying Game", authors: ["Ruth Ware"], publisher: "Gallery/Scout Press", publishedDate: "2017", description: "A mystery thriller about a group of friends with a dark secret.", pageCount: 368, categories: ["Mystery", "Thriller"], averageRating: 4.0, openLibraryId: "823838"),
            Book(id: "50", title: "Beach House", authors: ["Mary Alice Monroe"], publisher: "Mira Books", publishedDate: "2008", description: "A romance set in a beach house.", pageCount: 368, categories: ["Romance"], averageRating: 4.2, openLibraryId: "823839"),
            Book(id: "51", title: "The Name of the Wind", authors: ["Patrick Rothfuss"], publisher: "DAW Books", publishedDate: "2007", description: "The first book in the Kingkiller Chronicle series.", pageCount: 662, categories: ["Fantasy"], averageRating: 4.5, openLibraryId: "823840"),
            Book(id: "52", title: "The Hitchhiker's Guide to the Galaxy", authors: ["Douglas Adams"], publisher: "Pan Books", publishedDate: "1979", description: "A comedic science fiction series starter.", pageCount: 224, categories: ["Science Fiction", "Comedy"], averageRating: 4.2, openLibraryId: "823841"),
            Book(id: "53", title: "The Secret History", authors: ["Donna Tartt"], publisher: "Knopf", publishedDate: "1992", description: "A psychological thriller about a group of students.", pageCount: 559, categories: ["Mystery", "Thriller"], averageRating: 4.2, openLibraryId: "823842"),
            Book(id: "54", title: "The Night Circus", authors: ["Erin Morgenstern"], publisher: "Doubleday", publishedDate: "2011", description: "A fantasy novel about a magical competition.", pageCount: 387, categories: ["Fantasy"], averageRating: 4.3, openLibraryId: "823843"),
            Book(id: "55", title: "The Martian", authors: ["Andy Weir"], publisher: "Crown Publishing Group", publishedDate: "2011", description: "A science fiction novel about an astronaut stranded on Mars.", pageCount: 369, categories: ["Science Fiction"], averageRating: 4.6, openLibraryId: "823844"),
            Book(id: "56", title: "The Woman in the Window", authors: ["A.J. Finn"], publisher: "William Morrow", publishedDate: "2018", description: "A psychological thriller about an agoraphobic woman.", pageCount: 427, categories: ["Mystery", "Thriller"], averageRating: 4.1, openLibraryId: "823845"),
            Book(id: "57", title: "It Ends with Us", authors: ["Colleen Hoover"], publisher: "Atria Books", publishedDate: "2016", description: "A romance that tackles complex themes of love and relationships.", pageCount: 384, categories: ["Romance"], averageRating: 4.4, openLibraryId: "823846"),
            Book(id: "58", title: "The Bone Season", authors: ["Samantha Shannon"], publisher: "Bloomsbury Publishing", publishedDate: "2013", description: "A fantasy novel set in a dystopian future.", pageCount: 480, categories: ["Fantasy", "Dystopian"], averageRating: 4.2, openLibraryId: "823847"),
            Book(id: "59", title: "Altered Carbon", authors: ["Richard K. Morgan"], publisher: "Gollancz", publishedDate: "2002", description: "A science fiction novel about consciousness and identity.", pageCount: 544, categories: ["Science Fiction"], averageRating: 4.0, openLibraryId: "823848"),
            Book(id: "60", title: "The Cuckoo's Calling", authors: ["Robert Galbraith"], publisher: "Mulholland Books", publishedDate: "2013", description: "A mystery novel featuring a private detective.", pageCount: 464, categories: ["Mystery", "Thriller"], averageRating: 4.2, openLibraryId: "823849"),
            Book(id: "61", title: "The Kiss Quotient", authors: ["Helen Hoang"], publisher: "Berkley", publishedDate: "2018", description: "A romance featuring an autistic woman and a male escort.", pageCount: 336, categories: ["Romance"], averageRating: 4.3, openLibraryId: "823850"),
            Book(id: "62", title: "The City We Became", authors: ["N.K. Jemisin"], publisher: "Orbit", publishedDate: "2020", description: "A fantasy novel about the personification of New York City.", pageCount: 448, categories: ["Fantasy"], averageRating: 4.2, openLibraryId: "823851"),
            Book(id: "63", title: "The Time Machine", authors: ["H.G. Wells"], publisher: "William Heinemann", publishedDate: "1895", description: "A science fiction novel about time travel.", pageCount: 118, categories: ["Science Fiction"], averageRating: 4.1, openLibraryId: "823852"),
            Book(id: "64", title: "The Lying Game", authors: ["Ruth Ware"], publisher: "Gallery/Scout Press", publishedDate: "2017", description: "A mystery thriller about a group of friends with a dark secret.", pageCount: 368, categories: ["Mystery", "Thriller"], averageRating: 4.0, openLibraryId: "823853"),
            Book(id: "65", title: "Beach House", authors: ["Mary Alice Monroe"], publisher: "Mira Books", publishedDate: "2008", description: "A romance set in a beach house.", pageCount: 368, categories: ["Romance"], averageRating: 4.2, openLibraryId: "823854"),
            Book(id: "66", title: "The Name of the Wind", authors: ["Patrick Rothfuss"], publisher: "DAW Books", publishedDate: "2007", description: "The first book in the Kingkiller Chronicle series.", pageCount: 662, categories: ["Fantasy"], averageRating: 4.5, openLibraryId: "823855"),
            Book(id: "67", title: "The Hitchhiker's Guide to the Galaxy", authors: ["Douglas Adams"], publisher: "Pan Books", publishedDate: "1979", description: "A comedic science fiction series starter.", pageCount: 224, categories: ["Science Fiction", "Comedy"], averageRating: 4.2, openLibraryId: "823856"),
            Book(id: "68", title: "The Secret History", authors: ["Donna Tartt"], publisher: "Knopf", publishedDate: "1992", description: "A psychological thriller about a group of students.", pageCount: 559, categories: ["Mystery", "Thriller"], averageRating: 4.2, openLibraryId: "823857"),
            Book(id: "69", title: "The Night Circus", authors: ["Erin Morgenstern"], publisher: "Doubleday", publishedDate: "2011", description: "A fantasy novel about a magical competition.", pageCount: 387, categories: ["Fantasy"], averageRating: 4.3, openLibraryId: "823858"),
            Book(id: "70", title: "The Martian", authors: ["Andy Weir"], publisher: "Crown Publishing Group", publishedDate: "2011", description: "A science fiction novel about an astronaut stranded on Mars.", pageCount: 369, categories: ["Science Fiction"], averageRating: 4.6, openLibraryId: "823859"),
            Book(id: "71", title: "The Woman in the Window", authors: ["A.J. Finn"], publisher: "William Morrow", publishedDate: "2018", description: "A psychological thriller about an agoraphobic woman.", pageCount: 427, categories: ["Mystery", "Thriller"], averageRating: 4.1, openLibraryId: "823860"),
            Book(id: "72", title: "It Ends with Us", authors: ["Colleen Hoover"], publisher: "Atria Books", publishedDate: "2016", description: "A romance that tackles complex themes of love and relationships.", pageCount: 384, categories: ["Romance"], averageRating: 4.4, openLibraryId: "823861"),
            Book(id: "73", title: "The Bone Season", authors: ["Samantha Shannon"], publisher: "Bloomsbury Publishing", publishedDate: "2013", description: "A fantasy novel set in a dystopian future.", pageCount: 480, categories: ["Fantasy", "Dystopian"], averageRating: 4.2, openLibraryId: "823862"),
            Book(id: "74", title: "Altered Carbon", authors: ["Richard K. Morgan"], publisher: "Gollancz", publishedDate: "2002", description: "A science fiction novel about consciousness and identity.", pageCount: 544, categories: ["Science Fiction"], averageRating: 4.0, openLibraryId: "823863"),
            Book(id: "75", title: "The Cuckoo's Calling", authors: ["Robert Galbraith"], publisher: "Mulholland Books", publishedDate: "2013", description: "A mystery novel featuring a private detective.", pageCount: 464, categories: ["Mystery", "Thriller"], averageRating: 4.2, openLibraryId: "823864"),
            Book(id: "76", title: "The Kiss Quotient", authors: ["Helen Hoang"], publisher: "Berkley", publishedDate: "2018", description: "A romance featuring an autistic woman and a male escort.", pageCount: 336, categories: ["Romance"], averageRating: 4.3, openLibraryId: "823865"),
            Book(id: "77", title: "The City We Became", authors: ["N.K. Jemisin"], publisher: "Orbit", publishedDate: "2020", description: "A fantasy novel about the personification of New York City.", pageCount: 448, categories: ["Fantasy"], averageRating: 4.2, openLibraryId: "823866"),
            Book(id: "78", title: "The Time Machine", authors: ["H.G. Wells"], publisher: "William Heinemann", publishedDate: "1895", description: "A science fiction novel about time travel.", pageCount: 118, categories: ["Science Fiction"], averageRating: 4.1, openLibraryId: "823867"),
            Book(id: "79", title: "The Lying Game", authors: ["Ruth Ware"], publisher: "Gallery/Scout Press", publishedDate: "2017", description: "A mystery thriller about a group of friends with a dark secret.", pageCount: 368, categories: ["Mystery", "Thriller"], averageRating: 4.0, openLibraryId: "823868"),
            Book(id: "80", title: "Beach House", authors: ["Mary Alice Monroe"], publisher: "Mira Books", publishedDate: "2008", description: "A romance set in a beach house.", pageCount: 368, categories: ["Romance"], averageRating: 4.2, openLibraryId: "823869"),
            Book(id: "81", title: "The Name of the Wind", authors: ["Patrick Rothfuss"], publisher: "DAW Books", publishedDate: "2007", description: "The first book in the Kingkiller Chronicle series.", pageCount: 662, categories: ["Fantasy"], averageRating: 4.5, openLibraryId: "823870"),
            Book(id: "82", title: "The Hitchhiker's Guide to the Galaxy", authors: ["Douglas Adams"], publisher: "Pan Books", publishedDate: "1979", description: "A comedic science fiction series starter.", pageCount: 224, categories: ["Science Fiction", "Comedy"], averageRating: 4.2, openLibraryId: "823871"),
            Book(id: "83", title: "The Secret History", authors: ["Donna Tartt"], publisher: "Knopf", publishedDate: "1992", description: "A psychological thriller about a group of students.", pageCount: 559, categories: ["Mystery", "Thriller"], averageRating: 4.2, openLibraryId: "823872"),
            Book(id: "84", title: "The Night Circus", authors: ["Erin Morgenstern"], publisher: "Doubleday", publishedDate: "2011", description: "A fantasy novel about a magical competition.", pageCount: 387, categories: ["Fantasy"], averageRating: 4.3, openLibraryId: "823873"),
            Book(id: "85", title: "The Martian", authors: ["Andy Weir"], publisher: "Crown Publishing Group", publishedDate: "2011", description: "A science fiction novel about an astronaut stranded on Mars.", pageCount: 369, categories: ["Science Fiction"], averageRating: 4.6, openLibraryId: "823874"),
            Book(id: "86", title: "The Woman in the Window", authors: ["A.J. Finn"], publisher: "William Morrow", publishedDate: "2018", description: "A psychological thriller about an agoraphobic woman.", pageCount: 427, categories: ["Mystery", "Thriller"], averageRating: 4.1, openLibraryId: "823875"),
            Book(id: "87", title: "It Ends with Us", authors: ["Colleen Hoover"], publisher: "Atria Books", publishedDate: "2016", description: "A romance that tackles complex themes of love and relationships.", pageCount: 384, categories: ["Romance"], averageRating: 4.4, openLibraryId: "823876"),
            Book(id: "88", title: "The Bone Season", authors: ["Samantha Shannon"], publisher: "Bloomsbury Publishing", publishedDate: "2013", description: "A fantasy novel set in a dystopian future.", pageCount: 480, categories: ["Fantasy", "Dystopian"], averageRating: 4.2, openLibraryId: "823877"),
            Book(id: "89", title: "Altered Carbon", authors: ["Richard K. Morgan"], publisher: "Gollancz", publishedDate: "2002", description: "A science fiction novel about consciousness and identity.", pageCount: 544, categories: ["Science Fiction"], averageRating: 4.0, openLibraryId: "823878"),
            Book(id: "90", title: "The Cuckoo's Calling", authors: ["Robert Galbraith"], publisher: "Mulholland Books", publishedDate: "2013", description: "A mystery novel featuring a private detective.", pageCount: 464, categories: ["Mystery", "Thriller"], averageRating: 4.2, openLibraryId: "823879"),
            Book(id: "91", title: "The Kiss Quotient", authors: ["Helen Hoang"], publisher: "Berkley", publishedDate: "2018", description: "A romance featuring an autistic woman and a male escort.", pageCount: 336, categories: ["Romance"], averageRating: 4.3, openLibraryId: "823880"),
            Book(id: "92", title: "The City We Became", authors: ["N.K. Jemisin"], publisher: "Orbit", publishedDate: "2020", description: "A fantasy novel about the personification of New York City.", pageCount: 448, categories: ["Fantasy"], averageRating: 4.2, openLibraryId: "823881"),
            Book(id: "93", title: "The Time Machine", authors: ["H.G. Wells"], publisher: "William Heinemann", publishedDate: "1895", description: "A science fiction novel about time travel.", pageCount: 118, categories: ["Science Fiction"], averageRating: 4.1, openLibraryId: "823882"),
            Book(id: "94", title: "The Lying Game", authors: ["Ruth Ware"], publisher: "Gallery/Scout Press", publishedDate: "2017", description: "A mystery thriller about a group of friends with a dark secret.", pageCount: 368, categories: ["Mystery", "Thriller"], averageRating: 4.0, openLibraryId: "823883"),
            Book(id: "95", title: "Beach House", authors: ["Mary Alice Monroe"], publisher: "Mira Books", publishedDate: "2008", description: "A romance set in a beach house.", pageCount: 368, categories: ["Romance"], averageRating: 4.2, openLibraryId: "823884"),
            Book(id: "96", title: "The Name of the Wind", authors: ["Patrick Rothfuss"], publisher: "DAW Books", publishedDate: "2007", description: "The first book in the Kingkiller Chronicle series.", pageCount: 662, categories: ["Fantasy"], averageRating: 4.5, openLibraryId: "823885"),
            Book(id: "97", title: "The Hitchhiker's Guide to the Galaxy", authors: ["Douglas Adams"], publisher: "Pan Books", publishedDate: "1979", description: "A comedic science fiction series starter.", pageCount: 224, categories: ["Science Fiction", "Comedy"], averageRating: 4.2, openLibraryId: "823886"),
            Book(id: "98", title: "The Secret History", authors: ["Donna Tartt"], publisher: "Knopf", publishedDate: "1992", description: "A psychological thriller about a group of students.", pageCount: 559, categories: ["Mystery", "Thriller"], averageRating: 4.2, openLibraryId: "823887"),
            Book(id: "99", title: "The Night Circus", authors: ["Erin Morgenstern"], publisher: "Doubleday", publishedDate: "2011", description: "A fantasy novel about a magical competition.", pageCount: 387, categories: ["Fantasy"], averageRating: 4.3, openLibraryId: "823888"),
            Book(id: "100", title: "The Martian", authors: ["Andy Weir"], publisher: "Crown Publishing Group", publishedDate: "2011", description: "A science fiction novel about an astronaut stranded on Mars.", pageCount: 369, categories: ["Science Fiction"], averageRating: 4.6, openLibraryId: "823889")
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
    
    //        func generateHomeRecommendations() {
    //            recommendations = allBooks
    //                .filter { !$0.isInLibrary && $0.rating >= 4.0 }
    //                .sorted { $0.rating > $1.rating }
    //                .prefix(5)
    //                .map { $0 }
    //        }
    
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
