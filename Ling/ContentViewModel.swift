import Foundation
import Combine
import SwiftUI

// We don't need to redefine WebImport here as it's already defined in HistoryManager.swift
// Removing duplicate definition to avoid conflicts

class ContentViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var filterResult = ""
    @Published var historyRecords: [HistoryRecord] = []
    @Published var isShowingSettings = false
    @Published var apiKey = UserDefaults.standard.string(forKey: "openAIAPIKey") ?? ""
    @Published var isSearching = false
    @Published var notes: [Note] = []
    @Published var selectedNoteIds: Set<UUID> = []
    @Published var webImports: [WebImport] = []
    @Published var selectedWebImportIds: Set<UUID> = []
    @Published var isShowingNoteSelector = false
    @Published var isShowingWebImporter = false
    @Published var isShowingWebImportDetail = false
    @Published var currentWebImportURL = ""
    @Published var currentWebImportTitle = ""
    @Published var currentWebImportContent = ""
    @Published var isImportingWebContent = false
    @Published var webImportError: String? = nil
    @Published var viewMode: Int = 0 // 0:历史记录, 1:过滤结果, 2:笔记, 3:网页
    @Published var isShowingNoteEditor = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private let historyManager = HistoryManager.shared
    private let llmService = LLMService.shared
    
    init() {
        loadHistory()
        loadNotes()
        loadWebImports()
    }
    
    func loadHistory() {
        historyRecords = historyManager.loadRecords()
    }
    
    func loadNotes() {
        notes = historyManager.loadNotes()
    }
    
    func loadWebImports() {
        webImports = historyManager.loadWebImports()
    }
    
    func deleteRecord(at index: Int) {
        historyManager.deleteRecord(at: index)
        loadHistory()
    }
    
    func deleteNote(withId id: UUID) {
        historyManager.deleteNote(withId: id)
        selectedNoteIds.remove(id)
        loadNotes()
    }
    
    func deleteWebImport(withId id: UUID) {
        historyManager.deleteWebImport(withId: id)
        selectedWebImportIds.remove(id)
        loadWebImports()
    }
    
    func deleteAll() {
        historyManager.deleteAll()
        loadHistory()
        loadNotes()
        loadWebImports()
        selectedNoteIds.removeAll()
        selectedWebImportIds.removeAll()
    }
    
    func toggleNoteSelection(noteId: UUID) {
        if selectedNoteIds.contains(noteId) {
            selectedNoteIds.remove(noteId)
        } else {
            selectedNoteIds.insert(noteId)
        }
    }
    
    func toggleWebImportSelection(id: UUID) {
        if selectedWebImportIds.contains(id) {
            selectedWebImportIds.remove(id)
        } else {
            selectedWebImportIds.insert(id)
        }
    }
    
    func clearSelections() {
        selectedNoteIds.removeAll()
        selectedWebImportIds.removeAll()
    }
    
    func saveAPIKey() {
        UserDefaults.standard.set(apiKey, forKey: "openAIAPIKey")
    }
    
    func performFilter() {
        guard !searchText.isEmpty else {
            filterResult = ""
            return
        }
        
        isSearching = true
        
        // Build context from selected notes and web imports
        var context = ""
        
        // Add selected notes to context
        let selectedNotes = notes.filter { selectedNoteIds.contains($0.id) }
        if !selectedNotes.isEmpty {
            context += "参考笔记:\n"
            for note in selectedNotes {
                context += "---\n标题: \(note.title)\n内容: \(note.content)\n---\n"
            }
        }
        
        // Add selected web imports to context
        let selectedWebImports = webImports.filter { selectedWebImportIds.contains($0.id) }
        if !selectedWebImports.isEmpty {
            context += "参考网页:\n"
            for webImport in selectedWebImports {
                context += "---\n标题: \(webImport.title)\n内容: \(webImport.content)\n---\n"
            }
        }
        
        // Append the search text if we have context
        var prompt = searchText
        if !context.isEmpty {
            prompt = "\(context)\n基于以上内容，回答以下问题：\n\(searchText)"
        }
        
        // Call LLM service
        llmService.performQuery(prompt: prompt) { [weak self] result in
            DispatchQueue.main.async {
                self?.isSearching = false
                
                switch result {
                case .success(let response):
                    self?.filterResult = response
                    
                    // Save the history record
                    let record = HistoryRecord(
                        keyword: self?.searchText ?? "",
                        content: response,
                        timestamp: Date()
                    )
                    self?.historyManager.saveRecord(record)
                    self?.loadHistory()
                    
                    // If there were selected notes or web imports, also save this as a new note
                    if !(self?.selectedNoteIds.isEmpty ?? true) || !(self?.selectedWebImportIds.isEmpty ?? true) {
                        let sourceInfo = self?.buildSourceInfo() ?? ""
                        let newNote = Note(
                            title: self?.searchText ?? "查询结果",
                            content: response + "\n\n" + sourceInfo,
                            timestamp: Date()
                        )
                        self?.historyManager.saveNote(newNote)
                        self?.loadNotes()
                    }
                    
                case .failure(let error):
                    self?.filterResult = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func buildSourceInfo() -> String {
        var sourceInfo = "来源: "
        
        // Add note references
        let selectedNotes = notes.filter { selectedNoteIds.contains($0.id) }
        if !selectedNotes.isEmpty {
            sourceInfo += "\n笔记: "
            for note in selectedNotes {
                sourceInfo += "\n- \(note.title)"
            }
        }
        
        // Add web import references
        let selectedWebImports = webImports.filter { selectedWebImportIds.contains($0.id) }
        if !selectedWebImports.isEmpty {
            sourceInfo += "\n网页: "
            for webImport in selectedWebImports {
                sourceInfo += "\n- \(webImport.title) (\(webImport.url))"
            }
        }
        
        return sourceInfo
    }
    
    func saveNote(title: String, content: String) {
        let note = Note(title: title, content: content, timestamp: Date())
        historyManager.saveNote(note)
        loadNotes()
    }
    
    func saveWebImport(url: String, title: String, content: String) {
        let webImport = WebImport(url: url, title: title, content: content, timestamp: Date())
        historyManager.saveWebImport(webImport)
        loadWebImports()
    }
    
    func importWebContent() {
        guard !currentWebImportURL.isEmpty else {
            webImportError = "URL不能为空"
            return
        }
        
        guard let url = URL(string: currentWebImportURL) else {
            webImportError = "无效的URL"
            return
        }
        
        isImportingWebContent = true
        webImportError = nil
        
        // If no title is provided, use the URL as the temporary title
        let importTitle = currentWebImportTitle.isEmpty ? currentWebImportURL : currentWebImportTitle
        
        // Fetch web content
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isImportingWebContent = false
                
                if let error = error {
                    self?.webImportError = "导入失败: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data, let htmlString = String(data: data, encoding: .utf8) else {
                    self?.webImportError = "无法读取网页内容"
                    return
                }
                
                // Extract text content from HTML
                let textContent = self?.extractTextFromHTML(htmlString) ?? "无法解析内容"
                
                // If no title was provided, try to extract it from HTML
                var finalTitle = importTitle
                if self?.currentWebImportTitle.isEmpty == true {
                    if let extractedTitle = self?.extractTitleFromHTML(htmlString) {
                        finalTitle = extractedTitle
                    }
                }
                
                self?.currentWebImportContent = textContent
                self?.currentWebImportTitle = finalTitle
                self?.isShowingWebImportDetail = true
            }
        }.resume()
    }
    
    func saveCurrentWebImport() {
        saveWebImport(
            url: currentWebImportURL,
            title: currentWebImportTitle,
            content: currentWebImportContent
        )
        resetWebImporter()
    }
    
    func resetWebImporter() {
        currentWebImportURL = ""
        currentWebImportTitle = ""
        currentWebImportContent = ""
        isShowingWebImporter = false
        isShowingWebImportDetail = false
        webImportError = nil
    }
    
    func convertWebImportToNote(webImport: WebImport) {
        let note = Note(
            title: webImport.title,
            content: "来源: \(webImport.url)\n\n\(webImport.content)",
            timestamp: Date()
        )
        historyManager.saveNote(note)
        loadNotes()
    }
    
    // Helper methods to extract content from HTML
    private func extractTextFromHTML(_ html: String) -> String {
        // Basic HTML to text conversion
        var text = html
        
        // Remove scripts
        text = text.replacingOccurrences(of: "<script[^>]*>([\\s\\S]*?)</script>", with: "", options: .regularExpression)
        
        // Remove styles
        text = text.replacingOccurrences(of: "<style[^>]*>([\\s\\S]*?)</style>", with: "", options: .regularExpression)
        
        // Remove HTML tags
        text = text.replacingOccurrences(of: "<[^>]+>", with: "\n", options: .regularExpression)
        
        // Decode HTML entities
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&#39;", with: "'")
        
        // Remove extra whitespace
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "\n+", with: "\n", options: .regularExpression)
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractTitleFromHTML(_ html: String) -> String? {
        let titlePattern = "<title[^>]*>(.*?)</title>"
        if let titleRange = html.range(of: titlePattern, options: .regularExpression) {
            let titleTag = String(html[titleRange])
            let title = titleTag.replacingOccurrences(of: "<title[^>]*>", with: "", options: .regularExpression)
                                .replacingOccurrences(of: "</title>", with: "")
            return title.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }
}