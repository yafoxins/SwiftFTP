import SwiftUI

struct SettingsView: View {
    @ObservedObject var loc = LocalizationManager.shared
    @AppStorage("appLanguage") var appLanguage: String = {
        if let lang = Locale.preferredLanguages.first {
            return String(lang.prefix(2))
        } else {
            return "en"
        }
    }()
    @AppStorage("showFileSize") var showFileSize: Bool = true
    @AppStorage("showFileDate") var showFileDate: Bool = true
    @AppStorage("showFilePermissions") var showFilePermissions: Bool = false
    @AppStorage("autoScrollToTop") var autoScrollToTop: Bool = true
    @AppStorage("showTransferSpeed") var showTransferSpeed: Bool = true
    
    let supportedLanguages = ["en", "ru"]
    @Environment(\.presentationMode) var presentation
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Заголовок
            HStack {
                Text(loc.localized("Settings"))
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { presentation.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(AnimatedButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Табы
            HStack(spacing: 0) {
                ForEach(0..<3) { index in
                    Button(action: { selectedTab = index }) {
                        VStack(spacing: 4) {
                            Text(tabTitle(for: index))
                                .font(.subheadline)
                                .fontWeight(selectedTab == index ? .semibold : .medium)
                                .foregroundColor(selectedTab == index ? .accentColor : .secondary)
                            Rectangle()
                                .fill(selectedTab == index ? Color.accentColor : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .buttonStyle(AnimatedButtonStyle())
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            
            Divider()
                .padding(.horizontal, 24)
            
            // Контент табов
            Group {
                switch selectedTab {
                case 0:
                    GeneralSettingsView(
                        appLanguage: $appLanguage,
                        showFileSize: $showFileSize,
                        showFileDate: $showFileDate,
                        showFilePermissions: $showFilePermissions,
                        autoScrollToTop: $autoScrollToTop,
                        showTransferSpeed: $showTransferSpeed,
                        loc: loc
                    )
                case 1:
                    AppearanceSettingsView(loc: loc)
                case 2:
                    AboutSettingsView(loc: loc)
                default:
                    GeneralSettingsView(
                        appLanguage: $appLanguage,
                        showFileSize: $showFileSize,
                        showFileDate: $showFileDate,
                        showFilePermissions: $showFilePermissions,
                        autoScrollToTop: $autoScrollToTop,
                        showTransferSpeed: $showTransferSpeed,
                        loc: loc
                    )
                }
            }
            .animation(.easeInOut(duration: 0.3), value: selectedTab)
        }
        .frame(width: 480, height: 520)
        .background(
            VisualEffectBlur()
                .background(Color(nsColor: NSColor.windowBackgroundColor).opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.accentColor.opacity(0.10), lineWidth: 1.2)
        )
        .id(loc.language)
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return loc.localized("General")
        case 1: return loc.localized("Appearance")
        case 2: return loc.localized("About")
        default: return ""
        }
    }
}

// Общие настройки
struct GeneralSettingsView: View {
    @Binding var appLanguage: String
    @Binding var showFileSize: Bool
    @Binding var showFileDate: Bool
    @Binding var showFilePermissions: Bool
    @Binding var autoScrollToTop: Bool
    @Binding var showTransferSpeed: Bool
    let loc: LocalizationManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Язык
                SettingsSection(title: loc.localized("Language")) {
                    HStack(spacing: 12) {
                        ForEach(["en", "ru"], id: \.self) { lang in
                            Button(action: {
                                appLanguage = lang
                                loc.setLanguage(lang)
                            }) {
                                HStack(spacing: 8) {
                                    Text(lang == "ru" ? "🇷🇺" : "🇺🇸")
                                        .font(.title3)
                                    Text(loc.localized(lang == "ru" ? "Русский" : "English"))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(appLanguage == lang ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(appLanguage == lang ? Color.accentColor : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(AnimatedButtonStyle())
                        }
                    }
                }
                
                // Отображение файлов
                SettingsSection(title: loc.localized("File Display")) {
                    VStack(spacing: 12) {
                        SettingsToggle(
                            title: loc.localized("Show file size"),
                            subtitle: loc.localized("Display file size in the file list"),
                            isOn: $showFileSize
                        )
                        SettingsToggle(
                            title: loc.localized("Show file date"),
                            subtitle: loc.localized("Display modification date in the file list"),
                            isOn: $showFileDate
                        )
                        SettingsToggle(
                            title: loc.localized("Show file permissions"),
                            subtitle: loc.localized("Display file permissions in the file list"),
                            isOn: $showFilePermissions
                        )
                    }
                }
                
                // Поведение
                SettingsSection(title: loc.localized("Behavior")) {
                    VStack(spacing: 12) {
                        SettingsToggle(
                            title: loc.localized("Auto-scroll to top"),
                            subtitle: loc.localized("Automatically scroll to the top when entering a folder"),
                            isOn: $autoScrollToTop
                        )
                        SettingsToggle(
                            title: loc.localized("Show transfer speed"),
                            subtitle: loc.localized("Display transfer speed during file operations"),
                            isOn: $showTransferSpeed
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
    }
}

// Настройки внешнего вида
struct AppearanceSettingsView: View {
    let loc: LocalizationManager
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 40)
            Image(systemName: "paintbrush.fill")
                .font(.system(size: 44, weight: .medium))
                .foregroundColor(.accentColor)
                .padding(.bottom, 8)
            Text(loc.localized("Appearance section is coming soon!"))
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(.accentColor)
            Text(loc.localized("This section is under development. Stay tuned!"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer()
        }
    }
}

// О проекте
struct AboutSettingsView: View {
    let loc: LocalizationManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 36) {
                // Логотип и версия
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.18))
                            .frame(width: 92, height: 92)
                        Image(systemName: "server.rack")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundColor(.accentColor)
                    }
                    Text("FTP/SFTP Client")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 2)
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 18)
                
                // Описание
                Text(loc.localized("Fast and secure connection to your servers. Manage your files easily and in a modern way."))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                Divider().padding(.horizontal, 8)
                // Ссылки
                VStack(alignment: .leading, spacing: 16) {
                    Text(loc.localized("Links"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.bottom, 2)
                    HStack(spacing: 18) {
                        LinkButton(
                            title: "GitHub",
                            subtitle: "github.com/yafoxins",
                            icon: "link",
                            url: "https://github.com/yafoxins"
                        )
                        LinkButton(
                            title: "Telegram",
                            subtitle: "@yafoxin",
                            icon: "message",
                            url: "https://t.me/yafoxin"
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                
                Divider().padding(.horizontal, 8)
                // Лицензия
                VStack(spacing: 14) {
                    Text(loc.localized("License"))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                    LicenseLinkButton()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }
}

// Компоненты
struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            content
        }
    }
}

struct SettingsToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle())
        }
        .padding(.vertical, 4)
    }
}

struct ThemeOptionView: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.title3)
            }
        }
        .padding(.vertical, 8)
    }
}

struct LinkButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let url: String
    
    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(AnimatedButtonStyle())
        .padding(.vertical, 8)
    }
}

// Новый красивый LicenseLinkButton
struct LicenseLinkButton: View {
    var body: some View {
        Button(action: {
            if let url = URL(string: "https://opensource.org/licenses/MIT") {
                NSWorkspace.shared.open(url)
            }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.13))
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.accentColor.opacity(0.13), radius: 8, y: 2)
                    Image(systemName: "doc.plaintext")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.accentColor)
                }
                Text("MIT License")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
                HStack(spacing: 4) {
                    Text("opensource.org")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.accentColor.opacity(0.08))
            )
        }
        .buttonStyle(AnimatedButtonStyle())
    }
} 