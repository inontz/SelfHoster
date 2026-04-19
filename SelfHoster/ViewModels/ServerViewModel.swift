import Foundation
import SwiftUI

@MainActor
class ServerViewModel: ObservableObject {
    @Published var servers: [ProxmoxServer] = []
    @Published var selectedServer: ProxmoxServer?
    @Published var proxmoxService: ProxmoxService?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @AppStorage("savedServers") private var savedServersData = Data()
    
    init() {
        loadServers()
    }
    
    func loadServers() {
        if let data = UserDefaults.standard.data(forKey: "savedServers"),
           let servers = try? JSONDecoder().decode([ProxmoxServer].self, from: data) {
            self.servers = servers
        }
    }
    
    func saveServers() {
        if let data = try? JSONEncoder().encode(servers) {
            UserDefaults.standard.set(data, forKey: "savedServers")
        }
    }
    
    func addServer(_ server: ProxmoxServer) {
        servers.append(server)
        saveServers()
    }
    
    func updateServer(_ server: ProxmoxServer) {
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index] = server
            saveServers()
        }
    }
    
    func deleteServer(_ server: ProxmoxServer) {
        servers.removeAll { $0.id == server.id }
        saveServers()
    }
    
    func connect(to server: ProxmoxServer) async {
        isLoading = true
        errorMessage = nil
        selectedServer = server
        
        let service = ProxmoxService(server: server)
        
        do {
            try await service.connect()
            proxmoxService = service
            updateServer(service.server)
        } catch {
            errorMessage = error.localizedDescription
            proxmoxService = nil
        }
        
        isLoading = false
    }
    
    func disconnect() {
        proxmoxService = nil
        selectedServer = nil
    }
}
