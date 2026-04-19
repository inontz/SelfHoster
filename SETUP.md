# Setup Guide

## Prerequisites

1. **Xcode 15.0+** - Download from the Mac App Store
2. **iOS 17.0+** - The app requires iOS 17 or later
3. **Apple Developer Account** - Free account is sufficient for personal use

## Installation Steps

### 1. Open the Project

```bash
open SelfHoster.xcodeproj
```

### 2. Configure Signing

1. In Xcode, select the `SelfHoster` project in the navigator
2. Select the `SelfHoster` target
3. Go to the **Signing & Capabilities** tab
4. Select your **Team** (your Apple ID)
5. Ensure **Bundle Identifier** is unique (e.g., `com.yourname.selfhoster`)

### 3. Add Required Capabilities

The app needs these capabilities (already configured in Info.plist):

- **App Transport Security**: Allows local network connections
- **Bonjour Services**: For network discovery
- **Local Network Usage**: Requires user permission

### 4. Build and Run

1. Connect your iOS device via USB
2. Select your device from the scheme menu
3. Press **⌘R** to build and run
4. Trust the developer certificate on your device if prompted

## First Launch

### Permissions

On first launch, you'll be asked for:

1. **Local Network Access** - Required to discover Proxmox servers
2. **Untrusted Server Warning** - If using self-signed certificates

### Adding Your First Server

#### Option 1: Auto-Discovery

1. Tap the **+** button
2. Tap **Scan Local Network**
3. Wait for discovery to complete
4. Select your server from the list
5. Enter credentials and save

#### Option 2: Manual Entry

1. Tap the **+** button
2. Fill in server details:
   - **Name**: Friendly name (e.g., "Home Server")
   - **Host**: IP address or domain (e.g., `192.168.1.100` or `proxmox.local`)
   - **Port**: `8006` (default Proxmox port)
   - **Username**: Your Proxmox username (e.g., `root` or `admin`)
   - **Password**: Your Proxmox password
   - **Realm**: `pam` (default) or `pve`

## Proxmox Server Configuration

### API Access

The app uses the Proxmox REST API. Ensure:

1. Your Proxmox server is accessible on the network
2. Port 8006 is open (default HTTPS port)
3. You have valid credentials

### Using API Tokens (Recommended)

For better security, create an API token:

```bash
# On your Proxmox server
pveum user token add root@pam mytoken -privsep 0
```

Then use:
- **Username**: `root@pam!mytoken`
- **Password**: The token secret

### Firewall Rules

If you have a firewall, allow:
- TCP 8006 (API)
- TCP 61000-61999 (VNC for VMs)
- TCP 62000-62999 (VNC for containers)

## Troubleshooting

### Cannot Connect to Server

1. Verify the server is online and accessible
2. Check the IP address and port
3. Ensure HTTPS is enabled on Proxmox
4. Try accessing `https://your-server:8006` in a browser

### Discovery Not Working

1. Ensure iOS device is on the same network
2. Grant Local Network permission in Settings
3. Try manual entry instead

### Terminal Not Connecting

1. VM must be running
2. VNC must be enabled on the Proxmox server
3. Check firewall rules for VNC ports
4. Try accessing the VM console in the web UI first

### Certificate Warnings

Proxmox uses self-signed certificates by default. To avoid warnings:

1. **Option 1**: Accept the certificate on first connection
2. **Option 2**: Use a trusted certificate (Let's Encrypt)
3. **Option 3**: Add the certificate to your device's trusted certificates

## Building for Production

### App Store Distribution

1. Create an App Store Connect record
2. Configure signing for distribution
3. Archive the build (Product → Archive)
4. Distribute to App Store

### Ad Hoc Distribution

1. Add device UDIDs to your Apple Developer account
2. Create Ad Hoc provisioning profile
3. Build with distribution settings
4. Share via TestFlight or direct install

## Updates

To update the app:

1. Pull latest changes from repository
2. Clean build folder (⇧⌘K)
3. Rebuild and deploy

## Support

For issues or feature requests, please check:
- Proxmox API documentation: https://pve.proxmox.com/pve-docs/api-viewer/
- iOS development guidelines: https://developer.apple.com/
