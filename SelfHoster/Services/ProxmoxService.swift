import Foundation

// MARK: - ProxmoxService

/// Service for interacting with Proxmox VE API
class ProxmoxService: ObservableObject {
    
    // MARK: - Properties
    
    private var session: URLSession
    private var authTicket: ProxmoxAuthTicket?
    
    @Published var server: ProxmoxServer
    @Published var isConnected = false
    @Published var errorMessage: String?
    
    // MARK: - Initialization
    
    init(server: ProxmoxServer) {
        self.server = server
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.httpShouldSetCookies = true
        
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Authentication
    
    /// Connects to the Proxmox server and authenticates
    func connect() async throws {
        let url = URL(string: "\(server.baseURL)/access/ticket")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "username": server.usernameWithRealm,
            "password": server.password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProxmoxError.networkError(message: "Invalid server response")
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            let error = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            throw ProxmoxError.authenticationFailed(
                message: error?["errors"] as? String ?? "Authentication failed"
            )
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(APIResponse<ProxmoxAuthTicket>.self, from: data)
        
        self.authTicket = result.data
        self.isConnected = true
        self.server.isOnline = true
        self.server.lastConnected = Date()
    }
    
    // MARK: - Private Helpers
    
    /// Returns authentication headers for API requests
    private var authHeaders: [String: String] {
        guard let ticket = authTicket else { return [:] }
        return [
            "Cookie": "PVEAuthCookie=\(ticket.ticket)",
            "CSRFPreventionToken": ticket.csrfPreventionToken
        ]
    }
    
    /// Creates an authenticated URL request
    private func createAuthenticatedRequest(url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        authHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        return request
    }
    
    /// Generic method to fetch and decode API responses
    private func fetch<T: Codable>(from endpoint: String) async throws -> T {
        guard let url = URL(string: "\(server.baseURL)/\(endpoint)") else {
            throw ProxmoxError.networkError(message: "Invalid URL")
        }
        
        let request = createAuthenticatedRequest(url: url)
        let (data, _) = try await session.data(for: request)
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(APIResponse<T>.self, from: data)
        return result.data
    }
    
    // MARK: - Public API Methods
    
    /// Gets the Proxmox version information
    func getVersion() async throws -> ProxmoxVersion {
        try await fetch(from: "version")
    }
    
    /// Gets all nodes on the server
    func getNodes() async throws -> [ProxmoxNode] {
        try await fetch(from: "nodes")
    }
    
    /// Gets all virtual machines for a specific node
    func getVMs(node: String) async throws -> [ProxmoxVM] {
        try await fetch(from: "nodes/\(node)/qemu")
    }
    
    /// Gets all containers for a specific node
    func getContainers(node: String) async throws -> [ProxmoxContainer] {
        try await fetch(from: "nodes/\(node)/lxc")
    }
    
    /// Starts a virtual machine
    func startVM(node: String, vmid: Int) async throws {
        try await performVMAction(node: node, vmid: vmid, action: "start", type: "qemu")
    }
    
    /// Stops a virtual machine
    func stopVM(node: String, vmid: Int) async throws {
        try await performVMAction(node: node, vmid: vmid, action: "stop", type: "qemu")
    }
    
    /// Starts a container
    func startContainer(node: String, vmid: Int) async throws {
        try await performVMAction(node: node, vmid: vmid, action: "start", type: "lxc")
    }
    
    /// Stops a container
    func stopContainer(node: String, vmid: Int) async throws {
        try await performVMAction(node: node, vmid: vmid, action: "stop", type: "lxc")
    }
    
    // MARK: - Private Helper Methods
    
    /// Performs an action (start/stop) on a VM or container
    private func performVMAction(node: String, vmid: Int, action: String, type: String) async throws {
        let endpoint = "nodes/\(node)/\(type)/\(vmid)/status/\(action)"
        guard let url = URL(string: "\(server.baseURL)/\(endpoint)") else {
            throw ProxmoxError.networkError(message: "Invalid URL")
        }
        
        let request = createAuthenticatedRequest(url: url, method: "POST")
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw ProxmoxError.operationFailed(message: "Failed to \(action) \(type)")
        }
    }
    
    /// Gets a VNC ticket for terminal access
    func getVNCTicket(node: String, vmid: Int) async throws -> String {
        let endpoint = "nodes/\(node)/qemu/\(vmid)/vncproxy"
        guard let url = URL(string: "\(server.baseURL)/\(endpoint)") else {
            throw ProxmoxError.networkError(message: "Invalid URL")
        }
        
        var request = createAuthenticatedRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["websocket": 1]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await session.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let dataDict = json?["data"] as? [String: Any]
        
        guard let ticket = dataDict?["ticket"] as? String else {
            throw ProxmoxError.operationFailed(message: "Failed to get VNC ticket")
        }
        
        return ticket
    }
    
    /// Gets the WebSocket URL for terminal access
    func getTerminalURL(node: String, vmid: Int, type: String = "qemu") async throws -> URL {
        let ticket = try await getVNCTicket(node: node, vmid: vmid)
        let port = type == "qemu" ? 61000 + vmid : 62000 + vmid
        
        var components = URLComponents()
        components.scheme = "wss"
        components.host = server.host
        components.port = port
        components.path = "/vnc.html"
        components.queryItems = [
            URLQueryItem(name: "path", value: "websockify"),
            URLQueryItem(name: "token", value: ticket)
        ]
        
        guard let url = components.url else {
            throw ProxmoxError.networkError(message: "Failed to construct terminal URL")
        }
        
        return url
    }
}

enum ProxmoxError: LocalizedError {
    case authenticationFailed(message: String)
    case operationFailed(message: String)
    case networkError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .operationFailed(let message):
            return "Operation failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

struct APIResponse<T: Codable>: Codable {
    let data: T
}
