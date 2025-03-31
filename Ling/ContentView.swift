import SwiftUI

// Theme definition
enum AppTheme: String, CaseIterable, Identifiable {
    case standard = "标准"
    case halloween = "万圣节"
    case newYear = "新年"
    case spring = "春节"
    case darkMode = "暗黑模式"
    
    var id: String { self.rawValue }
    
    var primaryColor: Color {
        switch self {
        case .standard: return .blue
        case .halloween: return .orange
        case .newYear: return .red
        case .spring: return Color(red: 0.8, green: 0.2, blue: 0.2)
        case .darkMode: return Color(red: 0.2, green: 0.5, blue: 0.7)
        }
    }
    
    var secondaryColor: Color {
        switch self {
        case .standard: return Color(.systemGray6)
        case .halloween: return Color(red: 0.2, green: 0.0, blue: 0.3)
        case .newYear: return Color(red: 0.9, green: 0.8, blue: 0.0)
        case .spring: return Color(red: 1.0, green: 0.9, blue: 0.7)
        case .darkMode: return Color(red: 0.15, green: 0.15, blue: 0.15)
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .standard: return Color(.systemBackground)
        case .halloween: return Color(red: 0.1, green: 0.0, blue: 0.15)
        case .newYear: return Color(red: 0.95, green: 0.95, blue: 1.0)
        case .spring: return Color(red: 1.0, green: 0.97, blue: 0.95)
        case .darkMode: return Color(red: 0.08, green: 0.08, blue: 0.1)
        }
    }
    
    var textColor: Color {
        switch self {
        case .standard: return Color(.label)
        case .halloween: return .white
        case .newYear: return Color(.label)
        case .spring: return Color(.label)
        case .darkMode: return Color(red: 0.9, green: 0.9, blue: 0.95)
        }
    }
    
    var accentColor: Color {
        switch self {
        case .standard: return .blue
        case .halloween: return .purple
        case .newYear: return .green
        case .spring: return Color(red: 0.8, green: 0.4, blue: 0.0)
        case .darkMode: return Color(red: 0.4, green: 0.7, blue: 0.9)
        }
    }
    
    var icon: String {
        switch self {
        case .standard: return "paintbrush"
        case .halloween: return "moon.stars"
        case .newYear: return "sparkles"
        case .spring: return "leaf"
        case .darkMode: return "moon.fill"
        }
    }
    
    // Decorative elements for themes
    var decorations: [ThemeDecoration] {
        switch self {
        case .standard:
            return []
        case .halloween:
            return [
                ThemeDecoration(icon: "eyes", size: 30, position: .topRight, opacity: 0.5),
                ThemeDecoration(icon: "moon.stars.fill", size: 24, position: .bottomLeft, opacity: 0.3),
                ThemeDecoration(icon: "bat.fill", size: 26, position: .bottomRight, opacity: 0.4)
            ]
        case .newYear:
            return [
                ThemeDecoration(icon: "sparkles", size: 30, position: .topRight, opacity: 0.5),
                ThemeDecoration(icon: "fireworks", size: 24, position: .bottomLeft, opacity: 0.4),
                ThemeDecoration(icon: "star.fill", size: 20, position: .topLeft, opacity: 0.3)
            ]
        case .spring:
            return [
                ThemeDecoration(icon: "leaf.fill", size: 30, position: .topRight, opacity: 0.4),
                ThemeDecoration(icon: "sun.max.fill", size: 24, position: .bottomLeft, opacity: 0.3),
                ThemeDecoration(icon: "flame.fill", size: 20, position: .bottomRight, opacity: 0.4)
            ]
        case .darkMode:
            return [
                ThemeDecoration(icon: "star.fill", size: 24, position: .bottomRight, opacity: 0.2),
                ThemeDecoration(icon: "moon.fill", size: 20, position: .bottomLeft, opacity: 0.2)
            ]
        }
    }
    
    var colorScheme: ColorScheme {
        switch self {
        case .standard, .newYear, .spring: return .light
        case .halloween, .darkMode: return .dark
        }
    }
}

struct ThemeDecoration: Identifiable {
    var id = UUID()
    var icon: String
    var size: CGFloat
    var position: Position
    var opacity: Double
    
    enum Position {
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    func offset(in geometry: GeometryProxy) -> CGSize {
        switch position {
        case .topLeft:
            return CGSize(width: geometry.size.width * 0.15, height: geometry.size.height * 0.2)
        case .topRight:
            return CGSize(width: geometry.size.width * 0.85, height: geometry.size.height * 0.2)
        case .bottomLeft:
            return CGSize(width: geometry.size.width * 0.15, height: geometry.size.height * 0.9)
        case .bottomRight:
            return CGSize(width: geometry.size.width * 0.85, height: geometry.size.height * 0.9)
        }
    }
}

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme
    
