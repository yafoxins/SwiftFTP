import SwiftUI

struct FileListView: View {
    @ObservedObject var manager = ConnectionManager.shared
    @ObservedObject var loc = LocalizationManager.shared
    @State private var pathInput: String = ""
    @State private var renamingFile: RemoteFile? = nil
    @State private var newName: String = ""
    @State private var showRenameSheet = false
    @State private var deletingFile: RemoteFile? = nil
    @State private var showCustomDeleteDialog = false
    @State private var showPermissionsSheet = false
    @State private var permissionsTarget: RemoteFile? = nil
    @State private var hoveredFolder: String? = nil
    @State private var selectedFolderPath: String? = nil
    @State private var showInfoSheet = false
    @State private var infoTarget: RemoteFile? = nil
    @State private var showReplaceDialog = false
    @State private var replaceDialogFile: String = ""
    @State private var replaceDialogLocalURL: URL? = nil
    @State private var replaceDialogDestPath: String = ""
    @State private var selectedFiles: Set<String> = [] // path
    @State private var showBatchDeleteDialog = false
    @State private var lastSelectedIndex: Int? = nil // для shift-выделения
    @State private var dragSelecting = false
    @State private var dragRect: CGRect = .zero
    @FocusState private var isFocused: Bool
    @State private var fileRowRects: [String: CGRect] = [:] // path -> rect

