import Foundation
import mft

class SFTPManager: ObservableObject {
    @Published var files: [RemoteFile] = []
    @Published var isConnected: Bool = false
    @Published var error: String? = nil

    private var sftp: MFTSftpConnection?
    private var connectionSemaphore = DispatchSemaphore(value: 1)
    private var operationQueue = DispatchQueue(label: "sftp.operations", qos: .userInitiated)
    private var currentOperationId = UUID()

    func connect(host: String, port: Int, username: String, password: String, completion: @escaping (Bool) -> Void) {
        operationQueue.async {
            self.connectionSemaphore.wait()
            defer { self.connectionSemaphore.signal() }
            
            do {
                let sftp = MFTSftpConnection(hostname: host, port: port, username: username, password: password)
                try sftp.connect()
                try sftp.authenticate()
                
                DispatchQueue.main.async {
                    self.sftp = sftp
                    self.isConnected = true
                    self.error = nil
                    completion(true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    self.isConnected = false
                    completion(false)
                }
            }
        }
    }

    func listFiles(path: String = ".", completion: @escaping ([RemoteFile]) -> Void) {
        print("[SFTPManager] listFiles called with path: \(path)")
        
        // Проверяем состояние соединения
        guard let sftp = sftp, isConnected else {
            print("[SFTPManager] sftp is nil or not connected")
            DispatchQueue.main.async {
                self.isConnected = false
                completion([])
            }
            return
        }
        
        let operationId = UUID()
        currentOperationId = operationId
        
        operationQueue.async {
            self.connectionSemaphore.wait()
            defer { self.connectionSemaphore.signal() }
            
            // Проверяем, что операция все еще актуальна
            guard self.currentOperationId == operationId else {
                print("[SFTPManager] Operation cancelled, ignoring")
                return
            }
            
            do {
                // Проверяем, что соединение все еще активно
                guard self.isConnected, self.sftp != nil else {
                    print("[SFTPManager] Connection lost during operation")
                    DispatchQueue.main.async {
                        self.isConnected = false
                        completion([])
                    }
                    return
                }
                
                let items = try sftp.contentsOfDirectory(atPath: path, maxItems: 0)
                print("[SFTPManager] contentsOfDirectory returned \(items.count) items for path: \(path)")
                
                // Проверяем еще раз, что операция актуальна
                guard self.currentOperationId == operationId else {
                    print("[SFTPManager] Operation cancelled after directory listing, ignoring")
                    return
                }
                
                let basePath: String
                if path == "." || path.isEmpty {
                    basePath = "/"
                } else {
                    basePath = path.hasSuffix("/") ? path : path + "/"
                }
                
                let remoteFiles = items.map { item in
                    print("[SFTPManager] item: \(item.filename), isDir: \(item.isDirectory), size: \(item.size), permissions: \(item.permissions)")
                    let octalPerms = Int(item.permissions) & 0o777 // только rwxrwxrwx
                    return RemoteFile(
                        name: item.filename,
                        path: basePath + item.filename,
                        isDirectory: item.isDirectory,
                        size: Int64(item.size),
                        modifiedDate: item.mtime,
                        permissions: octalPerms
                    )
                }
                
                DispatchQueue.main.async {
                    // Финальная проверка актуальности операции
                    guard self.currentOperationId == operationId else {
                        print("[SFTPManager] Operation cancelled before completion, ignoring")
                        return
                    }
                    
                    self.files = remoteFiles
                    print("[SFTPManager] remoteFiles.count = \(remoteFiles.count)")
                    completion(remoteFiles)
                }
            } catch {
                print("[SFTPManager] ERROR: \(error)")
                DispatchQueue.main.async {
                    // Проверяем, что операция все еще актуальна
                    guard self.currentOperationId == operationId else {
                        print("[SFTPManager] Operation cancelled during error handling, ignoring")
                        return
                    }
                    
                    // Проверяем, является ли ошибка связанной с соединением
                    if let nsError = error as NSError?, nsError.domain == "sftp" && nsError.code == 1002 {
                        print("[SFTPManager] Socket error detected, marking as disconnected")
                        self.isConnected = false
                        self.sftp = nil
                    }
                    completion([])
                }
            }
        }
    }

    func uploadFile(localPath: String, remotePath: String, completion: @escaping (Bool, String?) -> Void) {
        guard let sftp = sftp, isConnected else {
            completion(false, "Нет подключения")
            return
        }
        
        operationQueue.async {
            self.connectionSemaphore.wait()
            defer { self.connectionSemaphore.signal() }
            
            do {
                let inStream = InputStream(fileAtPath: localPath)!
                let srcAttrs = try FileManager.default.attributesOfItem(atPath: localPath) as NSDictionary
                try sftp.write(stream: inStream, toFileAtPath: remotePath, append: false) { uploaded in
                    NSLog("Upload progress: %d / %d", uploaded, srcAttrs.fileSize())
                    return true
                }
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }

    func uploadFileWithProgress(localPath: String, remotePath: String, progress: @escaping (Double) -> Void, completion: @escaping (Bool, String?) -> Void) {
        guard let sftp = sftp, isConnected else {
            completion(false, "Нет подключения")
            return
        }
        operationQueue.async {
            self.connectionSemaphore.wait()
            defer { self.connectionSemaphore.signal() }
            do {
                let inStream = InputStream(fileAtPath: localPath)!
                let srcAttrs = try FileManager.default.attributesOfItem(atPath: localPath) as NSDictionary
                let total = srcAttrs.fileSize()
                try sftp.write(stream: inStream, toFileAtPath: remotePath, append: false) { uploaded in
                    let percent = total > 0 ? Double(uploaded) / Double(total) : 0
                    DispatchQueue.main.async {
                        progress(percent)
                    }
                    return true
                }
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }

    func downloadFile(remotePath: String, localPath: String, completion: @escaping (Bool, String?) -> Void) {
        guard let sftp = sftp, isConnected else {
            completion(false, "Нет подключения")
            return
        }
        
        operationQueue.async {
            self.connectionSemaphore.wait()
            defer { self.connectionSemaphore.signal() }
            
            do {
                let outStream = OutputStream(toFileAtPath: localPath, append: false)!
                try sftp.contents(atPath: remotePath, toStream: outStream, fromPosition: 0) { downloaded, total in
                    NSLog("Download progress: %d / %d", downloaded, total)
                    return true
                }
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }

    func removeFile(remotePath: String, completion: @escaping (Bool, String?) -> Void) {
        guard let sftp = sftp, isConnected else {
            completion(false, "Нет подключения")
            return
        }
        
        operationQueue.async {
            self.connectionSemaphore.wait()
            defer { self.connectionSemaphore.signal() }
            
            do {
                try sftp.removeFile(atPath: remotePath)
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }

    func moveFile(from: String, to: String, completion: @escaping (Bool, String?) -> Void) {
        guard let sftp = sftp, isConnected else {
            completion(false, "Нет подключения")
            return
        }
        operationQueue.async {
            self.connectionSemaphore.wait()
            defer { self.connectionSemaphore.signal() }
            do {
                try sftp.moveItem(atPath: from, toPath: to)
                DispatchQueue.main.async { completion(true, nil) }
            } catch {
                DispatchQueue.main.async { completion(false, error.localizedDescription) }
            }
        }
    }

    func disconnect() {
        operationQueue.async {
            self.connectionSemaphore.wait()
            defer { self.connectionSemaphore.signal() }
            
            self.sftp?.disconnect()
            self.sftp = nil
            
            DispatchQueue.main.async {
                self.isConnected = false
            }
        }
    }

    func canonicalPath(forPath path: String) throws -> String {
        guard let sftp = sftp, isConnected else { 
            throw NSError(domain: "SFTP", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not connected"]) 
        }
        return try sftp.canonicalPath(forPath: path)
    }

    func changePermissions(path: String, permissions: UInt32, recursive: Bool, completion: @escaping (Bool, String?) -> Void) {
        guard let sftp = sftp, isConnected else {
            completion(false, "Нет подключения")
            return
        }
        operationQueue.async {
            self.connectionSemaphore.wait()
            defer { self.connectionSemaphore.signal() }
            do {
                try sftp.set(permissions: permissions, forPath: path)
                if recursive {
                    let items = try sftp.contentsOfDirectory(atPath: path, maxItems: 0)
                    for item in items {
                        let itemPath = (path as NSString).appendingPathComponent(item.filename)
                        if item.isDirectory {
                            self.changePermissions(path: itemPath, permissions: permissions, recursive: true, completion: {_,_ in })
                        } else {
                            try? sftp.set(permissions: permissions, forPath: itemPath)
                        }
                    }
                }
                DispatchQueue.main.async { completion(true, nil) }
            } catch {
                DispatchQueue.main.async { completion(false, error.localizedDescription) }
            }
        }
    }
    
    // Проверка существования файла
    func fileExists(path: String, completion: @escaping (Bool, String?) -> Void) {
        guard let sftp = sftp, isConnected else {
            completion(false, "Нет подключения")
            return
        }
        operationQueue.async {
            self.connectionSemaphore.wait()
            defer { self.connectionSemaphore.signal() }
            do {
                // Пытаемся получить информацию о файле
                let _ = try sftp.infoForFile(atPath: path)
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, nil) // Файл не существует
                }
            }
        }
    }
    
    // Получение свойств файла (для InfoSheet)
    func getFileInfo(path: String, completion: @escaping (RemoteFile?, String?) -> Void) {
        guard let sftp = sftp, isConnected else {
            completion(nil, "Нет подключения")
            return
        }
        operationQueue.async {
            self.connectionSemaphore.wait()
            defer { self.connectionSemaphore.signal() }
            do {
                let item = try sftp.infoForFile(atPath: path)
                let fileName = (path as NSString).lastPathComponent
                let octalPerms = Int(item.permissions) & 0o777
                
                let remoteFile = RemoteFile(
                    name: fileName,
                    path: path,
                    isDirectory: item.isDirectory,
                    size: Int64(item.size),
                    modifiedDate: item.mtime,
                    permissions: octalPerms
                )
                
                DispatchQueue.main.async {
                    completion(remoteFile, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error.localizedDescription)
                }
            }
        }
    }
} 