    init() {
        // Load the saved theme or use standard as default
        if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = AppTheme.allCases.first(where: { $0.rawValue == savedTheme }) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .standard
        }
    }
    
    func setTheme(_ theme: AppTheme) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = theme
            // Save the theme preference
            UserDefaults.standard.set(theme.rawValue, forKey: "selectedTheme")
        }
    }
}

struct ContentView: View {
    @StateObject var viewModel = ContentViewModel()
    @StateObject var themeManager = ThemeManager()
    @State private var showThemeSelector = false
    
    private func recordTimestamp(_ obj: Any) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        if let note = obj as? Note {
            return formatter.string(from: note.timestamp)
        } else if let record = obj as? HistoryRecord {
            return formatter.string(from: record.timestamp)
        } else if let webImport = obj as? WebImport {
            return formatter.string(from: webImport.timestamp)
        }
        
        return formatter.string(from: Date())
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Background - avoiding status bar
                    Rectangle()
                        .fill(themeManager.currentTheme.backgroundColor)
                        .ignoresSafeArea(edges: [.horizontal, .bottom])
                    
                    // Theme decorations
                    ForEach(themeManager.currentTheme.decorations) { decoration in
                        Image(systemName: decoration.icon)
                            .font(.system(size: decoration.size))
                            .foregroundColor(themeManager.currentTheme.accentColor)
                            .opacity(decoration.opacity)
                            .position(
                                x: decoration.offset(in: geometry).width,
                                y: decoration.offset(in: geometry).height
                            )
                    }
                    
                    // Main content with top padding to avoid status bar
                    VStack(spacing: 12) {
                        // Title area
                        Text("笔记与智能助手")
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.textColor)
                            .padding(.top, 8)
                        
                        // Top action row
                        HStack(spacing: 8) {
                            Button(action: {
                                viewModel.isShowingWebImporter = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "link")
                                        .font(.system(size: 14))
                                    Text("导入网页")
                                        .font(.subheadline)
                                }
                                .foregroundColor(themeManager.currentTheme.textColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(themeManager.currentTheme.secondaryColor.opacity(0.6))
                                .cornerRadius(6)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                viewModel.isShowingSettings = true
                            }) {
                                Image(systemName: "gear")
                                    .font(.system(size: 16))
                                    .foregroundColor(themeManager.currentTheme.primaryColor)
                                    .frame(width: 30, height: 30)
                            }
                            
