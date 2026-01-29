# HomeKit Restore

A macOS application designed to help you document, organize, and back up your HomeKit setup codes. This app helps you build a personal vault of your device codes for future reference and disaster recovery.

![Version](https://img.shields.io/badge/version-1.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-lightgrey.svg)
![Swift](https://img.shields.io/badge/swift-5.9-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## Purpose

Lost your HomeKit setup codes? Need to re-pair devices after a reset? HomeKit Restore helps you:

- **Store setup codes securely** - Keychain-protected vault for your 8-digit codes
- **Find codes on devices** - Location hints for Eve, Lutron, Philips Hue, and more
- **Discover network devices** - Find HomeKit (HAP) and Matter devices on your network
- **Export your data** - CSV, JSON, and text exports for backup
- **Organize your devices** - Manual device inventory with room and home organization

**Key Use Cases:**
- Disaster recovery after HomeKit reset
- Pre-emptive backup of setup codes
- Device inventory documentation
- Smart home insurance documentation
- Finding codes on physical devices

## What This App Can Do

### Code Vault (Secure Storage)
- Manually enter and store setup codes (XXX-XX-XXX format)
- Associate codes with specific devices
- Attach photos of setup code labels
- Add notes and location information
- Codes stored securely in macOS Keychain

### Device Inventory
- Add devices manually or from network discovery
- Group by room, home, manufacturer, or category
- Track device details (manufacturer, model, IP address)
- Associate devices with their setup codes

### Network Discovery
- Scan for HomeKit (HAP) devices via Bonjour/mDNS
- Detect Matter devices (commissioning and operational)
- Identify unpaired devices on your network
- View device metadata and connection info
- Add discovered devices to your inventory

### Code Location Hints
Built-in guidance for finding setup codes on popular devices:
- **Eve** - Back/bottom of device, battery compartment
- **Lutron Caseta** - Bottom of Smart Bridge only
- **Philips Hue** - Bottom of Hue Bridge only
- **Nanoleaf** - Controller unit or power supply
- **Ecobee** - Back of thermostat (remove from wall)
- **Aqara** - Bottom of hub
- **LIFX** - Small text on bulb base
- **Wemo** - Side of plug

### Export Options
- **CSV** - For spreadsheets (Excel, Numbers, Google Sheets)
- **JSON** - For developers and automation
- **Text** - Simple text format for reference

## What This App Cannot Do

**Important Limitations:**

- **Cannot retrieve setup codes from paired devices** - HomeKit intentionally does not store setup codes after pairing for security reasons
- **Cannot read device inventory from HomeKit** - The HomeKit framework is not available on native macOS apps (only via Mac Catalyst)
- **Cannot generate QR codes that will work for pairing** - Setup codes are one-time use during pairing
- **Cannot bypass HomeKit security** - This is by design and is a feature, not a bug

**This app is for manual documentation and backup, not automatic code recovery.**

## Requirements

- macOS 14.0 (Sonoma) or later
- Network access (for device discovery)

## Installation

### From DMG
1. Download the latest DMG from Releases
2. Open the DMG file
3. Drag "HomeKit Restore" to Applications
4. Launch from Applications folder

### Building from Source
```bash
cd /Volumes/Data/xcode/HomeKitRestore
xcodebuild -project HomeKitRestore.xcodeproj \
           -scheme HomeKitRestore \
           -configuration Release \
           build
```

## Usage

### Getting Started
1. **Launch** HomeKit Restore
2. **Scan network** to discover devices
3. **Add devices** to your inventory manually or from discovery
4. **Enter codes** for each device
5. **Export** your data for backup

### Adding a Setup Code
1. Select a device from the Devices tab or Code Vault
2. Enter the 8-digit code (format: XXX-XX-XXX)
3. Optionally add a photo of the code label
4. Add notes about where you found the code
5. Click Save

### Finding Setup Codes
Each device detail view includes manufacturer-specific hints:
- Common locations on the device
- Tips for finding hidden labels
- Bridge vs. accessory information

### Network Discovery
1. Go to the Network Scan tab
2. Click "Scan" to discover devices
3. Filter by HomeKit (HAP), Matter, or unpaired
4. Add discovered devices to your inventory
5. Save codes for any discovered devices

### Exporting Data
1. Go to the Export tab
2. Choose CSV, JSON, or Text format
3. Select save location
4. Keep backup in secure location

## Architecture

### Technology Stack
- **Language**: Swift 5.9
- **UI Framework**: SwiftUI
- **Network Discovery**: Network.framework (NWBrowser)
- **Secure Storage**: Security.framework (Keychain)
- **Platform**: macOS 14+

### Project Structure
```
HomeKitRestore/
├── HomeKitRestore/
│   ├── HomeKitRestoreApp.swift      # App entry point
│   ├── HomeKitRestore.entitlements  # App capabilities
│   ├── Models/
│   │   ├── AccessoryModel.swift     # Device data model
│   │   └── SetupCode.swift          # Code storage model
│   ├── Managers/
│   │   ├── HomeKitManager.swift     # Device inventory (manual)
│   │   ├── CodeVaultManager.swift   # Keychain storage
│   │   ├── NetworkScannerManager.swift  # Bonjour discovery
│   │   └── ExportManager.swift      # Export functionality
│   ├── Views/
│   │   ├── ContentView.swift        # Main navigation
│   │   ├── DeviceListView.swift     # Device inventory
│   │   ├── DeviceDetailView.swift   # Device details & code entry
│   │   ├── CodeVaultView.swift      # Code management
│   │   ├── NetworkScannerView.swift # Network discovery
│   │   └── ExportView.swift         # Export options
│   └── Assets.xcassets/
├── README.md
├── LICENSE
└── HomeKitRestore.xcodeproj
```

### Key Components

**HomeKitManager**
- Manages manual device inventory
- Stores devices in UserDefaults
- Groups accessories by room, manufacturer, category

**CodeVaultManager**
- Securely stores codes in macOS Keychain
- Manages photo attachments for code labels
- Provides search and filtering

**NetworkScannerManager**
- Uses NWBrowser for Bonjour/mDNS discovery
- Scans for _hap._tcp (HomeKit), _matterc._udp (Matter commissioning), _matter._tcp (Matter operational)
- Resolves services to get IP addresses

**ExportManager**
- Generates CSV, JSON, and text exports
- Combines device inventory with saved codes
- Provides formatted output for backup

## Security

- **Keychain Storage**: Setup codes are stored in the macOS Keychain
- **No Network Transmission**: Codes never leave your device (except local network scanning)
- **No Cloud Sync**: Data stays local to your Mac
- **Hardened Runtime**: App is code-signed with hardened runtime
- **No Sandbox**: Required for full file system access (exports)

## Privacy

This app:
- Stores all data locally on your Mac
- Does not collect or transmit any personal data
- Does not require an internet connection (except for local network scanning)
- Uses Bonjour/mDNS for local network discovery only

## Troubleshooting

### Network Scan Not Finding Devices
- Ensure devices are powered on
- Check that Mac is on the same network as devices
- Some devices only advertise when in pairing mode
- Check firewall settings for Bonjour/mDNS

### Codes Not Saving
- Check disk space availability
- Ensure app has write access to Application Support folder
- Try restarting the app

## Version History

### Version 1.0 (2026-01-28)
- Initial release
- Manual device inventory
- Secure code vault with Keychain storage
- Network discovery for HAP and Matter devices
- Code location hints for major manufacturers
- Export to CSV, JSON, Text
- Photo attachment support for code labels

## License

MIT License - Copyright (c) 2026 Jordan Koch

See LICENSE file for details.

## Author

**Jordan Koch**
- GitHub: [@kochj23](https://github.com/kochj23)

---

*HomeKit Restore - Document and backup your HomeKit setup codes*

**Last Updated:** January 28, 2026
