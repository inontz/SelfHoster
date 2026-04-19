import SwiftUI

struct ServerDetailView: View {
    @ObservedObject var viewModel: ServerViewModel
    let server: ProxmoxServer
    
    @State private var nodes: [ProxmoxNode] = []
    @State private var vms: [ProxmoxVM] = []
    @State private var containers: [ProxmoxContainer] = []
    @State private var isLoading = true
    @State private var showingTerminal = false
    @State private var selectedVM: ProxmoxVM?
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let error = errorMessage {
                ErrorView(message: error, onRetry: {
                    Task {
                        await loadServerData()
                    }
                })
            } else {
                Form {
                    Section(header: Text("Status")) {
                        HStack {
                            Circle()
                                .fill(server.isOnline ? .green : .red)
                                .frame(width: 12, height: 12)
                            Text(server.isOnline ? "Online" : "Offline")
                        }
                    }
                    
                    if !nodes.isEmpty {
                        Section(header: Text("Nodes")) {
                            ForEach(nodes) { node in
                                NavigationLink(destination: NodeDetailView(service: viewModel.proxmoxService!, node: node)) {
                                    NodeRowView(node: node)
                                }
                            }
                        }
                    }
                    
                    if !vms.isEmpty {
                        Section(header: Text("Virtual Machines")) {
                            ForEach(vms) { vm in
                                VMRowView(vm: vm, service: viewModel.proxmoxService!, node: nodes.first?.name ?? "") {
                                    selectedVM = vm
                                    showingTerminal = true
                                }
                            }
                        }
                    }
                    
                    if !containers.isEmpty {
                        Section(header: Text("Containers")) {
                            ForEach(containers) { container in
                                ContainerRowView(container: container, service: viewModel.proxmoxService!, node: nodes.first?.name ?? "")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(server.name)
        .task {
            await loadServerData()
        }
        .sheet(isPresented: $showingTerminal) {
            if let vm = selectedVM, let node = nodes.first {
                TerminalView(service: viewModel.proxmoxService!, node: node.name, vmid: vm.vmid)
            }
        }
    }
    
    private func loadServerData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let service = viewModel.proxmoxService {
                nodes = try await service.getNodes()
                
                if let firstNode = nodes.first {
                    async let vmsTask = service.getVMs(node: firstNode.name)
                    async let containersTask = service.getContainers(node: firstNode.name)
                    
                    vms = try await vmsTask
                    containers = try await containersTask
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct NodeRowView: View {
    let node: ProxmoxNode
    
    var body: some View {
        HStack {
            Image(systemName: "server.rack")
            VStack(alignment: .leading) {
                Text(node.name)
                    .font(.headline)
                Text("CPU: \(cpuPercentage)% | Mem: \(memoryPercentage)%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var cpuPercentage: String {
        guard let cpu = node.cpu else { return "0" }
        return String(format: "%.1f", cpu * 100)
    }
    
    private var memoryPercentage: String {
        guard let mem = node.mem, let maxMem = node.maxmem, maxMem > 0 else { return "0" }
        return String(format: "%.1f", (Double(mem) / Double(maxMem)) * 100)
    }
}

struct VMRowView: View {
    let vm: ProxmoxVM
    let service: ProxmoxService
    let node: String
    let onOpenTerminal: () -> Void
    
    @State private var isStarting = false
    @State private var isStopping = false
    
    var body: some View {
        HStack {
            Image(systemName: vm.status == "running" ? "play.circle.fill" : "stop.circle.fill")
                .foregroundColor(vm.status == "running" ? .green : .gray)
            
            VStack(alignment: .leading) {
                Text(vm.name ?? "VM \(vm.vmid)")
                    .font(.headline)
                Text("ID: \(vm.vmid) • \(vm.status.capitalized)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if vm.status == "running" {
                Button(action: openTerminal) {
                    Image(systemName: "terminal")
                }
                .buttonStyle(.bordered)
                
                Button(action: stopVM) {
                    if isStopping {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "stop.fill")
                    }
                }
                .disabled(isStopping)
            } else {
                Button(action: startVM) {
                    if isStarting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "play.fill")
                    }
                }
                .disabled(isStarting)
            }
        }
    }
    
    private func startVM() {
        isStarting = true
        Task {
            try? await service.startVM(node: node, vmid: vm.vmid)
            isStarting = false
        }
    }
    
    private func stopVM() {
        isStopping = true
        Task {
            try? await service.stopVM(node: node, vmid: vm.vmid)
            isStopping = false
        }
    }
    
    private func openTerminal() {
        onOpenTerminal()
    }
}

struct ContainerRowView: View {
    let container: ProxmoxContainer
    let service: ProxmoxService
    let node: String
    
    @State private var isStarting = false
    @State private var isStopping = false
    
    var body: some View {
        HStack {
            Image(systemName: container.status == "running" ? "play.circle.fill" : "stop.circle.fill")
                .foregroundColor(container.status == "running" ? .green : .gray)
            
            VStack(alignment: .leading) {
                Text(container.name ?? "CT \(container.vmid)")
                    .font(.headline)
                Text("ID: \(container.vmid) • \(container.status.capitalized)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if container.status == "running" {
                Button(action: stopContainer) {
                    if isStopping {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "stop.fill")
                    }
                }
                .disabled(isStopping)
            } else {
                Button(action: startContainer) {
                    if isStarting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "play.fill")
                    }
                }
                .disabled(isStarting)
            }
        }
    }
    
    private func startContainer() {
        isStarting = true
        Task {
            try? await service.startContainer(node: node, vmid: container.vmid)
            isStarting = false
        }
    }
    
    private func stopContainer() {
        isStopping = true
        Task {
            try? await service.stopContainer(node: node, vmid: container.vmid)
            isStopping = false
        }
    }
}

struct NodeDetailView: View {
    let service: ProxmoxService
    let node: ProxmoxNode
    
    var body: some View {
        List {
            Section(header: Text("Resources")) {
                HStack {
                    Text("CPU Usage")
                    Spacer()
                    Text("\(cpuPercentage)%")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Memory")
                    Spacer()
                    Text("\(memoryUsage) / \(maxMemoryUsage) GB")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Disk")
                    Spacer()
                    Text("\(diskUsage) / \(maxDiskUsage) GB")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Information")) {
                HStack {
                    Text("Type")
                    Spacer()
                    Text(node.type)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Uptime")
                    Spacer()
                    Text(uptimeString)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(node.name)
    }
    
    private var cpuPercentage: String {
        guard let cpu = node.cpu else { return "0" }
        return String(format: "%.1f", cpu * 100)
    }
    
    private var memoryUsage: String {
        guard let mem = node.mem else { return "0" }
        return String(format: "%.1f", Double(mem) / 1024 / 1024 / 1024)
    }
    
    private var maxMemoryUsage: String {
        guard let maxMem = node.maxmem else { return "0" }
        return String(format: "%.1f", Double(maxMem) / 1024 / 1024 / 1024)
    }
    
    private var diskUsage: String {
        guard let disk = node.disk else { return "0" }
        return String(format: "%.1f", Double(disk) / 1024 / 1024 / 1024)
    }
    
    private var maxDiskUsage: String {
        guard let maxDisk = node.maxdisk else { return "0" }
        return String(format: "%.1f", Double(maxDisk) / 1024 / 1024 / 1024)
    }
    
    private var uptimeString: String {
        guard let uptime = node.uptime else { return "Unknown" }
        let days = uptime / 86400
        let hours = (uptime % 86400) / 3600
        return "\(days)d \(hours)h"
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Retry", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    NavigationView {
        ServerDetailView(
            viewModel: ServerViewModel(),
            server: ProxmoxServer(name: "Test Server", host: "192.168.1.100")
        )
    }
}