                            Button(action: {
                                showThemeSelector = true
                            }) {
                                Image(systemName: themeManager.currentTheme.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                                    .frame(width: 30, height: 30)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .padding(.leading, 8)
                            
                            TextField("输入过滤关键词", text: $viewModel.searchText)
                                .textFieldStyle(.plain)
                                .foregroundColor(themeManager.currentTheme.textColor)
                                .padding(.vertical, 8)
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        
                        // Action buttons
                        HStack(spacing: 8) {
                            Button("执行过滤") {
                                viewModel.performFilter()
                            }
                            .buttonStyle(ThemedButtonStyle(theme: themeManager.currentTheme, isPrimary: true))
                            .disabled(viewModel.isSearching)
                            
                            Button(viewModel.selectedNoteIds.isEmpty && viewModel.selectedWebImportIds.isEmpty ? 
                                  "选择参考资料" : 
                                  "已选择\(viewModel.selectedNoteIds.count + viewModel.selectedWebImportIds.count)个资料") {
                                viewModel.isShowingNoteSelector = true
                            }
                            .buttonStyle(ThemedButtonStyle(theme: themeManager.currentTheme, isPrimary: false))
                            
                            Button("清空记录") {
                                viewModel.deleteAll()
                            }
                            .buttonStyle(ThemedButtonStyle(theme: themeManager.currentTheme, isPrimary: false))
                            .disabled(viewModel.isSearching)
                        }
                        .padding(.horizontal)
                        
                        // Tab selector
                        Picker("视图模式", selection: $viewModel.viewMode) {
                            Text("历史记录").tag(0)
                            Text("过滤结果").tag(1)
                            Text("笔记").tag(2)
                            Text("网页").tag(3)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        .accentColor(themeManager.currentTheme.primaryColor)
                        
                        // Content area based on selected tab
                        if viewModel.viewMode == 0 {
                            historyList
                        } else if viewModel.viewMode == 1 {
                            resultsView
                        } else if viewModel.viewMode == 2 {
                            notesView
                        } else {
                            webImportsView
                        }
                    }
                    
                    // Floating action button
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                if viewModel.viewMode == 3 {
                                    viewModel.isShowingWebImporter = true
                                } else {
                                    viewModel.isShowingNoteEditor = true
                                }
                            }) {
                                Image(systemName: viewModel.viewMode == 3 ? "link.badge.plus" : "square.and.pencil")
                                    .font(.system(size: 22))
                                    .frame(width: 48, height: 48)
                                    .foregroundColor(.white)
                                    .background(themeManager.currentTheme.primaryColor)
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(themeManager.currentTheme.colorScheme)
            .onAppear {
                viewModel.loadHistory()
                viewModel.loadNotes()
                viewModel.loadWebImports()
            }
            .sheet(isPresented: $viewModel.isShowingNoteEditor) {
                NoteEditorView(viewModel: viewModel, theme: themeManager.currentTheme)
            }
            .sheet(isPresented: $viewModel.isShowingSettings) {
                SettingsView(viewModel: viewModel, theme: themeManager.currentTheme)
            }
            .sheet(isPresented: $viewModel.isShowingNoteSelector) {
                NoteSelectorView(viewModel: viewModel)
            }
            .sheet(isPresented: $showThemeSelector) {
                ThemeSelectorView(themeManager: themeManager)
            }
            .sheet(isPresented: $viewModel.isShowingWebImporter) {
                WebImporterView(viewModel: viewModel, theme: themeManager.currentTheme)
            }
            .sheet(isPresented: $viewModel.isShowingWebImportDetail) {
                WebImportDetailView(viewModel: viewModel, theme: themeManager.currentTheme)
            }
        }
    }
    
    // MARK: - Content Views
    
    private var historyList: some View {
        List {
            ForEach(viewModel.historyRecords.sorted(by: { $0.timestamp > $1.timestamp })) { record in
                VStack(alignment: .leading, spacing: 5) {
                    Text(record.keyword).font(.headline)
                    Text(record.content.prefix(50)).font(.subheadline)
                    Text(recordTimestamp(record)).font(.caption)
                }
                .padding(.vertical, 5)
                .foregroundColor(themeManager.currentTheme.textColor)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.deleteRecord(at: index)
                }
            }
            .listRowBackground(themeManager.currentTheme.secondaryColor)
        }
        .scrollContentBackground(.hidden)
        .listStyle(.plain)
    }
    
    private var resultsView: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading) {
                    Text(viewModel.filterResult)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(themeManager.currentTheme.secondaryColor)
                        .foregroundColor(themeManager.currentTheme.textColor)
                        .cornerRadius(8)
                }
                .padding()
            }
            
            if viewModel.isSearching {
                ProgressView("处理中...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
                    .background(themeManager.currentTheme.backgroundColor.opacity(0.9))
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .cornerRadius(10)
            }
        }
    }
    
    private var notesView: some View {
        List {
            ForEach(viewModel.notes) { note in
                NavigationLink(destination: NoteDetailView(note: note, viewModel: viewModel, theme: themeManager.currentTheme)) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(note.title).font(.headline)
                        Text(note.content.prefix(50)).font(.subheadline)
                        Text(recordTimestamp(note)).font(.caption)
                    }
                    .padding(.vertical, 5)
                    .foregroundColor(themeManager.currentTheme.textColor)
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    if index < viewModel.notes.count {
                        viewModel.deleteNote(withId: viewModel.notes[index].id)
                    }
                }
            }
            .listRowBackground(themeManager.currentTheme.secondaryColor)
        }
        .scrollContentBackground(.hidden)
        .listStyle(.plain)
    }
    
    private var webImportsView: some View {
        List {
            ForEach(viewModel.webImports) { webImport in
                NavigationLink {
                    let webImportViewData = WebImportDetailView(viewModel: viewModel, theme: themeManager.currentTheme)
                        .onAppear {
                            viewModel.currentWebImportURL = webImport.url
                            viewModel.currentWebImportTitle = webImport.title
                            viewModel.currentWebImportContent = webImport.content
                        }
                    return webImportViewData
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(themeManager.currentTheme.accentColor)
                            Text(webImport.title).font(.headline)
                        }
                        Text(webImport.url).font(.caption).lineLimit(1)
                        Text("导入于 \(recordTimestamp(webImport))").font(.caption)
                    }
                    .padding(.vertical, 5)
                    .foregroundColor(themeManager.currentTheme.textColor)
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    if index < viewModel.webImports.count {
                        viewModel.deleteWebImport(withId: viewModel.webImports[index].id)
                    }
                }
            }
            .listRowBackground(themeManager.currentTheme.secondaryColor)
        }
        .scrollContentBackground(.hidden)
        .listStyle(.plain)
    }
}

