import SwiftUI

struct ConnectView: View {
    @EnvironmentObject var store: ProfileStore
    @ObservedObject var manager: ConnectionManager
    @Environment(\.presentationMode) var presentation
    @ObservedObject var loc = LocalizationManager.shared

    var onConnect: ((Site) -> Void)? = nil
    var selectedProtocol: ConnectionManager.ProtocolType

    @State private var name = ""
    @State private var host = ""
    @State private var port = "22"
    @State private var user = ""
    @State private var password = ""

    var body: some View {
        VStack {
            Spacer(minLength: 12)
            VStack(spacing: 16) {
                LinearGradient(gradient: Gradient(colors: [Color.accentColor, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .mask(
                        Image(systemName: "server.rack")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                    )
                    .frame(width: 36, height: 36)
                    .shadow(radius: 2)
                    .padding(.top, 4)
                Text(loc.localized("Add Server"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .shadow(radius: 1)
                InputFieldsView
            }
            .padding(.horizontal, 4)
            HStack(spacing: 14) {
                Button(action: {
                    presentation.wrappedValue.dismiss()
                }) {
                    Text(loc.localized("Cancel"))
                        .fontWeight(.medium)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44)
                        .background(Color.gray.opacity(0.13))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
                .buttonStyle(AnimatedButtonStyle())
                Button(action: {
                    if let existing = store.findDuplicate(host: host, port: Int(port) ?? 22, user: user) {
                        manager.loadProfile(site: existing, password: password)
                        onConnect?(existing)
                        presentation.wrappedValue.dismiss()
                        return
                    }
                    let site = Site(
                        id: UUID(),
                        name: name,
                        host: host,
                        port: Int(port) ?? 22,
                        user: user,
                        protoRaw: selectedProtocol == .sftp ? "sftp" : "ftp"
                    )
                    store.add(site: site, password: password)
                    manager.loadProfile(site: site, password: password)
                    onConnect?(site)
                    presentation.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text(loc.localized("Save & Connect"))
                            .fontWeight(.semibold)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(AnimatedButtonStyle())
                .disabled(name.isEmpty || host.isEmpty || user.isEmpty || port.isEmpty)
            }
            .padding(.top, 8)
        }
        .padding(18)
        .background(
            VisualEffectBlur()
                .background(Color.white.opacity(0.90))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.accentColor.opacity(0.10), lineWidth: 1.2)
        )
        .animation(.easeInOut, value: name + host + port + user + password)
        .frame(width: 340, height: 400)
    }

    private var InputFieldsView: some View {
        VStack(spacing: 10) {
            TextField(loc.localized("Server Name"), text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField(loc.localized("Host"), text: $host)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField(loc.localized("Port"), text: $port)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField(loc.localized("Username"), text: $user)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            SecureField(loc.localized("Password"), text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
} 