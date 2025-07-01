import Foundation
import Combine
import SwiftUI

class ConnectionManager: ObservableObject {
    static let shared = ConnectionManager()
    
    enum ProtocolType: String, Codable, Identifiable, CaseIterable {
        case ftp, sftp
        var id: String { rawValue }
    }
    
    enum ConnectionState: String {
        case disconnected, connecting, connected, failed
    }
    
    @Published var isConnected = false
    @Published var remoteFiles: [RemoteFile] = []
    @Published var currentPath = "/"
    @Published var connectionState: ConnectionState = .disconnected
    @Published var connectedServerName: String? = nil
    @Published var error: String? = nil
    @Published var currentUpload: TransferTask? = nil
    @Published var uploadQueue: [TransferTask] = []
    
    private var currentSite: Site?
    private var sftpManager: SFTPManager?
    private var ftpManager: FTPManager?
    
    private var pathCancellable: AnyCancellable?
    private var isLoadingFiles = false
    private var isInitialConnection = false
    private var currentRequestId = UUID() // Для отмены старых запросов
    
    var loadingFiles: Bool { isLoadingFiles }
    
    var totalUploadProgress: Double {
        guard !uploadQueue.isEmpty else { return 0 }
        let sum = uploadQueue.reduce(0.0) { $0 + $1.progress }
        return sum / Double(uploadQueue.count)
    }
    
