import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ServerViewModel()
    @State private var showAddServer = false
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.servers.isEmpty {
                    EmptyServersView(showAddServer: $showAddServer)
                } else {
                    ServerListView(viewModel: viewModel, showAddServer: $showAddServer)
                }
            }
            .navigationTitle("SelfHoster")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddServer = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddServer) {
                AddServerView(viewModel: viewModel)
            }
        }
    }
}

struct EmptyServersView: View {
    @Binding var showAddServer: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "server.rack")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No Servers")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add a Proxmox server to get started")
                .foregroundColor(.secondary)
            
            Button("Add Server") {
                showAddServer = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct ServerListView: View {
    @ObservedObject var viewModel: ServerViewModel
    @Binding var showAddServer: Bool
    @State private var selectedServer: ProxmoxServer?
    
    var body: some View {
        List(viewModel.servers) { server in
            NavigationLink(destination: ServerDetailView(viewModel: viewModel, server: server)) {
                ServerRowView(server: server)
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct ServerRowView: View {
    let server: ProxmoxServer
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(server.name)
                    .font(.headline)
                Text(server.host)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if server.isOnline {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
            } else {
                Circle()
                    .fill(.gray)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

#Preview {
    ContentView()
}