struct ThemedButtonStyle: ButtonStyle {
    let theme: AppTheme
    let isPrimary: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isPrimary ? theme.primaryColor : theme.secondaryColor)
            .foregroundColor(isPrimary ? .white : theme.textColor)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

struct ThemeSelectorView: View {
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(AppTheme.allCases) { theme in
                    Button(action: {
                        themeManager.setTheme(theme)
                        dismiss()
                    }) {
                        HStack {
                            Circle()
                                .fill(theme.primaryColor)
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: theme.icon)
                                .foregroundColor(theme.accentColor)
                                .padding(.horizontal, 4)
                            
                            Text(theme.rawValue)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if themeManager.currentTheme == theme {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("选择主题")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct NoteEditorView: View {
    @ObservedObject var viewModel: ContentViewModel
    let theme: AppTheme
    @Environment(\.dismiss) var dismiss
    @State private var title: String = ""
    @State private var content: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()
                
                VStack {
                    TextField("笔记标题", text: $title)
                        .font(.headline)
                        .padding()
                        .foregroundColor(theme.textColor)
                    
                    TextEditor(text: $content)
                        .padding()
                        .foregroundColor(theme.textColor)
                        .background(theme.secondaryColor.opacity(0.3))
                        .cornerRadius(8)
                    
                    Button("保存笔记") {
                        if !title.isEmpty && !content.isEmpty {
                            viewModel.saveNote(title: title, content: content)
                            dismiss()
                        }
                    }
                    .buttonStyle(ThemedButtonStyle(theme: theme, isPrimary: true))
                    .padding()
                    .disabled(title.isEmpty || content.isEmpty)
                }
                .padding()
            }
            .navigationTitle("新建笔记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.primaryColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(theme.colorScheme == .dark ? .white : .black)
                }
            }
        }
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: ContentViewModel
    let theme: AppTheme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()
                
                Form {
                    Section(header: Text("API 设置")) {
                        SecureField("OpenAI API Key", text: $viewModel.apiKey)
                            .foregroundColor(theme.textColor)
                        
                        Button("保存") {
                            viewModel.saveAPIKey()
                            dismiss()
                        }
                        .buttonStyle(ThemedButtonStyle(theme: theme, isPrimary: true))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    }
                    
                    Section(header: Text("应用管理")) {
                        Button("清空所有数据") {
                            viewModel.deleteAll()
                            dismiss()
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.primaryColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(theme.colorScheme == .dark ? .white : .black)
                }
            }
        }
    }
}

