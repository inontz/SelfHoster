import Foundation
import Network

@MainActor
class NetworkDiscoveryService: ObservableObject {
    @Published var isScanning = false
    @Published var discoveredServers: [ProxmoxServer] = []
    @Published var scanProgress = 0
    
    private var browser: NWBrowser?
    private let queue = DispatchQueue(label: "com.selfhoster.discovery")
    
    func scanForProxmoxServers() async {
        await MainActor.run {
            isScanning = true
            discoveredServers.removeAll()
            scanProgress = 0
        }

        let localSubnets = self.getLocalSubnets()
        let totalIPs = localSubnets.count * 254
        var completedIPs = 0
        var foundServers: Set<ProxmoxServer> = []

        await withTaskGroup(of: ProxmoxServer?.self) { group in
            for subnet in localSubnets {
                for i in 1...254 {
                    let ip = "\(subnet).\(i)"
                    group.addTask {
                        let server = await NetworkDiscoveryService.asyncCheckProxmoxServer(at: ip)
                        return server
                    }
                }
            }

            for await server in group {
                completedIPs += 1
                let progress = Int(Double(completedIPs) / Double(totalIPs) * 100)
                await MainActor.run {
                    scanProgress = progress
                    if let server, foundServers.insert(server).inserted {
                        discoveredServers = Array(foundServers)
                    }
                }
            }
        }
        await MainActor.run {
            isScanning = false
            scanProgress = 100
        }
    }
    
    nonisolated static func checkProxmoxServer(at host: String) -> ProxmoxServer? {
        let url = URL(string: "https://\(host):8006/api2/json/version")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 2
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 2
        config.timeoutIntervalForResource = 5
        
        let session = URLSession(configuration: config)
        
        let semaphore = DispatchSemaphore(value: 0)
        var result: ProxmoxServer?
        
        session.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                return
            }
            
            result = ProxmoxServer(
                name: "Proxmox \(host)",
                host: host,
                port: 8006,
                isOnline: true
            )
        }.resume()
        
        _ = semaphore.wait(timeout: .now() + 3)
        return result
    }
    
    nonisolated static func asyncCheckProxmoxServer(at host: String) async -> ProxmoxServer? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let result = checkProxmoxServer(at: host)
                continuation.resume(returning: result)
            }
        }
    }
    
    private func getLocalSubnets() -> [String] {
        var subnets: [String] = []
        
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return ["192.168.1"] }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee else { continue }
            let addrFamily = interface.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_INET) {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(
                    interface.ifa_addr,
                    socklen_t(interface.ifa_addr.pointee.sa_len),
                    &hostname,
                    socklen_t(hostname.count),
                    nil,
                    socklen_t(0),
                    NI_NUMERICHOST
                )
                
                let ip = String(cString: hostname)
                if ip.hasPrefix("192.168.") || ip.hasPrefix("10.") || ip.hasPrefix("172.") {
                    let parts = ip.split(separator: ".")
                    if parts.count >= 3 {
                        subnets.append("\(parts[0]).\(parts[1]).\(parts[2])")
                    }
                }
            }
        }
        
        freeifaddrs(ifaddr)
        return subnets.isEmpty ? ["192.168.1"] : Array(Set(subnets))
    }
    
    func addServerManually(
        name: String,
        host: String,
        port: Int = 8006,
        username: String = "root",
        password: String,
        realm: String = "pam"
    ) -> ProxmoxServer {
        ProxmoxServer(
            name: name,
            host: host,
            port: port,
            username: username,
            password: password,
            realm: realm
        )
    }
}