    var body: some View {
        VStack(spacing: 0) {
            // Верхняя панель
            HStack(spacing: 6) {
                Button(action: { manager.goUp() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.accentColor)
                        .padding(4)
                }
                .buttonStyle(AnimatedButtonStyle())
                .help(loc.localized("Up"))
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color(nsColor: NSColor.controlBackgroundColor).opacity(0.92))
                        .shadow(color: Color.black.opacity(0.04), radius: 1, y: 1)
                    HStack(spacing: 6) {
                        Image(systemName: "folder")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.accentColor)
                        TextField(loc.localized("Path"), text: $pathInput, onCommit: {
                            manager.changeDirectory(to: pathInput)
                        })
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundColor(.primary)
                        .frame(minHeight: 22, maxHeight: 22)
                        .padding(.vertical, 0)
                        .background(Color.clear)
                        .onAppear {
                            pathInput = manager.currentPath
                        }
                        .onChange(of: manager.currentPath) { newValue in
                            pathInput = newValue
                        }
                        if !pathInput.isEmpty {
                            Button(action: { pathInput = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(AnimatedButtonStyle())
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, minHeight: 26, maxHeight: 26)
                // Кнопка массового удаления
                if !selectedFiles.isEmpty {
                    Button(action: { showBatchDeleteDialog = true }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text(loc.localized("Delete selected"))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(AnimatedButtonStyle())
                    .padding(.leading, 8)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)
            // Быстрые действия
            if !selectedFiles.isEmpty {
                QuickActionsToolbar(
                    selectedFiles: selectedFiles,
                    manager: manager,
                    loc: loc,
                    onRename: { file in
                        renamingFile = file
                        newName = file.name
                        showRenameSheet = true
                    },
                    onDeselect: { selectedFiles.removeAll() },
                    onDelete: { showBatchDeleteDialog = true }
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 2)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            // Список файлов с drag-rectangle и поддержкой Cmd+A
            ZStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            if manager.currentPath != "/" && manager.currentPath != "." {
                                AnimatedBackButton {
                                    manager.goUp()
                                }
                                .id("back")
                            }
                            ForEach(Array(manager.remoteFiles.enumerated()), id: \ .element.id) { idx, file in
                                FileRowView(
                                    file: file,
                                    hoveredFolder: $hoveredFolder,
                                    selectedFolderPath: $selectedFolderPath,
                                    manager: manager,
                                    loc: loc,
                                    isSelected: selectedFiles.contains(file.path),
                                    onSelect: { path in
                                        if let last = lastSelectedIndex, NSEvent.modifierFlags.contains(.shift), let current = manager.remoteFiles.firstIndex(where: { $0.path == path }) {
                                            let range = last <= current ? last...current : current...last
                                            for i in range { selectedFiles.insert(manager.remoteFiles[i].path) }
                                        } else {
                                            if selectedFiles.contains(file.path) {
                                                selectedFiles.remove(file.path)
                                            } else {
                                                selectedFiles.insert(file.path)
                                            }
                                            lastSelectedIndex = idx
                                        }
                                    },
                                    onRename: {
                                        renamingFile = file
                                        newName = file.name
                                        showRenameSheet = true
                                        if file.isDirectory { selectedFolderPath = file.path }
                                    },
                                    onDelete: {
                                        _ = manager.delete(path: file.path)
                                        deletingFile = nil
                                    },
                                    onPermissions: {
                                        permissionsTarget = file
                                        showPermissionsSheet = true
                                        if file.isDirectory { selectedFolderPath = file.path }
                                    },
                                    onInfo: {
                                        infoTarget = file
                                        showInfoSheet = true
                                    },
                                    onGeometry: { rect in
                                        fileRowRects[file.path] = rect
                                    }
                                )
                                .id(file.path)
                            }
                        }
                    }
                    .onChange(of: manager.currentPath) { _ in
                        selectedFiles.removeAll()
                        if UserDefaults.standard.bool(forKey: "autoScrollToTop") {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo("back", anchor: .top)
                                }
                            }
                        }
                    }
                }
                // Drag-rectangle overlay (визуализация)
                if dragSelecting {
                    Rectangle()
                        .fill(Color.accentColor.opacity(0.13))
                        .frame(width: dragRect.width, height: dragRect.height)
                        .position(x: dragRect.midX, y: dragRect.midY)
                        .animation(.easeInOut(duration: 0.08), value: dragRect)
                        .allowsHitTesting(false)
                }
            }
            .background(FocusableView(isFocused: Binding(get: { isFocused }, set: { isFocused = $0 }), onKeyDown: handleKeyDown))
            .gesture(DragGesture(minimumDistance: 8)
                .onChanged { value in
                    dragSelecting = true
                    dragRect = CGRect(origin: value.startLocation, size: CGSize(width: value.location.x - value.startLocation.x, height: value.location.y - value.startLocation.y)).standardized
                    // Выделяем файлы по реальным rects
                    var newSelection = Set<String>()
                    for (path, rect) in fileRowRects {
                        if dragRect.intersects(rect) {
                            newSelection.insert(path)
                        }
                    }
                    selectedFiles = newSelection
                }
                .onEnded { _ in
                    dragSelecting = false
                    dragRect = .zero
                }
            )
            .id(manager.currentPath)
            .padding(.horizontal, 0)
            .coordinateSpace(name: "filelist")
            // upload-зона только снизу
            if manager.uploadQueue.isEmpty {
                UploadDropZone(isUploading: false, upload: nil, loc: loc, onDrop: { providers in
                    handleDrop(providers: providers, destPath: manager.currentPath)
                })
                .frame(height: 52)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            } else {
                VStack(spacing: 8) {
                    // Общий прогресс
                    HStack(spacing: 12) {
                        ProgressView(value: manager.totalUploadProgress)
                            .frame(width: 160)
                        Text(String(format: "%d%%", Int(manager.totalUploadProgress * 100)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 2)
                    ForEach(manager.uploadQueue.indices, id: \ .self) { idx in
                        let upload = manager.uploadQueue[idx]
                        UploadDropZone(isUploading: true, upload: upload, loc: loc, onDrop: { providers in
                            handleDrop(providers: providers, destPath: manager.currentPath)
                        }, onCancel: {
                            upload.cancel()
                        })
                        .frame(height: 52)
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 12)
            }
        }
        .navigationTitle(loc.localized("Files"))
        .sheet(isPresented: $showRenameSheet) {
            RenameSheet(file: $renamingFile, newName: $newName, isPresented: $showRenameSheet, onSave: { file, newName in
                if let file = file {
                    manager.rename(from: file.path, to: newName)
                }
            }, loc: loc)
        }
        .sheet(isPresented: $showPermissionsSheet) {
            if let file = permissionsTarget {
                PermissionsSheet(file: file, isPresented: $showPermissionsSheet, onSave: { perms, recursive in
                    manager.changePermissions(path: file.path, permissions: perms, recursive: recursive) { success, error in
                        if !success {
                            manager.error = error
                        }
                    }
                }, loc: loc)
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            if let file = infoTarget {
                InfoSheet(file: file, isPresented: $showInfoSheet, loc: loc)
            }
        }
        .sheet(isPresented: Binding(get: { showReplaceDialog }, set: { newValue in
            if !newValue {
                // Сброс переменных при закрытии
                replaceDialogFile = ""
                replaceDialogLocalURL = nil
                replaceDialogDestPath = ""
            }
            showReplaceDialog = newValue
        })) {
            if let localURL = replaceDialogLocalURL {
                ReplaceFileDialog(
                    isPresented: $showReplaceDialog,
                    fileName: replaceDialogFile,
                    localURL: localURL,
                    destPath: replaceDialogDestPath,
                    onReplace: {
                        showReplaceDialog = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            replaceDialogFile = ""
                            replaceDialogLocalURL = nil
                            replaceDialogDestPath = ""
                        }
                        manager.upload(localURL: localURL, destPath: replaceDialogDestPath)
                    },
                    onSkip: {
                        showReplaceDialog = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            replaceDialogFile = ""
                            replaceDialogLocalURL = nil
                            replaceDialogDestPath = ""
                        }
                    },
                    onRetry: {
                        showReplaceDialog = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            replaceDialogFile = ""
                            replaceDialogLocalURL = nil
                            replaceDialogDestPath = ""
                        }
                        // Повторяем проверку существования
                        let fileName = localURL.lastPathComponent
                        var remotePath = replaceDialogDestPath
                        if !remotePath.hasSuffix("/") { remotePath += "/" }
                        remotePath += fileName
                        manager.fileExists(path: remotePath) { exists, error in
                            DispatchQueue.main.async {
                                if let error = error {
                                    print("RETRY: error checking file existence: \(error)")
                                    manager.upload(localURL: localURL, destPath: replaceDialogDestPath)
                                } else if exists {
                                    // Форсируем повторное открытие
                                    replaceDialogFile = fileName + " " + UUID().uuidString
                                    replaceDialogLocalURL = localURL
                                    replaceDialogDestPath = replaceDialogDestPath
                                    showReplaceDialog = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        showReplaceDialog = true
                                    }
                                } else {
                                    manager.upload(localURL: localURL, destPath: replaceDialogDestPath)
                                }
                            }
                        }
                    },
                    loc: loc
                )
            }
        }
        .sheet(isPresented: $showCustomDeleteDialog) {
            if let file = deletingFile {
                CustomDeleteDialog(
                    isPresented: $showCustomDeleteDialog,
                    onDelete: {
                        _ = manager.delete(path: file.path)
                        deletingFile = nil
                    },
                    onCancel: {
                        deletingFile = nil
                    },
                    loc: loc,
                    file: file
                )
            }
        }
        .sheet(isPresented: $showBatchDeleteDialog) {
            CustomDeleteDialog(
                isPresented: $showBatchDeleteDialog,
                onDelete: {
                    for path in selectedFiles {
                        _ = manager.delete(path: path)
                    }
                    selectedFiles.removeAll()
                },
                onCancel: {},
                loc: loc,
                file: RemoteFile(name: loc.localized("Selected files"), path: "", isDirectory: false, size: 0, modifiedDate: Date(), permissions: nil)
            )
        }
        .onAppear {
            NotificationCenter.default.addObserver(forName: NSNotification.Name("ResetSelectionAfterReload"), object: nil, queue: .main) { _ in
                selectedFiles.removeAll()
            }
        }
    }

    // Обработка Cmd+A
    private func handleKeyDown(_ event: NSEvent) {
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers?.lowercased() == "a" {
            selectedFiles = Set(manager.remoteFiles.map { $0.path })
        } else if event.keyCode == 53 { // Esc
            selectedFiles.removeAll()
        }
    }

    func handleDrop(providers: [NSItemProvider], destPath: String) -> Bool {
        print("UPLOAD DROP: destPath=\(destPath), providers=\(providers.count)")
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    print("UPLOAD DROP: url=\(url.path)")
                    DispatchQueue.main.async {
                        // Проверяем существование файла перед upload
                        let fileName = url.lastPathComponent
                        var remotePath = destPath
                        if !remotePath.hasSuffix("/") { remotePath += "/" }
                        remotePath += fileName
                        
                        manager.fileExists(path: remotePath) { exists, error in
                            DispatchQueue.main.async {
                                if let error = error {
                                    print("UPLOAD DROP: error checking file existence: \(error)")
                                    // Если ошибка - все равно пытаемся upload
                                    manager.upload(localURL: url, destPath: destPath)
                                } else if exists {
                                    // Файл существует - показываем диалог замены
                                    replaceDialogFile = fileName
                                    replaceDialogLocalURL = url
                                    replaceDialogDestPath = destPath
                                    showReplaceDialog = true
                                } else {
                                    // Файл не существует - upload
                                    manager.upload(localURL: url, destPath: destPath)
                                }
                            }
                        }
                    }
                } else {
                    print("UPLOAD DROP: error or no url")
                }
            }
        }
        return true
    }
}

