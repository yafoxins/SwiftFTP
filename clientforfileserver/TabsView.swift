import SwiftUI

struct TabsView: View {
    @EnvironmentObject var store: ProfileStore
    @ObservedObject var manager = ConnectionManager.shared
    @ObservedObject var loc = LocalizationManager.shared
    @State private var openServers: [Site] = []
    @State private var selectedTab: UUID? = nil
    @State private var showingConnectSheet = false
    @State private var showingProtocolSheet = false
    @State private var selectedProtocol: ConnectionManager.ProtocolType? = nil
    @State private var showingSettings = false
    @AppStorage("appLanguage") var appLanguage: String = TabsView.defaultLanguage()

    static func defaultLanguage() -> String {
        if let lang = Locale.preferredLanguages.first {
            return String(lang.prefix(2))
        } else {
            return "en"
        }
    }

    var body: some View {
        Group {
            if openServers.isEmpty {
                // Показываем WelcomeView если нет серверов
                WelcomeView(showingProtocolSheet: $showingProtocolSheet)
                    .transition(.opacity.combined(with: .scale))
            } else {
                // Показываем основное окно с серверами
                mainView
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: openServers.isEmpty)
        .onAppear {
            openServers = store.sites
            if let first = openServers.first {
                selectedTab = first.id
                ConnectionManager.shared.loadProfile(site: first, password: store.getPassword(for: first))
            }
            NotificationCenter.default.addObserver(forName: .didRemoveSite, object: nil, queue: .main) { notif in
                if let removed = notif.object as? Site, selectedTab == removed.id {
                    selectedTab = nil
                    ConnectionManager.shared.currentPath = "/"
                    ConnectionManager.shared.remoteFiles = []
                }
            }
        }
        .onReceive(store.$sites) { sites in
            let oldSelected = selectedTab
            openServers = sites
            
            // Если серверов нет, сбрасываем выбранный таб
            if sites.isEmpty {
                selectedTab = nil
                ConnectionManager.shared.disconnect()
                return
            }
            
            // Если добавлен новый сервер, выбрать его
            if let last = sites.last, sites.count > openServers.count {
                selectedTab = last.id
            } else if let old = oldSelected, sites.contains(where: { $0.id == old }) {
                selectedTab = old
            } else {
                selectedTab = sites.first?.id
            }
        }
        .sheet(isPresented: $showingProtocolSheet) {
            ProtocolSelectView { proto in
                selectedProtocol = proto
            }
        }
        .sheet(item: $selectedProtocol) { proto in
            ConnectView(manager: ConnectionManager.shared, selectedProtocol: proto)
                .environmentObject(store)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    private var mainView: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Горизонтальный таб-лист серверов
                HStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(openServers) { site in
                                ServerTabView(
                                    site: site,
                                    isSelected: selectedTab == site.id,
                                    onSelect: {
                                        if selectedTab != site.id {
                                            selectedTab = site.id
                                            ConnectionManager.shared.loadProfile(site: site, password: store.getPassword(for: site))
                                        }
                                    },
                                    onClose: {
                                        let idx = openServers.firstIndex(where: { $0.id == site.id })
                                        if let idx = idx {
                                            openServers.remove(at: idx)
                                            store.remove(site: site)
                                            if selectedTab == site.id {
                                                if openServers.indices.contains(idx) {
                                                    selectedTab = openServers[idx].id
                                                } else {
                                                    selectedTab = openServers.last?.id
                                                }
                                            }
                                        }
                                    }
                                )
                                .padding(.trailing, 2)
                            }
                        }
                    }
                    Spacer()
                    HStack(spacing: 0) {
                        Button(action: { showingProtocolSheet = true }) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 18, weight: .medium))
                                .padding(.vertical, 7)
                                .padding(.horizontal, 10)
                        }
                        .buttonStyle(AnimatedButtonStyle())
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 18, weight: .medium))
                                .padding(.vertical, 7)
                                .padding(.horizontal, 10)
                        }
                        .buttonStyle(AnimatedButtonStyle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .background(Color(nsColor: NSColor.windowBackgroundColor).opacity(0.92))
                Divider()
                // Основная область
                if let selectedTab = selectedTab, openServers.contains(where: { $0.id == selectedTab }) {
                    HStack(spacing: 0) {
                        FileListView()
                    }
                    .transition(.opacity)
                    .animation(.easeInOut, value: selectedTab)
                } else {
                    Spacer()
                }
            }
            // Статус загрузки - всегда видимый
            VStack(spacing: 0) {
                if let upload = ConnectionManager.shared.currentUpload {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.up.doc")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 16, weight: .medium))
                            VStack(alignment: .leading, spacing: 2) {
                                if case let .upload(localURL, destPath) = upload.direction {
                                    Text(localURL.lastPathComponent)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                    Text(destPath)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(format: "%d%%", Int(upload.progress * 100)))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.accentColor)
                                if upload.progress > 0 && upload.progress < 1 {
                                    Text("\(Int(upload.progress * 100))%")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        ProgressView(value: upload.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                            .scaleEffect(y: 0.8)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(nsColor: NSColor.windowBackgroundColor).opacity(0.95))
                            .shadow(radius: 4, y: 1)
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: upload.progress)
                } else {
                    // Пустое место для статуса когда нет загрузки
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 0)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 8)
            
            // Нижняя панель: статус справа, кнопка Reload чуть левее
            HStack(spacing: 12) {
                // Статус подключения
                HStack(spacing: 8) {
                    Circle()
                        .fill(manager.connectionState == .connected ? Color.green : (manager.connectionState == .connecting ? Color.yellow : Color.red))
                        .frame(width: 10, height: 10)
                    Text(statusText)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Color(nsColor: NSColor.windowBackgroundColor).opacity(0.85))
                .cornerRadius(12)
                .shadow(radius: 4)
                // Кнопка Reload справа от статуса
                Button(action: {
                    manager.reloadFiles()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .padding(8)
                        .background(Color(nsColor: NSColor.windowBackgroundColor).opacity(0.6))
                        .cornerRadius(10)
                        .shadow(radius: 1)
                }
                .buttonStyle(AnimatedButtonStyle())
                .opacity(0.7)
                .padding(.trailing, 8)
            }
            .padding(18)
        }
        .animation(.easeInOut, value: showingConnectSheet)
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

struct ServerTabView: View {
    let site: Site
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    @EnvironmentObject var store: ProfileStore
    var body: some View {
        HStack(spacing: 6) {
            Button(action: onSelect) {
                HStack(spacing: 4) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 15, weight: .medium))
                    Text(site.name)
                        .font(.system(size: 15, weight: .medium))
                    ProtocolBadge(proto: site.proto)
                    Text("\(site.host):\(site.port)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 7)
                .padding(.horizontal, 14)
                .background(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            Button(action: {
                store.remove(site: site)
                onClose()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(AnimatedButtonStyle())
            .padding(.trailing, 4)
        }
    }
}

struct ProtocolBadge: View {
    let proto: ConnectionManager.ProtocolType
    
    var body: some View {
        Text(proto.rawValue.uppercased())
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(proto == .sftp ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
            .foregroundColor(proto == .sftp ? .blue : .orange)
            .cornerRadius(4)
    }
} 
