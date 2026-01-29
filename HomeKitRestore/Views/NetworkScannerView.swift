//
//  NetworkScannerView.swift
//  HomeKit Restore
//
//  Created by Jordan Koch on 2026-01-28.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct NetworkScannerView: View {
    @EnvironmentObject var networkScanner: NetworkScannerManager
    @EnvironmentObject var codeVaultManager: CodeVaultManager

    @State private var selectedDevice: DiscoveredDevice?
    @State private var filterType: FilterType = .all

    enum FilterType: String, CaseIterable {
        case all = "All"
        case hap = "HomeKit (HAP)"
        case matterCommissioning = "Matter (Unpaired)"
        case matterOperational = "Matter (Paired)"
    }

    var filteredDevices: [DiscoveredDevice] {
        switch filterType {
        case .all:
            return networkScanner.discoveredDevices
        case .hap:
            return networkScanner.hapDevices
        case .matterCommissioning:
            return networkScanner.matterCommissioningDevices
        case .matterOperational:
            return networkScanner.matterOperationalDevices
        }
    }

    var body: some View {
        HSplitView {
            // Device List
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Network Discovery")
                            .font(.headline)
                        Text(networkScanner.scanProgress)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Picker("Filter", selection: $filterType) {
                        ForEach(FilterType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 180)

                    Button(action: toggleScan) {
                        if networkScanner.isScanning {
                            Label("Stop", systemImage: "stop.fill")
                        } else {
                            Label("Scan", systemImage: "antenna.radiowaves.left.and.right")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color(nsColor: .windowBackgroundColor))

                Divider()

                // Scan results
                if networkScanner.discoveredDevices.isEmpty && !networkScanner.isScanning {
                    VStack(spacing: 16) {
                        Image(systemName: "network")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Devices Found")
                            .font(.title2)
                        Text("Click 'Scan' to discover HomeKit and Matter devices on your network.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("Start Scan") {
                            networkScanner.startScan()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredDevices, selection: $selectedDevice) { device in
                        DiscoveredDeviceRow(device: device)
                            .tag(device)
                    }
                    .listStyle(.inset)

                    if networkScanner.isScanning {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Scanning...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
            }
            .frame(minWidth: 400)

            // Detail View
            if let device = selectedDevice {
                DiscoveredDeviceDetailView(device: device)
                    .frame(minWidth: 350)
            } else {
                VStack {
                    Image(systemName: "network.badge.shield.half.filled")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Select a device to view details")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Network Scanner")
    }

    private func toggleScan() {
        if networkScanner.isScanning {
            networkScanner.stopScan()
        } else {
            networkScanner.startScan()
        }
    }
}

struct DiscoveredDeviceRow: View {
    let device: DiscoveredDevice

    var body: some View {
        HStack {
            Image(systemName: serviceIcon)
                .font(.title2)
                .foregroundColor(serviceColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    Text(device.serviceTypeFriendly)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let manufacturer = device.manufacturer {
                        Text("• \(manufacturer)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if device.isPaired {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }

    var serviceIcon: String {
        switch device.serviceType {
        case "_hap._tcp":
            return "house.fill"
        case "_matterc._udp":
            return "wave.3.right.circle.fill"
        case "_matter._tcp":
            return "checkmark.seal.fill"
        default:
            return "network"
        }
    }

    var serviceColor: Color {
        switch device.serviceType {
        case "_hap._tcp":
            return .orange
        case "_matterc._udp":
            return .purple
        case "_matter._tcp":
            return .green
        default:
            return .gray
        }
    }
}

struct DiscoveredDeviceDetailView: View {
    let device: DiscoveredDevice
    @EnvironmentObject var codeVaultManager: CodeVaultManager

    @State private var setupCode: String = ""

    var codeHint: CodeLocationHint? {
        guard let manufacturer = device.manufacturer else { return nil }
        return CodeLocationHint.hints(for: manufacturer)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Image(systemName: serviceIcon)
                        .font(.system(size: 48))
                        .foregroundColor(serviceColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(device.name)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(device.serviceTypeFriendly)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    pairingBadge
                }

                Divider()

                // Connection Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Connection Details")
                        .font(.headline)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        if let ip = device.ipAddress {
                            InfoRow(label: "IP Address", value: ip)
                        }

                        if let port = device.port {
                            InfoRow(label: "Port", value: "\(port)")
                        }

                        if let manufacturer = device.manufacturer {
                            InfoRow(label: "Manufacturer", value: manufacturer)
                        }

                        if let model = device.model {
                            InfoRow(label: "Model", value: model)
                        }

                        InfoRow(label: "Service Type", value: device.serviceType)
                        InfoRow(label: "Discovered", value: formatDate(device.discoveredAt))
                    }
                }

                // TXT Record
                if !device.txtRecord.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Service Metadata")
                            .font(.headline)

                        ForEach(device.txtRecord.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            HStack {
                                Text(key)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(value)
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }

                // Setup Code Entry (for unpaired devices)
                if !device.isPaired {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Setup Code")
                            .font(.headline)

                        Text("This device appears to be unpaired. If you know the setup code, save it here for future reference.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            TextField("XXX-XX-XXX", text: $setupCode)
                                .font(.system(.title3, design: .monospaced))
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 200)

                            Button("Save Code") {
                                saveCode()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(setupCode.isEmpty)
                        }
                    }
                }

                // Code Location Hints
                if let hint = codeHint {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Code Location Hints")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("For \(hint.manufacturer) devices, check:")
                                .font(.subheadline)

                            ForEach(hint.locations, id: \.self) { location in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.accentColor)
                                    Text(location)
                                        .font(.caption)
                                }
                            }
                        }
                        .padding()
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
    }

    private var pairingBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(device.isPaired ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            Text(device.isPaired ? "Paired" : "Unpaired")
                .font(.caption)
                .foregroundColor(device.isPaired ? .green : .orange)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill((device.isPaired ? Color.green : Color.orange).opacity(0.15))
        )
    }

    private var serviceIcon: String {
        switch device.serviceType {
        case "_hap._tcp":
            return "house.fill"
        case "_matterc._udp":
            return "wave.3.right.circle.fill"
        case "_matter._tcp":
            return "checkmark.seal.fill"
        default:
            return "network"
        }
    }

    private var serviceColor: Color {
        switch device.serviceType {
        case "_hap._tcp":
            return .orange
        case "_matterc._udp":
            return .purple
        case "_matter._tcp":
            return .green
        default:
            return .gray
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func saveCode() {
        let code = SetupCode(
            accessoryName: device.name,
            manufacturer: device.manufacturer ?? "Unknown",
            model: device.model ?? "Unknown",
            code: setupCode,
            codeFormat: .numeric
        )
        codeVaultManager.saveCode(code)
        setupCode = ""
    }
}

#Preview {
    NetworkScannerView()
        .environmentObject(NetworkScannerManager())
        .environmentObject(CodeVaultManager.shared)
}