// Компонент для отображения строки файла
struct FileRowView: View {
    let file: RemoteFile
    @Binding var hoveredFolder: String?
    @Binding var selectedFolderPath: String?
    let manager: ConnectionManager
    let loc: LocalizationManager
    let isSelected: Bool
    let onSelect: (String) -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    let onPermissions: () -> Void
    let onInfo: () -> Void
    let onGeometry: (CGRect) -> Void
    
    @AppStorage("showFileSize") var showFileSize: Bool = true
    @AppStorage("showFileDate") var showFileDate: Bool = true
    @AppStorage("showFilePermissions") var showFilePermissions: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 12) {
                // Иконка
                Image(systemName: file.isDirectory ? "folder" : "doc")
                    .foregroundColor(file.isDirectory ? .accentColor : .gray)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 20, alignment: .leading)
                
                // Основная информация
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    // Дополнительная информация
                    if showFileSize || showFileDate || showFilePermissions {
                        HStack(spacing: 8) {
                            if showFileSize && !file.isDirectory {
                                Text(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if showFileDate {
                                Text(DateFormatter.localizedString(from: file.modifiedDate, dateStyle: .short, timeStyle: .short))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if showFilePermissions, let perms = file.permissions {
                                Text(String(format: "%03o", perms))
                                    .font(.caption)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 0)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.18) : (hoveredFolder == file.path || selectedFolderPath == file.path) ? Color.accentColor.opacity(0.13) : Color.clear)
            )
            .animation(.easeInOut(duration: 0.15), value: isSelected)
            .onTapGesture {
                if file.isDirectory && !manager.loadingFiles {
                    manager.changeDirectory(to: file.path)
                    selectedFolderPath = file.path
                } else {
                    onSelect(file.path)
                }
            }
            .onHover { hover in
                hoveredFolder = hover ? file.path : nil
            }
            .contextMenu {
                Button(loc.localized("Rename")) {
                    onRename()
                }
                Button(loc.localized("Delete")) {
                    onDelete()
                }
                Button(loc.localized("Permissions")) {
                    onPermissions()
                }
                Button(loc.localized("Info")) {
                    onInfo()
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    onGeometry(geo.frame(in: .named("filelist")))
                }
            }
            .onChange(of: geo.frame(in: .named("filelist"))) { newRect in
                DispatchQueue.main.async {
                    onGeometry(newRect)
                }
            }
        }
        .frame(height: 38)
    }
}

