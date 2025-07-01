import SwiftUI

struct SidebarView: View {
    var site: Site
    @EnvironmentObject var store: ProfileStore
    @ObservedObject private var manager = ConnectionManager.shared
    @ObservedObject var loc = LocalizationManager.shared

    var body: some View {
        List {
            Section(header: Text(loc.localized("Connection status")).font(.headline)) {
                HStack {
                    Circle()
                        .fill(manager.connectionState == .connected ? Color.green : (manager.connectionState == .connecting ? Color.yellow : Color.red))
                        .frame(width: 8, height: 8)
                    Text(statusText)
                        .font(.caption)
                }
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle(site.name)
    }

    var statusText: String {
        switch manager.connectionState {
        case .connecting:
            return loc.localized("Connecting...")
        case .connected:
            if let name = manager.connectedServerName {
                return loc.localized("Connected") + " (" + name + ")"
            } else {
                return loc.localized("Connected")
            }
        case .failed:
            return loc.localized("Connection failed")
        case .disconnected:
            return loc.localized("Disconnected")
        }
    }
} 