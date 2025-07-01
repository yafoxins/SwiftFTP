import Foundation

class SpeedLimiter {
    static let shared = SpeedLimiter()
    
    private var uploadLimit: Int = 0    // Bytes per second
    private var downloadLimit: Int = 0  // Bytes per second
    
    private init() {}
    
    func setUploadLimit(_ bytesPerSec: Int) {
        uploadLimit = bytesPerSec
    }
    
    func setDownloadLimit(_ bytesPerSec: Int) {
        downloadLimit = bytesPerSec
    }
    
    func getLimits() -> (upload: Int, download: Int) {
        return (uploadLimit, downloadLimit)
    }
    
    func throttle(bytesRead: Int, lastTime: inout Date) {
        guard downloadLimit > 0 else { return }
        let interval = Date().timeIntervalSince(lastTime)
        let expected = Double(bytesRead) / Double(downloadLimit)
        if interval < expected {
            Thread.sleep(forTimeInterval: expected - interval)
        }
        lastTime = Date()
    }
    
    func throttleUpload(bytesSent: Int, lastTime: inout Date) {
        guard uploadLimit > 0 else { return }
        let interval = Date().timeIntervalSince(lastTime)
        let expected = Double(bytesSent) / Double(uploadLimit)
        if interval < expected {
            Thread.sleep(forTimeInterval: expected - interval)
        }
        lastTime = Date()
    }
} 