// Кастомная кнопка для виртуальной папки ".." с анимацией
struct AnimatedBackButton: View {
    var action: () -> Void
    @State private var isHover = false
    var body: some View {
        HStack {
            Image(systemName: "arrow.uturn.left")
                .foregroundColor(.accentColor)
            Text("..")
                .font(.body)
                .foregroundColor(.accentColor)
            Spacer()
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .background(isHover ? Color.accentColor.opacity(0.08) : Color.clear)
        .shadow(color: isHover ? Color.accentColor.opacity(0.18) : .clear, radius: 6, y: 2)
        .animation(.spring(response: 0.22, dampingFraction: 0.6), value: isHover)
        .onTapGesture { action() }
        .onHover { hover in isHover = hover }
    }
}

// Кастомный sheet для переименования файла/папки
struct RenameSheet: View {
    @Binding var file: RemoteFile?
    @Binding var newName: String
    @Binding var isPresented: Bool
    var onSave: (RemoteFile?, String) -> Void
    var loc: LocalizationManager
    @FocusState private var isFocused: Bool
    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.13))
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.accentColor.opacity(0.13), radius: 8, y: 2)
                Image(systemName: file?.isDirectory == true ? "folder.fill" : "doc.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.accentColor)
            }
            .padding(.top, 6)
            Text(loc.localized("Rename"))
                .font(.title2).bold()
                .padding(.bottom, 2)
            TextField(loc.localized("New name"), text: $newName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .frame(width: 240)
                .focused($isFocused)
                .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { isFocused = true } }
            HStack(spacing: 16) {
                Button(action: { isPresented = false }) {
                    Text(loc.localized("Cancel"))
                        .frame(minWidth: 90, minHeight: 34)
                }
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.secondary.opacity(0.10))
                )
                .foregroundColor(.secondary)
                Button(action: {
                    onSave(file, newName)
                    isPresented = false
                }) {
                    Text(loc.localized("Save"))
                        .fontWeight(.semibold)
                        .frame(minWidth: 90, minHeight: 34)
                }
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill((newName.isEmpty || newName == file?.name) ? Color.accentColor.opacity(0.25) : Color.accentColor)
                )
                .foregroundColor(.white)
                .opacity((newName.isEmpty || newName == file?.name) ? 0.6 : 1)
                .animation(.easeInOut(duration: 0.18), value: newName)
                .disabled(newName.isEmpty || newName == file?.name)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
            .padding(.bottom, 4)
        }
        .frame(width: 320)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(nsColor: NSColor.windowBackgroundColor).opacity(0.98))
                .shadow(radius: 14, y: 4)
        )
        .animation(.spring(response: 0.22, dampingFraction: 0.7), value: newName)
    }
}

