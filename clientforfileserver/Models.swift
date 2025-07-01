import Foundation

struct Site: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var host: String
    var port: Int
    var user: String
    var protoRaw: String
    
    var proto: ConnectionManager.ProtocolType {
        protoRaw == "sftp" ? .sftp : .ftp
    }
}

struct RemoteFile: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let isDirectory: Bool
    let size: Int64
    let modifiedDate: Date
    let permissions: Int?
}

struct SyncProfile: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var localPath: String
    var remotePath: String
    
    enum Direction: String, Codable {
        case upload, download, bidirectional
    }
    var direction: Direction
    var rrule: String
}

class TransferTask: Identifiable, ObservableObject {
    enum Direction {
        case upload(localURL: URL, destPath: String)
        case download(path: String)
    }
    
    let id = UUID()
    let direction: Direction
    @Published var progress: Double = 0.0
    @Published var isPaused: Bool = false
    @Published var isCancelled: Bool = false
    var priority: Int
    
    init(direction: Direction, priority: Int = 0) {
        self.direction = direction
        self.priority = priority
    }
    
    func cancel() {
        isCancelled = true
    }
}

enum ProtocolSelection: String, CaseIterable, Identifiable {
    case sftp, ftp
    var id: String { rawValue }
} 