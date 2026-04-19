import Foundation

class ProxmoxService: ObservableObject {
    private var session: URLSession
    private var authTicket: ProxmoxAuthTicket?
    
    @Published var server: ProxmoxServer
    @Published var isConnected = false
    @Published var errorMessage: String?
    
    init(server: ProxmoxServer) {
        self.server = server
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.httpShouldSetCookies = true
        
        self.session = URLSession(configuration: config)
    }
    
    func connect() async throws {
        let url = URL(string: "\(server.baseURL)/access/ticket")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "username": "\(usernameWithRealm)",
            "password": server.password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            let error = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            throw ProxmoxError.authenticationFailed(message: error?["errors"] as? String ?? "Authentication failed")
        }
        
        let result = try JSONDecoder().decode(APIResponse<ProxmoxAuthTicket>.self, from: data)
        self.authTicket = result.data
        self.isConnected = true
        self.server.isOnline = true
        self.server.lastConnected = Date()
    }
    
    private var usernameWithRealm: String {
        "\(server.username)@\(server.realm)"
    }
    
    private var headers: [String: String] {
        guard let ticket = authTicket else { return [:] }
        return [
            "Cookie": "PVEAuthCookie=\(ticket.ticket)",
            "CSRFPreventionToken": ticket.csrfPreventionToken
        ]
    }
    
    func getVersion() async throws -> ProxmoxVersion {
        let url = URL(string: "\(server.baseURL)/version")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let (data, _) = try await session.data(for: request)
        let result = try JSONDecoder().decode(APIResponse<ProxmoxVersion>.self, from: data)
        return result.data
    }
    
    func getNodes() async throws -> [ProxmoxNode] {
        let url = URL(string: "\(server.baseURL)/nodes")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let (data, _) = try await session.data(for: request)
        let result = try JSONDecoder().decode(APIResponse<[ProxmoxNode]>.self, from: data)
        return result.data
    }
    
    func getVMs(node: String) async throws -> [ProxmoxVM] {
        let url = URL(string: "\(server.baseURL)/nodes/\(node)/qemu")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let (data, _) = try await session.data(for: request)
        let result = try JSONDecoder().decode(APIResponse<[ProxmoxVM]>.self, from: data)
        return result.data
    }
    
    func getContainers(node: String) async throws -> [ProxmoxContainer] {
        let url = URL(string: "\(server.baseURL)/nodes/\(node)/lxc")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let (data, _) = try await session.data(for: request)
        let result = try JSONDecoder().decode(APIResponse<[ProxmoxContainer]>.self, from: data)
        return result.data
    }
    
    func startVM(node: String, vmid: Int) async throws {
        let url = URL(string: "\(server.baseURL)/nodes/\(node)/qemu/\(vmid)/status/start")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw ProxmoxError.operationFailed(message: "Failed to start VM")
        }
    }
    
    func stopVM(node: String, vmid: Int) async throws {
        let url = URL(string: "\(server.baseURL)/nodes/\(node)/qemu/\(vmid)/status/stop")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw ProxmoxError.operationFailed(message: "Failed to stop VM")
        }
    }
    
    func startContainer(node: String, vmid: Int) async throws {
        let url = URL(string: "\(server.baseURL)/nodes/\(node)/lxc/\(vmid)/status/start")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw ProxmoxError.operationFailed(message: "Failed to start container")
        }
    }
    
    func stopContainer(node: String, vmid: Int) async throws {
        let url = URL(string: "\(server.baseURL)/nodes/\(node)/lxc/\(vmid)/status/stop")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw ProxmoxError.operationFailed(message: "Failed to stop container")
        }
    }
    
    func getVNCTicket(node: String, vmid: Int) async throws -> String {
        let url = URL(string: "\(server.baseURL)/nodes/\(node)/qemu/\(vmid)/vncproxy")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
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
        
        return components.url!
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