// Новый кастомный диалог:
struct CustomDeleteDialog: View {
    @Binding var isPresented: Bool
    var onDelete: () -> Void
    var onCancel: () -> Void
    var loc: LocalizationManager
    var file: RemoteFile
    @State private var isHoverDelete = false
    @State private var isHoverCancel = false
    var body: some View {
        ZStack {
            // Новый светлый blur-фон
            VisualEffectBlur()
                .opacity(0.85)
                .ignoresSafeArea()
                .transition(.opacity)
            VStack(spacing: 26) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.13))
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.red.opacity(0.13), radius: 8, y: 2)
                    Image(systemName: "trash.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.red)
                }
                .padding(.top, 6)
                Text(loc.localized("Delete"))
                    .font(.title2).bold()
                Text(loc.localized("Are you sure you want to delete this file or folder?"))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                HStack(spacing: 18) {
                    Button(action: {
                        isPresented = false
                        onCancel()
                    }) {
                        Text(loc.localized("Cancel"))
                            .fontWeight(.medium)
                            .frame(minWidth: 100, minHeight: 40)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.secondary.opacity(isHoverCancel ? 0.18 : 0.10))
                    )
                    .foregroundColor(.primary)
                    .onHover { isHoverCancel = $0 }
                    Button(action: {
                        isPresented = false
                        onDelete()
                    }) {
                        Text(loc.localized("Delete"))
                            .fontWeight(.semibold)
                            .frame(minWidth: 100, minHeight: 40)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isHoverDelete ? Color.red : Color.red.opacity(0.85))
                    )
                    .foregroundColor(.white)
                    .shadow(color: Color.red.opacity(0.18), radius: 6, y: 2)
                    .onHover { isHoverDelete = $0 }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
                .padding(.bottom, 4)
            }
            .frame(width: 370)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(nsColor: NSColor.windowBackgroundColor).opacity(0.98))
                    .shadow(color: Color.black.opacity(0.13), radius: 24, y: 8)
            )
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: isPresented)
            .transition(.scale.combined(with: .opacity))
        }
        .animation(.spring(response: 0.22, dampingFraction: 0.7), value: isPresented)
    }
}

