import Foundation

struct Note: Identifiable, Codable {
    let id = UUID()
    let title: String
    let content: String
    let timestamp: Date
}

struct HistoryRecord: Identifiable, Codable {
    let id = UUID()
    let keyword: String
    let content: String
    let timestamp: Date
}

struct WebImport: Identifiable, Codable {
    let id = UUID()
    let url: String
    let title: String
    let content: String
    let timestamp: Date
}

class HistoryManager {
    static let shared = HistoryManager()
    private let maxRecords = 100 // Limit number of records stored
    
    private let userDefaults = UserDefaults.standard
    private let historyKey = "historyRecords"
    private let noteKey = "noteRecords"
    private let webImportKey = "webImportRecords"
    
    // File manager for persistent storage
    private let fileManager = FileManager.default
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    private var notesDirectory: URL {
        let dir = documentsDirectory.appendingPathComponent("Notes", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    private var webImportsDirectory: URL {
        let dir = documentsDirectory.appendingPathComponent("WebImports", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    init() {
        // Migrate existing notes from UserDefaults to files if needed
        migrateNotesToFiles()
    }
    
    private func migrateNotesToFiles() {
        guard let data = userDefaults.data(forKey: noteKey),
              let oldNotes = try? JSONDecoder().decode([Note].self, from: data) else {
            return
        }
        
        for note in oldNotes {
            saveNoteToFile(note)
        }
        
        // Clear notes from UserDefaults after migration
        userDefaults.removeObject(forKey: noteKey)
    }
    
    func deleteAll() {
        // Delete history records
        userDefaults.removeObject(forKey: historyKey)
        
        // Delete all notes files
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: notesDirectory, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Error deleting notes: \(error)")
        }
        
        // Delete all web imports
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: webImportsDirectory, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Error deleting web imports: \(error)")
        }
    }
    
    func saveRecord(_ record: HistoryRecord) {
        var records = loadRecords()
        
        // Check if we already have this exact keyword in the last 24 hours
        let twentyFourHoursAgo = Date().addingTimeInterval(-86400)
        let hasDuplicate = records.contains { 
            $0.keyword.lowercased() == record.keyword.lowercased() && 
            $0.timestamp > twentyFourHoursAgo
        }
        
        if !hasDuplicate {
            records.append(record)
            
            // Limit the number of records
            if records.count > maxRecords {
                records = Array(records.suffix(maxRecords))
            }
            
            saveToUserDefaults(records, key: historyKey)
        }
    }
    
    func loadRecords() -> [HistoryRecord] {
        guard let data = userDefaults.data(forKey: historyKey) else { return [] }
        let decoder = JSONDecoder()
        return (try? decoder.decode([HistoryRecord].self, from: data)) ?? []
    }
    
    func deleteRecord(at index: Int) {
        var records = loadRecords()
        if index >= 0 && index < records.count {
            records.remove(at: index)
            saveToUserDefaults(records, key: historyKey)
        }
    }
    
    // MARK: - Notes File-based Storage
    
    func saveNote(_ note: Note) {
        saveNoteToFile(note)
    }
    
    private func saveNoteToFile(_ note: Note) {
        let noteFileURL = notesDirectory.appendingPathComponent("\(note.id.uuidString).json")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(note)
            try data.write(to: noteFileURL)
        } catch {
            print("Error saving note to file: \(error)")
        }
    }
    
    func loadNotes() -> [Note] {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: notesDirectory, includingPropertiesForKeys: nil)
            let jsonFiles = fileURLs.filter { $0.pathExtension == "json" }
            
            var notes: [Note] = []
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            for fileURL in jsonFiles {
                do {
                    let data = try Data(contentsOf: fileURL)
                    if let note = try? decoder.decode(Note.self, from: data) {
                        notes.append(note)
                    }
                } catch {
                    print("Error reading note file: \(error)")
                }
            }
            
            // Sort by timestamp, newest first
            return notes.sorted(by: { $0.timestamp > $1.timestamp })
        } catch {
            print("Error listing notes directory: \(error)")
            return []
        }
    }
    
    func deleteNote(withId id: UUID) {
        let noteFileURL = notesDirectory.appendingPathComponent("\(id.uuidString).json")
        
        do {
            try fileManager.removeItem(at: noteFileURL)
        } catch {
            print("Error deleting note file: \(error)")
        }
    }
    
    // MARK: - Web Imports Storage
    
    func saveWebImport(_ webImport: WebImport) {
        saveWebImportToFile(webImport)
    }
    
    private func saveWebImportToFile(_ webImport: WebImport) {
        let webImportFileURL = webImportsDirectory.appendingPathComponent("\(webImport.id.uuidString).json")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(webImport)
            try data.write(to: webImportFileURL)
        } catch {
            print("Error saving web import to file: \(error)")
        }
    }
    
    func loadWebImports() -> [WebImport] {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: webImportsDirectory, includingPropertiesForKeys: nil)
            let jsonFiles = fileURLs.filter { $0.pathExtension == "json" }
            
            var webImports: [WebImport] = []
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            for fileURL in jsonFiles {
                do {
                    let data = try Data(contentsOf: fileURL)
                    if let webImport = try? decoder.decode(WebImport.self, from: data) {
                        webImports.append(webImport)
                    }
                } catch {
                    print("Error reading web import file: \(error)")
                }
            }
            
            // Sort by timestamp, newest first
            return webImports.sorted(by: { $0.timestamp > $1.timestamp })
        } catch {
            print("Error listing web imports directory: \(error)")
            return []
        }
    }
    
    func deleteWebImport(withId id: UUID) {
        let webImportFileURL = webImportsDirectory.appendingPathComponent("\(id.uuidString).json")
        
        do {
            try fileManager.removeItem(at: webImportFileURL)
        } catch {
            print("Error deleting web import file: \(error)")
        }
    }
    
    private func saveToUserDefaults<T: Codable>(_ data: [T], key: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(data) {
            userDefaults.set(encoded, forKey: key)
            userDefaults.synchronize()
        }
    }
}
