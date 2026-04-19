import Foundation

struct ProxmoxServer: Identifiable, Codable, Equatable, Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(host)
        hasher.combine(port)
    }
    let id: UUID
    var name: String
    var host: String
    var port: Int
    var username: String
    var password: String
    var realm: String
    var isOnline: Bool
    var lastConnected: Date?
    
    var baseURL: String {
        "https://\(host):\(port)/api2/json"
    }
    
    init(
        id: UUID = UUID(),
        name: String = "",
        host: String = "",
        port: Int = 8006,
        username: String = "root",
        password: String = "",
        realm: String = "pam",
        isOnline: Bool = false,
        lastConnected: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.realm = realm
        self.isOnline = isOnline
        self.lastConnected = lastConnected
    }
}

struct ProxmoxAuthTicket: Codable {
    let ticket: String
    let csrfPreventionToken: String
    let username: String
}

struct ProxmoxVersion: Codable {
    let release: String
    let repoid: String
    let version: String
}

struct ProxmoxNode: Identifiable, Codable {
    let id: String
    let name: String
    let type: String
    let status: String
    let uptime: Int?
    let cpu: Double?
    let maxcpu: Int?
    let mem: Int?
    let maxmem: Int?
    let disk: Int?
    let maxdisk: Int?
}

struct ProxmoxVM: Identifiable, Codable {
    let vmid: Int
    let name: String?
    let status: String
    let cpu: Double?
    let maxcpu: Int?
    let mem: Int?
    let maxmem: Int?
    let disk: Int?
    let maxdisk: Int?
    let uptime: Int?
    
    var id: Int { vmid }
}

struct ProxmoxContainer: Identifiable, Codable {
    let vmid: Int
    let name: String?
    let status: String
    let cpu: Double?
    let maxcpu: Int?
    let mem: Int?
    let maxmem: Int?
    let disk: Int?
    let maxdisk: Int?
    let uptime: Int?
    
    var id: Int { vmid }
}

struct ProxmoxTask: Codable {
    let pid: String
    let status: String
    let type: String
    let starttime: Int
}