// Новая PermissionsSheet:
struct PermissionsSheet: View {
    let file: RemoteFile
    @Binding var isPresented: Bool
    var onSave: (UInt32, Bool) -> Void
    var loc: LocalizationManager
    @State private var permsString: String = "755"
    @State private var recursive: Bool = false
    @State private var perms: [[Bool]] = [[true, true, true], [true, false, true], [true, false, true]] // rwx для owner/group/other
    @FocusState private var isFocused: Bool
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(nsColor: NSColor.windowBackgroundColor).opacity(0.98))
                .shadow(radius: 14, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.accentColor.opacity(0.10), lineWidth: 1.2)
                )
            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.13))
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.accentColor.opacity(0.13), radius: 8, y: 2)
                    Image(systemName: file.isDirectory ? "folder.fill" : "doc.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.accentColor)
                }
                .padding(.top, 6)
                Text(file.name)
                    .font(.headline)
                    .padding(.top, 2)
                Text(loc.localized("Permissions"))
                    .font(.title2).bold()
                    .padding(.bottom, 2)
                PermissionMatrixView(perms: $perms, loc: loc, onChange: { permsString = permsToString(perms) })
                TextField("755", text: $permsString)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .frame(width: 80)
                    .multilineTextAlignment(.center)
                    .focused($isFocused)
                    .onChange(of: permsString) { val in
                        if let arr = stringToPerms(val) { perms = arr }
                    }
                if file.isDirectory {
                    Toggle(isOn: $recursive) {
                        Text(loc.localized("Apply recursively to all inside"))
                            .font(.footnote)
                    }
                    .toggleStyle(.checkbox)
                    .padding(.top, 2)
                }
                HStack(spacing: 16) {
                    Button(action: { isPresented = false }) {
                        Text(loc.localized("Cancel"))
                            .frame(minWidth: 90, minHeight: 34)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color.secondary.opacity(0.10))
                    )
                    .foregroundColor(.secondary)
                    Button(action: {
                        if let permsInt = UInt32(permsString, radix: 8) {
                            onSave(permsInt, recursive)
                            isPresented = false
                        }
                    }) {
                        Text(loc.localized("Save"))
                            .fontWeight(.semibold)
                            .frame(minWidth: 90, minHeight: 34)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill((permsString.count != 3 || UInt32(permsString, radix: 8) == nil) ? Color.accentColor.opacity(0.25) : Color.accentColor)
                    )
                    .foregroundColor(.white)
                    .opacity((permsString.count != 3 || UInt32(permsString, radix: 8) == nil) ? 0.6 : 1)
                    .disabled(permsString.count != 3 || UInt32(permsString, radix: 8) == nil)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
                .padding(.bottom, 4)
            }
            .frame(width: 320)
            .padding(.vertical, 12)
        }
        .frame(width: 340)
        .animation(.spring(response: 0.22, dampingFraction: 0.7), value: permsString)
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            // Инициализация при первом открытии
            if let mode = file.permissions, mode >= 0 && mode <= 0o7777 {
                let str = String(format: "%03o", mode & 0o777)
                permsString = str
                if let arr = stringToPerms(str) { perms = arr }
            } else {
                permsString = "755"
                perms = [[true, true, true], [true, false, true], [true, false, true]]
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { isFocused = true }
        }
    }
    // Вспомогательные функции:
    func permsToString(_ arr: [[Bool]]) -> String {
        let nums = arr.map { (rwx) -> Int in
            (rwx[0] ? 4 : 0) + (rwx[1] ? 2 : 0) + (rwx[2] ? 1 : 0)
        }
        return nums.map { String($0) }.joined()
    }
    func stringToPerms(_ str: String) -> [[Bool]]? {
        guard str.count == 3, let o = Int(String(str.prefix(1))), let g = Int(String(str.dropFirst().prefix(1))), let t = Int(String(str.suffix(1))) else { return nil }
        func bits(_ n: Int) -> [Bool] { [(n & 4) != 0, (n & 2) != 0, (n & 1) != 0] }
        return [bits(o), bits(g), bits(t)]
    }
}

struct PermissionMatrixView: View {
    @Binding var perms: [[Bool]]
    var loc: LocalizationManager
    var onChange: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<3) { i in
                VStack(spacing: 6) {
                    Text(loc.localized(i == 0 ? "Owner" : i == 1 ? "Group" : "Other"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    PermissionToggleView(label: "r", value: $perms[i][0])
                        .onChange(of: perms[i][0]) { _ in onChange() }
                    PermissionToggleView(label: "w", value: $perms[i][1])
                        .onChange(of: perms[i][1]) { _ in onChange() }
                    PermissionToggleView(label: "x", value: $perms[i][2])
                        .onChange(of: perms[i][2]) { _ in onChange() }
                }
                .frame(width: 60)
            }
        }
    }
}

struct PermissionToggleView: View {
    let label: String
    @Binding var value: Bool
    var body: some View {
        Toggle(isOn: $value) {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
        }
        .toggleStyle(.checkbox)
    }
}

struct UploadDropZone: View {
    var isUploading: Bool
    var upload: TransferTask?
    var loc: LocalizationManager
    var onDrop: ([NSItemProvider]) -> Bool
    var onCancel: (() -> Void)? = nil
    @State private var isTargeted = false
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isTargeted ? Color.accentColor.opacity(0.13) : Color(nsColor: NSColor.windowBackgroundColor).opacity(0.98))
                .shadow(radius: 4, y: 1)
            if isUploading, let upload = upload {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.up.doc")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 22, weight: .medium))
                    VStack(alignment: .leading, spacing: 2) {
                        if case let .upload(localURL, destPath) = upload.direction {
                            Text(localURL.lastPathComponent)
                                .font(.subheadline)
                                .bold()
                            Text(destPath)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        ProgressView(value: upload.progress)
                            .frame(width: 120)
                    }
                    Spacer()
                    Text(String(format: "%d%%", Int(upload.progress * 100)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let onCancel = onCancel {
                        Button(action: { onCancel() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help(loc.localized("Cancel transfer"))
                    }
                }
                .padding(.horizontal, 16)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "tray.and.arrow.down")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.accentColor)
                    Text(loc.localized("Drag files here to upload"))
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
        }
        .frame(height: 52)
        .onDrop(of: ["public.file-url"], isTargeted: $isTargeted, perform: onDrop)
        .animation(.easeInOut(duration: 0.18), value: isTargeted)
    }
}