    init() {
        pathCancellable = $currentPath
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main) // Добавляем задержку
            .sink { [weak self] _ in
                if !(self?.isInitialConnection ?? false) {
                    self?.reloadFiles()
                }
            }
    }
    
    func loadProfile(site: Site, password: String? = nil) {
        print("[ConnectionManager] loadProfile: site=\(site), password=\(password != nil ? "***" : "nil")")
        currentSite = site
        connect(to: site, password: password)
    }
    
    private func connect(to site: Site, password: String? = nil) {
        print("[ConnectionManager] connect: site=\(site), password=\(password != nil ? "***" : "nil")")
        setConnectionState(.connecting)
        connectedServerName = site.name
        isConnected = false
        remoteFiles = []
        error = nil
        isInitialConnection = true
        
        switch site.proto {
        case .sftp:
            let sftp = SFTPManager()
            print("[ConnectionManager] SFTP selected")
            sftp.connect(host: site.host, port: site.port, username: site.user, password: password ?? "") { [weak self] success in
                DispatchQueue.main.async {
                    print("[ConnectionManager] SFTP connect result: \(success), error=\(sftp.error ?? "nil")")
                    self?.isConnected = success
                    self?.setConnectionState(success ? .connected : .failed)
                    self?.connectedServerName = success ? site.name : nil
                    self?.error = sftp.error
                    if success {
                        print("[ConnectionManager] SFTP: loading file list...")
                        DispatchQueue.main.async {
                            self?.currentPath = "/"
                            self?.reloadFilesAfterConnect()
                            self?.isInitialConnection = false
                            self?.setConnectedStateIfNeeded()
                        }
                    } else {
                        self?.isInitialConnection = false
                    }
                }
            }
            self.sftpManager = sftp
            self.ftpManager = nil
        case .ftp:
            let ftp = FTPManager()
            print("[ConnectionManager] FTP selected")
            ftp.connect(host: site.host, port: site.port, username: site.user, password: password ?? "") { [weak self] success in
                DispatchQueue.main.async {
                    print("[ConnectionManager] FTP connect result: \(success), error=\(ftp.error ?? "nil")")
                    self?.isConnected = success
                    self?.setConnectionState(success ? .connected : .failed)
                    self?.connectedServerName = success ? site.name : nil
                    self?.error = ftp.error
                    if success {
                        print("[ConnectionManager] FTP: loading file list...")
                        self?.currentPath = "/"
                        ftp.listFiles(path: "/") { files in
                            DispatchQueue.main.async {
                                print("[ConnectionManager] FTP: files loaded: \(files.count)")
                                self?.remoteFiles = files
                                self?.isInitialConnection = false
                                self?.setConnectedStateIfNeeded()
                            }
                        }
                    } else {
                        self?.isInitialConnection = false
                    }
                }
            }
            self.ftpManager = ftp
            self.sftpManager = nil
        }
    }
    
    func disconnect() {
        sftpManager?.disconnect()
        ftpManager?.disconnect()
        isConnected = false
        connectionState = .disconnected
        connectedServerName = nil
        remoteFiles = []
        isInitialConnection = false
    }
    
    private func loadFiles() {
        // Simulate loading files
        let mockFiles = [
            RemoteFile(name: "Documents", path: "/Documents", isDirectory: true, size: 0, modifiedDate: Date(), permissions: nil),
            RemoteFile(name: "readme.txt", path: "/readme.txt", isDirectory: false, size: 1024, modifiedDate: Date(), permissions: nil),
            RemoteFile(name: "config.json", path: "/config.json", isDirectory: false, size: 2048, modifiedDate: Date(), permissions: nil)
        ]
        
        DispatchQueue.main.async {
            self.remoteFiles = mockFiles
        }
    }
    
    func download(path: String) {
        // Simulate download
        print("Downloading: \(path)")
    }
    
    func upload(localURL: URL, destPath: String) {
        guard let proto = currentSite?.proto else { return }
        switch proto {
        case .sftp:
            let fileName = localURL.lastPathComponent
            var remotePath = destPath
            if !remotePath.hasSuffix("/") { remotePath += "/" }
            remotePath += fileName
            let task = TransferTask(direction: .upload(localURL: localURL, destPath: remotePath))
            self.uploadQueue.append(task)
            if self.uploadQueue.count == 1 {
                startNextUpload()
            }
        case .ftp:
            // TODO: FTP upload
            print("[ConnectionManager] FTP upload not implemented")
        }
    }
    
    private func startNextUpload() {
        guard let task = uploadQueue.first else { return }
        guard let proto = currentSite?.proto else { return }
        switch proto {
        case .sftp:
            if case let .upload(localURL, remotePath) = task.direction {
                self.currentUpload = task
                sftpManager?.uploadFileWithProgress(localPath: localURL.path, remotePath: remotePath, progress: { percent in
                    DispatchQueue.main.async {
                        if task.isCancelled {
                            self.currentUpload = nil
                            self.uploadQueue.removeFirst()
                            self.startNextUpload()
                            return
                        }
                        task.progress = percent
                    }
                }, completion: { success, error in
                    DispatchQueue.main.async {
                        if !success && !task.isCancelled {
                            self.error = error
                        }
                        self.currentUpload = nil
                        self.uploadQueue.removeFirst()
                        self.reloadFiles()
                        self.startNextUpload()
                    }
                })
            }
        case .ftp:
            // TODO: FTP upload
            break
        }
    }
    
    func delete(path: String) -> Bool {
        guard let proto = currentSite?.proto else { return false }
        switch proto {
        case .sftp:
            sftpManager?.removeFile(remotePath: path) { success, error in
                DispatchQueue.main.async {
                    if !success {
                        self.error = error
                    }
                    self.reloadFiles()
                }
            }
            return true
        case .ftp:
            // TODO: FTP удаление
            return false
        }
    }
    
    func move(from: String, to: String) -> Bool {
        guard let proto = currentSite?.proto else { return false }
        switch proto {
        case .sftp:
            sftpManager?.moveFile(from: from, to: to) { success, error in
                DispatchQueue.main.async {
                    if !success {
                        self.error = error
                    }
                    self.reloadFiles()
                }
            }
            return true
        case .ftp:
            // TODO: FTP переименование
            return false
        }
    }
    
    func copy(from: String, to: String) -> Bool {
        // Simulate copy
        print("Copying: \(from) to \(to)")
        return true
    }
    
    func executeSSH(cmd: String) -> Bool {
        // Simulate SSH command execution
        print("Executing SSH command: \(cmd)")
        return true
    }
    
    func changeDirectory(to path: String) {
        guard isConnected else { return }
        guard !isLoadingFiles else { return }
        guard path != currentPath else { return }
        
        print("[ConnectionManager] changeDirectory: \(currentPath) -> \(path)")
        currentPath = path
        // НЕ вызываем reloadFiles() здесь, так как pathCancellable сделает это автоматически
    }

    func goUp() {
        guard isConnected else { return }
        if currentPath == "/" || currentPath == "." { return }
        var comps = currentPath.split(separator: "/").map(String.init)
        if comps.count > 1 {
            comps.removeLast()
            let newPath = "/" + comps.joined(separator: "/")
            changeDirectory(to: newPath)
        } else {
            changeDirectory(to: "/")
        }
    }

    func reloadFiles() {
        guard isConnected else { return }
        guard !isLoadingFiles else { 
            print("[ConnectionManager] reloadFiles: already loading, skipping")
            return 
        }
        let requestId = UUID()
        currentRequestId = requestId
        isLoadingFiles = true
        print("[ConnectionManager] reloadFiles: starting for path '\(currentPath)' with requestId: \(requestId)")
        switch currentSite?.proto {
        case .sftp:
            sftpManager?.listFiles(path: currentPath.isEmpty ? "." : currentPath) { [weak self] files in
                DispatchQueue.main.async {
                    guard let self = self, self.currentRequestId == requestId else {
                        print("[ConnectionManager] reloadFiles: request outdated, ignoring")
                        return
                    }
                    print("[ConnectionManager] reloadFiles: completed for path '\(self.currentPath)' with \(files.count) files")
                    self.remoteFiles = files
                    self.isLoadingFiles = false
                    if files.isEmpty && !(self.sftpManager?.isConnected ?? true) && !self.isConnected {
                        self.setConnectionState(.disconnected)
                        self.isConnected = false
                    } else {
                        self.setConnectionState(.connected)
                    }
                    self.setConnectedStateIfNeeded()
                }
            }
        case .ftp:
            ftpManager?.listFiles(path: currentPath.isEmpty ? "/" : currentPath) { [weak self] files in
                DispatchQueue.main.async {
                    guard let self = self, self.currentRequestId == requestId else {
                        print("[ConnectionManager] reloadFiles: request outdated, ignoring")
                        return
                    }
                    print("[ConnectionManager] reloadFiles: completed for path '\(self.currentPath)' with \(files.count) files")
                    self.remoteFiles = files
                    self.isLoadingFiles = false
                    if files.isEmpty && !self.isConnected {
                        self.setConnectionState(.disconnected)
                    } else {
                        self.setConnectionState(.connected)
                    }
                    self.setConnectedStateIfNeeded()
                }
            }
        default:
            isLoadingFiles = false
            break
        }
        NotificationCenter.default.post(name: NSNotification.Name("ResetSelectionAfterReload"), object: nil)
    }
    
    private func reloadFilesAfterConnect() {
        guard isConnected else { return }
        isLoadingFiles = true
        
        let requestId = UUID()
        currentRequestId = requestId
        
        print("[ConnectionManager] reloadFilesAfterConnect: starting for path '\(currentPath)' with requestId: \(requestId)")
        
        switch currentSite?.proto {
        case .sftp:
            sftpManager?.listFiles(path: currentPath.isEmpty ? "." : currentPath) { [weak self] files in
                DispatchQueue.main.async {
                    // Проверяем, что это все еще актуальный запрос
                    guard let self = self, self.currentRequestId == requestId else {
                        print("[ConnectionManager] reloadFilesAfterConnect: request outdated, ignoring")
                        return
                    }
                    
                    print("[ConnectionManager] reloadFilesAfterConnect: completed for path '\(self.currentPath)' with \(files.count) files")
                    self.remoteFiles = files
                    self.isLoadingFiles = false
                    if files.isEmpty && !(self.sftpManager?.isConnected ?? true) {
                        self.setConnectionState(.failed)
                        self.isConnected = false
                    } else {
                        self.setConnectionState(.connected)
                    }
                    self.setConnectedStateIfNeeded()
                }
            }
        case .ftp:
            ftpManager?.listFiles(path: currentPath.isEmpty ? "/" : currentPath) { [weak self] files in
                DispatchQueue.main.async {
                    // Проверяем, что это все еще актуальный запрос
                    guard let self = self, self.currentRequestId == requestId else {
                        print("[ConnectionManager] reloadFilesAfterConnect: request outdated, ignoring")
                        return
                    }
                    
                    print("[ConnectionManager] reloadFilesAfterConnect: completed for path '\(self.currentPath)' with \(files.count) files")
                    self.remoteFiles = files
                    self.isLoadingFiles = false
                    self.setConnectionState(.connected)
                    self.setConnectedStateIfNeeded()
                }
            }
        default:
            isLoadingFiles = false
            break
        }
    }
    
    private func setConnectionState(_ state: ConnectionState) {
        DispatchQueue.main.async {
            print("[DEBUG] setConnectionState: \(state.rawValue)")
            self.connectionState = state
        }
    }
    
    private func setConnectedStateIfNeeded() {
        DispatchQueue.main.async {
            if self.isConnected {
                self.setConnectionState(.connected)
            }
        }
    }
    
    func changePermissions(path: String, permissions: UInt32, recursive: Bool, completion: @escaping (Bool, String?) -> Void) {
        guard let proto = currentSite?.proto else { completion(false, "Нет подключения"); return }
        switch proto {
        case .sftp:
            sftpManager?.changePermissions(path: path, permissions: permissions, recursive: recursive, completion: completion)
        case .ftp:
            completion(false, "Изменение прав для FTP не поддерживается")
        }
    }
    
    // Проверка существования файла
    func fileExists(path: String, completion: @escaping (Bool, String?) -> Void) {
        guard let proto = currentSite?.proto else { completion(false, "Нет подключения"); return }
        switch proto {
        case .sftp:
            sftpManager?.fileExists(path: path, completion: completion)
        case .ftp:
            // TODO: FTP проверка существования
            completion(false, "Проверка существования для FTP не поддерживается")
        }
    }
    
    // Получение свойств файла
    func getFileInfo(path: String, completion: @escaping (RemoteFile?, String?) -> Void) {
        guard let proto = currentSite?.proto else { completion(nil, "Нет подключения"); return }
        switch proto {
        case .sftp:
            sftpManager?.getFileInfo(path: path, completion: completion)
        case .ftp:
            // TODO: FTP получение свойств
            completion(nil, "Получение свойств для FTP не поддерживается")
        }
    }
    
    // Переименование файла
    func rename(from: String, to: String) {
        guard let proto = currentSite?.proto else { return }
        switch proto {
        case .sftp:
            // Получаем путь к папке и новое имя
            let fromPath = from
            let toDir = (from as NSString).deletingLastPathComponent
            let toPath = toDir + "/" + to
            
            sftpManager?.moveFile(from: fromPath, to: toPath) { success, error in
                DispatchQueue.main.async {
                    if !success {
                        self.error = error
                    }
                    self.reloadFiles()
                }
            }
        case .ftp:
            // TODO: FTP переименование
            print("[ConnectionManager] FTP rename not implemented")
        }
    }
} 