struct NoteSelectorView: View {
    @ObservedObject var viewModel: ContentViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab = 0 // 0 for notes, 1 for web imports
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("选择类型", selection: $selectedTab) {
                    Text("笔记").tag(0)
                    Text("网页").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    // Notes tab
                    List {
                        ForEach(viewModel.notes) { note in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(note.title)
                                        .font(.headline)
                                    Text(note.content)
                                        .lineLimit(2)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: viewModel.selectedNoteIds.contains(note.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(viewModel.selectedNoteIds.contains(note.id) ? .blue : .gray)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.toggleNoteSelection(noteId: note.id)
                            }
                        }
                    }
                } else {
                    // Web imports tab
                    List {
                        ForEach(viewModel.webImports) { webImport in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(webImport.title)
                                        .font(.headline)
                                    Text(webImport.url)
                                        .lineLimit(1)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: viewModel.selectedWebImportIds.contains(webImport.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(viewModel.selectedWebImportIds.contains(webImport.id) ? .blue : .gray)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.toggleWebImportSelection(id: webImport.id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择参考资料")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("清空选择") {
                        viewModel.clearSelections()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct NoteDetailView: View {
    let note: Note
    @ObservedObject var viewModel: ContentViewModel
    @State private var editedContent: String
    @State private var editedTitle: String
    @State private var isEditing = false
    let theme: AppTheme
    
    init(note: Note, viewModel: ContentViewModel, theme: AppTheme) {
        self.note = note
        self.viewModel = viewModel
        self.theme = theme
        _editedContent = State(initialValue: note.content)
        _editedTitle = State(initialValue: note.title)
    }
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack {
                if isEditing {
                    TextField("标题", text: $editedTitle)
                        .font(.headline)
                        .padding()
                        .foregroundColor(theme.textColor)
                    
                    TextEditor(text: $editedContent)
                        .padding()
                        .foregroundColor(theme.textColor)
                        .background(theme.secondaryColor.opacity(0.3))
                        .cornerRadius(8)
                    
                    HStack {
                        Button("取消") {
                            isEditing = false
                            editedContent = note.content
                            editedTitle = note.title
                        }
                        .buttonStyle(ThemedButtonStyle(theme: theme, isPrimary: false))
                        .padding()
                        
                        Spacer()
                        
                        Button("保存") {
                            viewModel.saveNote(title: editedTitle, content: editedContent)
                            viewModel.deleteNote(withId: note.id)
                            viewModel.loadNotes()
                            isEditing = false
                        }
                        .buttonStyle(ThemedButtonStyle(theme: theme, isPrimary: true))
                        .padding()
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading) {
                            Text(note.title)
                                .font(.title)
                                .padding()
                                .foregroundColor(theme.textColor)
                            
                            Text(note.content)
                                .padding()
                                .foregroundColor(theme.textColor)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .navigationTitle(isEditing ? "编辑笔记" : note.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.primaryColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
        .toolbar {
            if !isEditing {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isEditing = true
                    }) {
                        Text("编辑")
                    }
                    .foregroundColor(theme.colorScheme == .dark ? .white : .black)
                }
            }
        }
    }
}

struct WebImporterView: View {
    @ObservedObject var viewModel: ContentViewModel
    let theme: AppTheme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Text("导入网页作为参考资料")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("网页地址").font(.subheadline).foregroundColor(theme.textColor)
                        
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(.gray)
                            TextField("输入完整网址 (https://...)", text: $viewModel.currentWebImportURL)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .foregroundColor(theme.textColor)
                        }
                        .padding(10)
                        .background(theme.secondaryColor.opacity(0.3))
                        .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("标题 (可选)").font(.subheadline).foregroundColor(theme.textColor)
                        
                        HStack {
                            Image(systemName: "text.quote")
                                .foregroundColor(.gray)
                            TextField("网页标题，留空则自动获取", text: $viewModel.currentWebImportTitle)
                                .foregroundColor(theme.textColor)
                        }
                        .padding(10)
                        .background(theme.secondaryColor.opacity(0.3))
                        .cornerRadius(8)
                    }
                    
                    if let errorMessage = viewModel.webImportError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.importWebContent()
                    }) {
                        HStack {
                            if viewModel.isImportingWebContent {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "arrow.down.doc")
                                Text("导入网页")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.currentWebImportURL.isEmpty ? Color.gray : theme.primaryColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.currentWebImportURL.isEmpty || viewModel.isImportingWebContent)
                }
                .padding()
            }
            .navigationTitle("导入网页")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        viewModel.resetWebImporter()
                        dismiss()
                    }
                    .foregroundColor(theme.colorScheme == .dark ? .white : .black)
                }
            }
        }
    }
}

struct WebImportDetailView: View {
    @ObservedObject var viewModel: ContentViewModel
    let theme: AppTheme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(theme.accentColor)
                        Text(viewModel.currentWebImportTitle)
                            .font(.headline)
                            .foregroundColor(theme.textColor)
                    }
                    .padding(.vertical, 8)
                    
                    Link(destination: URL(string: viewModel.currentWebImportURL) ?? URL(string: "https://google.com")!) {
                        Text(viewModel.currentWebImportURL)
                            .font(.subheadline)
                            .foregroundColor(theme.accentColor)
                            .underline()
                            .lineLimit(1)
                    }
                    
                    Divider().background(theme.secondaryColor)
                    
                    Text(viewModel.currentWebImportContent)
                        .foregroundColor(theme.textColor)
                        .padding(.vertical, 8)
                }
                .padding()
            }
            
            // Bottom action buttons
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    Button("取消") {
                        viewModel.resetWebImporter()
                        dismiss()
                    }
                    .padding()
                    .background(theme.secondaryColor)
                    .foregroundColor(theme.textColor)
                    .cornerRadius(10)
                    
                    Button("保存为网页导入") {
                        viewModel.saveCurrentWebImport()
                        dismiss()
                    }
                    .padding()
                    .background(theme.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
                .background(theme.backgroundColor)
            }
        }
        .navigationTitle("网页内容预览")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Convert directly to note instead of web import
                    viewModel.saveNote(
                        title: "网页笔记: \(viewModel.currentWebImportTitle)",
                        content: "来源: \(viewModel.currentWebImportURL)\n\n\(viewModel.currentWebImportContent)"
                    )
                    viewModel.resetWebImporter()
                    dismiss()
                }) {
                    Image(systemName: "square.and.pencil")
                }
                .foregroundColor(theme.colorScheme == .dark ? .white : .black)
            }
        }
    }
}

#Preview {
    ContentView()
}

