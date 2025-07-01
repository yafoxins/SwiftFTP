import SwiftUI

struct TerminalView: View {
    @State private var command = ""
    @State private var output = ""
    @ObservedObject var manager = ConnectionManager()
    @ObservedObject var loc = LocalizationManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc.localized("SSH Terminal"))
                .font(.headline)
                .padding(.bottom, 8)
            
            ScrollView {
                Text(output.isEmpty ? loc.localized("Terminal ready...") : output)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(6)
            }
            .frame(maxHeight: .infinity)
            
            HStack {
                TextField(loc.localized("Enter command..."), text: $command)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        executeCommand()
                    }
                
                Button(loc.localized("Send")) {
                    executeCommand()
                }
                .keyboardShortcut(.return)
            }
        }
        .padding()
        .navigationTitle(loc.localized("SSH Terminal"))
    }
    
    private func executeCommand() {
        guard !command.isEmpty else { return }
        
        let cmd = command
        output += "$ \(cmd)\n"
        
        // Simulate command execution
        DispatchQueue.global().async {
            let result = manager.executeSSH(cmd: cmd)
            DispatchQueue.main.async {
                self.output += result ? loc.localized("Command executed successfully") + "\n" : loc.localized("Command failed") + "\n"
                self.command = ""
            }
        }
    }
} 