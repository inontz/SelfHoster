# SelfHoster - Proxmox iOS Manager

A native iOS app for managing your Proxmox Virtual Environment servers.

## Features

- **Multiple Server Support**: Add and manage multiple Proxmox servers
- **Local Network Discovery**: Automatically discover Proxmox servers on your local network
- **Manual Server Configuration**: Add servers manually with custom settings
- **Server Monitoring**: View real-time status, CPU, memory, and disk usage
- **VM Management**: Start, stop, and monitor virtual machines
- **Container Management**: Start, stop, and monitor LXC containers
- **Web Terminal**: Access VM consoles directly from your iOS device
- **Secure Connection**: HTTPS/TLS encrypted connections to your servers

## Requirements

- iOS 17.0 or later
- Proxmox VE 7.0 or later
- Network access to your Proxmox server

## Project Structure

```
SelfHoster/
├── Models/
│   └── ProxmoxServer.swift      # Data models for Proxmox API
├── Views/
│   ├── ContentView.swift         # Main app view
│   ├── AddServerView.swift       # Add new server view
│   ├── ServerDetailView.swift    # Server details and VMs
│   └── TerminalView.swift        # Web terminal view
├── ViewModels/
│   ├── ServerViewModel.swift     # Server state management
│   └── DiscoveryViewModel.swift  # Network discovery state
├── Services/
│   ├── ProxmoxService.swift      # Proxmox API client
│   ├── NetworkDiscoveryService.swift  # LAN discovery
│   └── TerminalService.swift     # WebSocket terminal
└── SelfHosterApp.swift           # App entry point
```

## Getting Started

1. Open `SelfHoster.xcodeproj` in Xcode
2. Select your development team in project settings
3. Build and run on your iOS device

## Usage

### Adding a Server

1. Tap the "+" button
2. Enter server details:
   - Name: Friendly name for your server
   - Host: IP address or domain name
   - Port: Usually 8006 (default)
   - Username: Your Proxmox username (e.g., root)
   - Password: Your Proxmox password
   - Realm: Authentication realm (default: pam)
3. Or tap "Scan Local Network" to discover servers automatically

### Managing VMs and Containers

- View status and resource usage
- Start/stop VMs and containers
- Open terminal console for running VMs

## Security Notes

- Credentials are stored locally on your device
- All connections use HTTPS
- The app requires local network permission for discovery
- Consider using API tokens instead of passwords for better security

## API Reference

The app uses the Proxmox VE REST API:
- Authentication: `/api2/json/access/ticket`
- Nodes: `/api2/json/nodes`
- VMs: `/api2/json/nodes/{node}/qemu`
- Containers: `/api2/json/nodes/{node}/lxc`
- VNC Console: `/api2/json/nodes/{node}/qemu/{vmid}/vncproxy`

## License

MIT License - Feel free to modify and distribute.

## Contributing

Contributions are welcome! Please feel free to submit pull requests.
