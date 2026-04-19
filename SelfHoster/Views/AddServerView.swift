import SwiftUI

struct AddServerView: View {
    @ObservedObject var viewModel: ServerViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var host = ""
    @State private var port = "8006"
    @State private var username = "root"
    @State private var password = ""
    @State private var realm = "pam"
    @State private var isScanning = false
    @State private var showScanner = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Server Information")) {
                    TextField("Name", text: $name)
                    TextField("Host (IP or Domain)", text: $host)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Credentials")) {
                    TextField("Username", text: $username)
                    SecureField("Password", text: $password)
                    TextField("Realm", text: $realm)
                }
                
                Section {
                    Button(action: {
                        withAnimation {
                            isScanning = true
                        }
                        Task {
                            await scanForServers()
                            withAnimation {
                                isScanning = false
                            }
                        }
                    }) {
                        HStack {
                            if isScanning {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Image(systemName: "wifi")
                            Text("Scan Local Network")
                        }
                    }
                    .disabled(isScanning)
                }
            }
            .navigationTitle("Add Server")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveServer()
                    }
                    .disabled(name.isEmpty || host.isEmpty || password.isEmpty)
                }
            }
            .sheet(isPresented: $showScanner) {
                NetworkScannerView(onSelectServer: { server in
                    name = server.name
                    host = server.host
                    port = String(server.port)
                })
            }
        }
    }
    
    private func saveServer() {
        let server = ProxmoxServer(
            name: name,
            host: host,
            port: Int(port) ?? 8006,
            username: username,
            password: password,
            realm: realm
        )
        viewModel.addServer(server)
        dismiss()
    }
    
    private func scanForServers() async {
        showScanner = true
    }
}

struct NetworkScannerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var discoveryService = NetworkDiscoveryService()
    let onSelectServer: (ProxmoxServer) -> Void
    
    var body: some View {
        NavigationView {
            Group {
                if discoveryService.isScanning {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Scanning network...")
                            .foregroundColor(.secondary)
                    }
                } else if discoveryService.discoveredServers.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No servers found")
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(discoveryService.discoveredServers) { server in
                        Button(action: {
                            onSelectServer(server)
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(server.name)
                                        .font(.headline)
                                    Text(server.host)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Discovered Servers")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await discoveryService.scanForProxmoxServers()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await discoveryService.scanForProxmoxServers()
            }
        }
    }
}

#Preview {
    AddServerView(viewModel: ServerViewModel())
}
