import Foundation

// MARK: - ProxmoxServer

struct ProxmoxServer: Identifiable, Codable, Equatable, Hashable {
    // MARK: - Properties
    
    let id: UUID
    var name: String
    var host: String
    var port: Int
    var username: String
    var password: String
    var realm: String
    var isOnline: Bool
    var lastConnected: Date?
    
    // MARK: - Computed Properties
    
    var baseURL: String {
        "https://\(host):\(port)/api2/json"
    }
    
    var usernameWithRealm: String {
        "\(username)@\(realm)"
    }
    
    // MARK: - Initializer
    
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
    
    // MARK: - Hashable Conformance
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(host)
        hasher.combine(port)
    }
}

// MARK: - API Response Models

/// Authentication ticket returned by Proxmox API
struct ProxmoxAuthTicket: Codable {
    let ticket: String
    let csrfPreventionToken: String
    let username: String
}

/// Version information from Proxmox API
struct ProxmoxVersion: Codable {
    let release: String
    let repoid: String
    let version: String
}

// MARK: - Node

/// Represents a Proxmox node
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
    
    // MARK: - Computed Properties
    
    var cpuPercentage: String {
        guard let cpu = cpu else { return "0" }
        return String(format: "%.1f", cpu * 100)
    }
    
    var memoryPercentage: String {
        guard let mem = mem, let maxMem = maxmem, maxMem > 0 else { return "0" }
        return String(format: "%.1f", (Double(mem) / Double(maxMem)) * 100)
    }
    
    var memoryUsageGB: String {
        guard let mem = mem else { return "0" }
        return String(format: "%.1f", Double(mem) / 1024 / 1024 / 1024)
    }
    
    var maxMemoryGB: String {
        guard let maxMem = maxmem else { return "0" }
        return String(format: "%.1f", Double(maxMem) / 1024 / 1024 / 1024)
    }
    
    var diskUsageGB: String {
        guard let disk = disk else { return "0" }
        return String(format: "%.1f", Double(disk) / 1024 / 1024 / 1024)
    }
    
    var maxDiskGB: String {
        guard let maxDisk = maxdisk else { return "0" }
        return String(format: "%.1f", Double(maxDisk) / 1024 / 1024 / 1024)
    }
    
    var uptimeString: String {
        guard let uptime = uptime else { return "Unknown" }
        let days = uptime / 86400
        let hours = (uptime % 86400) / 3600
        return "\(days)d \(hours)h"
    }
}

// MARK: - Virtual Machine

/// Represents a QEMU virtual machine
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
    
    // MARK: - Computed Properties
    
    var displayName: String {
        name ?? "VM \(vmid)"
    }
    
    var isRunning: Bool {
        status == "running"
    }
}

// MARK: - Container

/// Represents an LXC container
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
    
    // MARK: - Computed Properties
    
    var displayName: String {
        name ?? "CT \(vmid)"
    }
    
    var isRunning: Bool {
        status == "running"
    }
}

// MARK: - Task

/// Represents a Proxmox task
struct ProxmoxTask: Codable {
    let pid: String
    let status: String
    let type: String
    let starttime: Int
}
