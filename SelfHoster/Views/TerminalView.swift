import SwiftUI
import WebKit

struct TerminalView: View {
    let service: ProxmoxService
    let node: String
    let vmid: Int
    
    @StateObject private var terminalService = TerminalService()
    @Environment(\.dismiss) var dismiss
    @State private var command = ""
    @State private var terminalURL: URL?
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView("Connecting to terminal...")
                        .padding()
                }
                
                if let url = terminalURL {
                    WebView(url: url)
                }
                
                VStack(spacing: 8) {
                    HStack {
                        TextField("Command", text: $command)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        Button("Send") {
                            terminalService.send(command: command + "\n")
                            command = ""
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle("Terminal - VM \(vmid)")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        terminalService.clearOutput()
                    }
                }
            }
            .task {
                await loadTerminal()
            }
        }
    }
    
    private func loadTerminal() async {
        do {
            let url = try await service.getTerminalURL(node: node, vmid: vmid)
            await MainActor.run {
                terminalURL = url
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let request = URLRequest(url: url)
        webView.load(request)
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
    }
}

#Preview {
    TerminalView(
        service: ProxmoxService(server: ProxmoxServer(name: "Test", host: "192.168.1.100")),
        node: "pve",
        vmid: 100
    )
}
