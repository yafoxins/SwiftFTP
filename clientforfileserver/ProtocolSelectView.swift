import SwiftUI

struct ProtocolSelectView: View {
    @ObservedObject var loc = LocalizationManager.shared
    var onSelect: (ConnectionManager.ProtocolType) -> Void
    @Environment(\.presentationMode) var presentation

    var body: some View {
        VStack(spacing: 24) {
            Text(loc.localized("Protocol"))
                .font(.title3)
                .fontWeight(.bold)
                .padding(.top, 18)
            HStack(spacing: 24) {
                ProtocolButton(icon: "lock.shield", label: loc.localized("SFTP")) {
                    onSelect(.sftp)
                    presentation.wrappedValue.dismiss()
                }
                ProtocolButton(icon: "arrow.down.doc", label: loc.localized("FTP")) {
                    onSelect(.ftp)
                    presentation.wrappedValue.dismiss()
                }
            }
            Spacer()
            Button(action: {
                presentation.wrappedValue.dismiss()
            }) {
                Text(loc.localized("Cancel"))
                    .fontWeight(.medium)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 40)
                    .background(Color.gray.opacity(0.13))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
            .buttonStyle(AnimatedButtonStyle())
            .padding(.bottom, 18)
        }
        .frame(width: 320, height: 260)
        .background(
            VisualEffectBlur()
                .background(Color.white.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.accentColor.opacity(0.10), lineWidth: 1.2)
        )
    }
}

struct ProtocolButton: View {
    var icon: String
    var label: String
    var action: () -> Void
    @State private var isHover = false
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 38, weight: .medium))
                Text(label)
                    .font(.body)
                    .fontWeight(.semibold)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(isHover ? Color.accentColor.opacity(0.22) : Color.accentColor.opacity(0.15))
            .cornerRadius(12)
            .shadow(color: isHover ? Color.accentColor.opacity(0.18) : .clear, radius: 8, y: 2)
        }
        .buttonStyle(AnimatedButtonStyle())
        .onHover { hover in
            isHover = hover
        }
    }
} 