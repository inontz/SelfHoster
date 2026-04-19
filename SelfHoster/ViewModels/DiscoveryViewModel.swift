import Foundation
import SwiftUI

@MainActor
class DiscoveryViewModel: ObservableObject {
    @Published var discoveryService = NetworkDiscoveryService()
    @Published var isScanning = false
    @Published var showManualAddSheet = false
    
    @Environment(\.dismiss) var dismiss
    
    func startScan() {
        isScanning = true
        Task {
            await discoveryService.scanForProxmoxServers()
            isScanning = false
        }
    }
    
    func addServerManually(
        name: String,
        host: String,
        port: Int,
        username: String,
        password: String,
        realm: String
    ) -> ProxmoxServer {
        discoveryService.addServerManually(
            name: name,
            host: host,
            port: port,
            username: username,
            password: password,
            realm: realm
        )
    }
}
