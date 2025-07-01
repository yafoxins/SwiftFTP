import SwiftUI

struct WelcomeView: View {
    @Binding var showingProtocolSheet: Bool
    @ObservedObject var loc = LocalizationManager.shared
    let supportedLanguages = ["en", "ru"]
    @AppStorage("appLanguage") var appLanguage: String = {
        if let lang = Locale.preferredLanguages.first {
            return String(lang.prefix(2))
        } else {
            return "en"
        }
    }()
    
    var body: some View {
        ZStack {
            // Градиентный фон с blur
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(nsColor: NSColor.windowBackgroundColor),
                    Color(nsColor: NSColor.controlBackgroundColor).opacity(0.3)
                ]),
                startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VisualEffectBlur()
                .ignoresSafeArea()
                .opacity(0.7)
            
            HStack(spacing: 0) {
                // Левая панель — профиль/о приложении
                VStack(spacing: 32) {
                    Spacer()
                    Image(systemName: "externaldrive.connected.to.line.below")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.accentColor, .white]), startPoint: .top, endPoint: .bottom))
                        .shadow(radius: 12)
                    Text("FTP/SFTP Client")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(radius: 4)
                    Text("v1.0.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.blue)
                            Text(loc.localized("Author:"))
                                .foregroundColor(.secondary)
                            Button(action: {
                                if let url = URL(string: "https://t.me/yafoxin") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                Text("@yafoxin")
                                    .underline()
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(AnimatedButtonStyle())
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "link")
                                .foregroundColor(.gray)
                            Text(loc.localized("GitHub:"))
                                .foregroundColor(.secondary)
                            Button(action: {
                                if let url = URL(string: "https://github.com/yafoxins") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                Text("github.com/yafoxins")
                                    .underline()
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(AnimatedButtonStyle())
                        }
                    }
                    .font(.footnote)
                    .padding(.top, 8)
                    Spacer()
                    HStack {
                        HStack(spacing: 0) {
                            ForEach(supportedLanguages, id: \.self) { lang in
                                Button(action: { loc.setLanguage(lang) }) {
                                    HStack(spacing: 6) {
                                        if appLanguage == lang { Image(systemName: "globe") }
                                        Text(loc.localized(lang == "ru" ? "Русский" : "English"))
                                            .font(.footnote)
                                            .fontWeight(appLanguage == lang ? .bold : .regular)
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 18)
                                    .background(appLanguage == lang ? Color.accentColor.opacity(0.18) : Color.clear)
                                    .foregroundColor(appLanguage == lang ? .accentColor : .primary)
                                    .cornerRadius(10)
                                    .shadow(color: appLanguage == lang ? Color.accentColor.opacity(0.18) : .clear, radius: 6, y: 2)
                                    .animation(.spring(response: 0.22, dampingFraction: 0.6), value: appLanguage == lang)
                                }
                                .buttonStyle(AnimatedButtonStyle())
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(nsColor: NSColor.windowBackgroundColor).opacity(0.7))
                                .shadow(radius: 8, y: 2)
                        )
                        .padding(.leading, 8)
                        Spacer()
                        Button(action: { NSApp.terminate(nil) }) {
                            Image(systemName: "power")
                                .font(.system(size: 18, weight: .medium))
                                .padding(10)
                                .background(Color.accentColor.opacity(0.13))
                                .foregroundColor(.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .shadow(color: Color.accentColor.opacity(0.18), radius: 6, y: 2)
                        }
                        .buttonStyle(AnimatedButtonStyle())
                        .padding(.trailing, 8)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 16)
                }
                .frame(width: 340)
                .background(
                    VisualEffectBlur()
                        .clipShape(RoundedRectangle(cornerRadius: 0))
                        .opacity(0.7)
                )
                .overlay(
                    Rectangle().frame(width: 1).foregroundColor(Color.white.opacity(0.08)), alignment: .trailing
                )
                
                // Правая панель — приветствие и кнопка
                VStack(spacing: 36) {
                    Spacer()
                    Text(loc.localized("Welcome!"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                    Text(loc.localized("Fast and secure connection to your servers. Manage your files easily and in a modern way."))
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button(action: {
                        showingProtocolSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text(loc.localized("Add server"))
                                .fontWeight(.semibold)
                        }
                        .font(.title2)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 48)
                        .background(
                            Capsule()
                                .fill(Color.accentColor.opacity(0.18))
                                .shadow(color: Color.accentColor.opacity(0.3), radius: 12, y: 4)
                        )
                    }
                    .buttonStyle(AnimatedButtonStyle())
                    .foregroundColor(.accentColor)
                    Spacer()
                    Text("© 2025 FTP/SFTP Client")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
} 