struct InfoSheet: View {
    let file: RemoteFile
    @Binding var isPresented: Bool
    var loc: LocalizationManager
    @State private var detailedFile: RemoteFile? = nil
    @State private var isLoading = false
    @State private var error: String? = nil
    
    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.13))
                    .frame(width: 48, height: 48)
                    .shadow(color: Color.accentColor.opacity(0.13), radius: 6, y: 1)
                Image(systemName: file.isDirectory ? "folder.fill" : "doc.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .foregroundColor(.accentColor)
            }
            .padding(.top, 4)
            Text(file.name)
                .font(.title3).bold()
                .padding(.top, 2)
            Divider().padding(.horizontal, 8)
            
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(loc.localized("Loading file information..."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 80)
            } else if let error = error {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.title2)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 80)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    let displayFile = detailedFile ?? file
                    InfoRow(label: loc.localized("Type"), value: displayFile.isDirectory ? loc.localized("Folder") : loc.localized("File"))
                    InfoRow(label: loc.localized("Path"), value: displayFile.path, monospaced: true)
                    if !displayFile.isDirectory {
                        InfoRow(label: loc.localized("Size"), value: ByteCountFormatter.string(fromByteCount: displayFile.size, countStyle: .file))
                    }
                    InfoRow(label: loc.localized("Modified"), value: DateFormatter.localizedString(from: displayFile.modifiedDate, dateStyle: .medium, timeStyle: .short))
                    if let perms = displayFile.permissions {
                        InfoRow(label: loc.localized("Permissions"), value: String(format: "%03o", perms) + "  (" + permsString(perms) + ")", monospaced: true)
                    }
                }
                .padding(.horizontal, 8)
                .frame(maxWidth: 320)
            }
            
            Divider().padding(.horizontal, 8)
            Button(action: { isPresented = false }) {
                Text(loc.localized("Close"))
                    .fontWeight(.semibold)
                    .frame(minWidth: 110, minHeight: 36)
            }
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.accentColor.opacity(0.15))
            )
            .foregroundColor(.accentColor)
            .padding(.bottom, 2)
        }
        .frame(width: 340)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(nsColor: NSColor.windowBackgroundColor).opacity(0.98))
                .shadow(radius: 12, y: 2)
        )
        .animation(.spring(response: 0.22, dampingFraction: 0.7), value: isPresented)
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            loadFileInfo()
        }
    }
    
    private func loadFileInfo() {
        // Если у нас уже есть полная информация о файле, используем её
        if file.permissions != nil && file.size > 0 {
            detailedFile = file
            return
        }
        
        // Иначе загружаем информацию с сервера
        isLoading = true
        error = nil
        
        ConnectionManager.shared.getFileInfo(path: file.path) { detailedFile, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    self.error = error
                } else if let detailedFile = detailedFile {
                    self.detailedFile = detailedFile
                }
            }
        }
    }
    
    func permsString(_ perms: Int) -> String {
        let chars = ["r","w","x"]
        var str = ""
        for i in (0..<3).reversed() {
            let val = (perms >> (i*3)) & 0b111
            for j in 0..<3 {
                str += ((val & (1 << (2-j))) != 0) ? chars[j] : "-"
            }
        }
        return str
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var monospaced: Bool = false
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 90, alignment: .leading)
            Spacer()
            Text(value)
                .font(monospaced ? .system(.body, design: .monospaced) : .body)
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

// Диалог замены файла
struct ReplaceFileDialog: View {
    @Binding var isPresented: Bool
    let fileName: String
    let localURL: URL
    let destPath: String
    let onReplace: () -> Void
    let onSkip: () -> Void
    let onRetry: () -> Void
    var loc: LocalizationManager
    @State private var isHoverReplace = false
    @State private var isHoverSkip = false
    @State private var isHoverRetry = false
    
