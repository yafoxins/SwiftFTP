import SwiftUI

class ProfileStore: ObservableObject {
    @Published var sites: [Site] = []
    private let defaultsKey = "savedSites"
    
    init() {
        loadSites()
    }
    
    func loadSites() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([Site].self, from: data) else {
            return
        }
        sites = decoded
    }
    
    func saveSites() {
        if let data = try? JSONEncoder().encode(sites) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
    
    func findDuplicate(host: String, port: Int, user: String) -> Site? {
        return sites.first { $0.host == host && $0.port == port && $0.user == user }
    }
    
    func add(site: Site, password: String) {
        if findDuplicate(host: site.host, port: site.port, user: site.user) == nil {
            sites.append(site)
            saveSites()
            KeychainHelper.shared.save(password: password, account: site.id.uuidString)
        }
    }
    
    func remove(site: Site) {
        sites.removeAll { $0.id == site.id }
        saveSites()
        NotificationCenter.default.post(name: .didRemoveSite, object: site)
    }
    
    func getPassword(for site: Site) -> String? {
        return KeychainHelper.shared.readPassword(account: site.id.uuidString)
    }
}

extension Notification.Name {
    static let didRemoveSite = Notification.Name("didRemoveSite")
} 