    var body: some View {
        ZStack {
            // Новый светлый blur-фон
            VisualEffectBlur()
                .opacity(0.85)
                .ignoresSafeArea()
                .transition(.opacity)
            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.13))
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.orange.opacity(0.13), radius: 8, y: 2)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.orange)
                }
                .padding(.top, 6)
                Text(loc.localized("File exists"))
                    .font(.title2).bold()
                Text(String(format: loc.localized("File '%@' already exists. What would you like to do?"), fileName))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                HStack(spacing: 14) {
                    Button(action: {
                        isPresented = false
                        onSkip()
                    }) {
                        Text(loc.localized("Skip"))
                            .frame(minWidth: 90, minHeight: 40)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.secondary.opacity(isHoverSkip ? 0.18 : 0.10))
                    )
                    .foregroundColor(.primary)
                    .onHover { isHoverSkip = $0 }
                    Button(action: {
                        isPresented = false
                        onRetry()
                    }) {
                        Text(loc.localized("Retry"))
                            .frame(minWidth: 90, minHeight: 40)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.blue.opacity(isHoverRetry ? 0.18 : 0.10))
                    )
                    .foregroundColor(.blue)
                    .onHover { isHoverRetry = $0 }
                    Button(action: {
                        isPresented = false
                        onReplace()
                    }) {
                        Text(loc.localized("Replace"))
                            .fontWeight(.semibold)
                            .frame(minWidth: 90, minHeight: 40)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isHoverReplace ? Color.orange : Color.orange.opacity(0.85))
                    )
                    .foregroundColor(.white)
                    .shadow(color: Color.orange.opacity(0.18), radius: 6, y: 2)
                    .onHover { isHoverReplace = $0 }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
                .padding(.bottom, 4)
            }
            .frame(width: 390)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(nsColor: NSColor.windowBackgroundColor).opacity(0.98))
                    .shadow(color: Color.black.opacity(0.13), radius: 24, y: 8)
            )
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: isPresented)
            .transition(.scale.combined(with: .opacity))
        }
        .animation(.spring(response: 0.22, dampingFraction: 0.7), value: isPresented)
    }
}

// Быстрые действия — отдельная структура
struct QuickActionsToolbar: View {
    let selectedFiles: Set<String>
    let manager: ConnectionManager
    let loc: LocalizationManager
    let onRename: (RemoteFile) -> Void
    let onDeselect: () -> Void
    let onDelete: () -> Void
    var body: some View {
        HStack(spacing: 10) {
            Button(action: {
                for path in selectedFiles { manager.download(path: path) }
            }) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 16, weight: .medium))
                Text(loc.localized("Download"))
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(AnimatedButtonStyle())
            .help(loc.localized("Download"))
            Button(action: {
                if let file = manager.remoteFiles.first(where: { selectedFiles.contains($0.path) }) {
                    onRename(file)
                }
            }) {
                Image(systemName: "pencil")
                    .font(.system(size: 15, weight: .medium))
                Text(loc.localized("Rename"))
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(AnimatedButtonStyle())
            .help(loc.localized("Rename"))
            Button(action: {
                let paths = manager.remoteFiles.filter { selectedFiles.contains($0.path) }.map { $0.path }
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(paths.joined(separator: "\n"), forType: .string)
            }) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 15, weight: .medium))
                Text(loc.localized("Copy path"))
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(AnimatedButtonStyle())
            .help(loc.localized("Copy path"))
            Divider()
                .frame(height: 22)
                .padding(.horizontal, 2)
            Button(action: { onDelete() }) {
                Image(systemName: "trash")
                    .font(.system(size: 15, weight: .medium))
                Text(loc.localized("Delete"))
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(AnimatedButtonStyle())
            .foregroundColor(.red)
            .help(loc.localized("Delete selected"))
            Divider()
                .frame(height: 22)
                .padding(.horizontal, 2)
            Button(action: { onDeselect() }) {
                Image(systemName: "rectangle.dashed")
                    .font(.system(size: 15, weight: .medium))
                Text(loc.localized("Deselect"))
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(AnimatedButtonStyle())
            .help(loc.localized("Deselect all"))
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: NSColor.windowBackgroundColor).opacity(0.98))
                .shadow(radius: 8, y: 1)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// Фокусируемый view для hotkey
struct FocusableView: NSViewRepresentable {
    @Binding var isFocused: Bool
    var onKeyDown: (NSEvent) -> Void
    func makeNSView(context: Context) -> NSView {
        let view = FocusableNSView()
        view.onKeyDown = onKeyDown
        DispatchQueue.main.async { view.window?.makeFirstResponder(view) }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        if isFocused { nsView.window?.makeFirstResponder(nsView) }
    }
    class FocusableNSView: NSView {
        var onKeyDown: ((NSEvent) -> Void)?
        override var acceptsFirstResponder: Bool { true }
        override func keyDown(with event: NSEvent) { onKeyDown?(event) }
    }
} 